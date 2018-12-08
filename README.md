# Change-of-Direction-Trial
Early stage script looking at ways to measure change of direction from GPS data. 

I'm not sure what the end result, if it happens, will be from this script. 

Based off some of Alec Buttfields work (http://vuir.vu.edu.au/36765/) I'm currently exploring ways the long/lat data can be used. 
Unsure will it end in a distance style metric or a count with some way of indicating magnitude. 

Currently need to increase time between datapoints as with 10Hz it is too small a time frame to accurately assess COD and leads to over- estimation in data ---Added filter to leave 1.5sec between data points

Current Output - Count of different COD values


| Name  | Minor  | Straightline |Mod       | High      |
| ----- |--------| -------------| -------- | --------- |
| 1     | 411    | 590          |16        |396        |
| 2     | 375    | 558          |12        |370        |
| 3     | 436    | 551          |21        |422        |

Above based off data from rugby which may explain low moderate COD due to linear nature of running. 
High "High" COD values may indicate either reduced value in measurement or further division of bearing change needed
