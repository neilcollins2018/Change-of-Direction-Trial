library(readxl)
library(smooth)
library(tidyverse)
library(zoo)
library(magrittr)
library(geosphere)
library(NISTunits)



read_plus2 <- function(flnm) {
  fread(flnm, skip = 8) %>%
    mutate(filename=gsub(" .csv", "", basename(flnm))) %>%
    separate(filename, c('Match', 'z2', 'z3', 'z4', 'z5', 'z6')," ") %>%
    mutate(Name = paste(z4, z5))
}

############File Path
C_A <- list.files(path="ADD FILE PATH HERE", 
                  pattern="*.csv", full.names = T) %>%
  map_df(function(x) read_plus2(x))

GPS2 <-C_A 

####Lead long/lat
GPS2 %<>%
  group_by(Name) %>%
  dplyr::mutate(LatEnd = lead(Latitude, 1)) %>%
  dplyr::mutate(LongEnd =lead(Longitude, 1))

###Create matrix of long/lat & lead values to find bearing between points
P1 <- matrix(GPS2$Latitude, GPS2$Longitude, nrow = nrow(GPS2), ncol = 2)
P2 <- matrix(GPS2$LatEnd, GPS2$LongEnd, nrow = nrow(GPS2), ncol = 2)

GPS2$Bearing <- NISTdegTOradian(bearing(P2, P1))

###Difference in bearings for change in bearing
GPS2 %<>%
  group_by(Name, Match) %>%
  dplyr::mutate("BearingDiff" = c(NA, diff(Bearing)))

###Speed metrics
GPS3 <- GPS2 %>%
  mutate("SpeedHS" = case_when(Velocity <= 5.5 ~ 0,
                               Velocity > 5.5 ~ Velocity),
         "SpeedSD" = case_when(Velocity <= 7 ~ 0,
                               Velocity > 7 ~ Velocity)) %>%
  group_by(Match, Name) %>%
  mutate(Time_diff = Seconds-lag(Seconds)) %>%
  mutate(Time_diff = case_when(is.na(Time_diff) ~ 0,
                               Time_diff < 0 ~ 0,
                               Time_diff > 0.1 ~ 0.1,
                               T ~ Time_diff),
         Dist = Velocity*Time_diff,
         Dist_HS = SpeedHS*Time_diff,
         Dist_SD = SpeedSD*Time_diff)

###Dummy values based on difference in bearing values ----Could Alter to differentiate between left and right COD
GPS3 %<>%
  mutate(COD_Magnitude = case_when(BearingDiff <= 0.05 & BearingDiff >= -0.05 ~ 'StraightLine',
                                BearingDiff > 0.05 & BearingDiff >= 0.1 ~ "Minor",
                                BearingDiff < -0.05 & BearingDiff >=-0.1 ~ "Minor",
                                BearingDiff > 0.1 & BearingDiff <= 1 ~ "Mod",
                                BearingDiff < -0.1 & BearingDiff >= -1 ~ "Mod",
                                BearingDiff > 1 & BearingDiff <= 2 ~ "High",
                                BearingDiff < -1 & BearingDiff >= -2 ~ "High",
                                BearingDiff > 2  ~ "V_High",
                                BearingDiff < -2  ~ "V_High"))

###Add factor and levels 
GPS3$COD_Magnitude <- factor(GPS3$COD_Magnitude, levels = 
                               c("StraightLine", "Minor", "Mod", "High", "V_High"))

###Sum distances for each bearing
GPSDist <- GPS3 %>% 
  ungroup() %>%
  filter(complete.cases(.))  %>%
  select(-c(1:12, 14:18,20:26)) %>%
  group_by(Match, Name, COD_Magnitude) %>%
  dplyr::summarise("Distance" = sum(Dist), "HSDist" = sum(Dist_HS), "VHSDist" = sum(Dist_SD))
