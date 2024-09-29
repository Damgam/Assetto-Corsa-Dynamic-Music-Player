In this folder you can see multiple folders called by the situations in which they play.

Important notes. 
- You can leave folders empty, except one, the 'Other' folder!
- Any empty folder will play music from the 'Other folder!
- Any folder with music included will ignore music from the 'Other' folder.
- If you add Finish music, make sure you add both Finish and FinishPodium. They can be the same files, but they should both be filled if you want Finish music.

My recommendation would be to put driving music into the Other folder and pitstop music into Idle folder, unless you want to go more specific into the categories.

If you want to get fancy, you can play around the ExternalMusicPaths.lua, there are instructions included in that file. Try not to break it though, that will brick the entire Music app.


New in 3.0 - Tags!
Certain modes now support tags!
To use them, you put them in the filename, for example `Artist - Title #ProgressTop20`
Tags can also be stacked, for example `Artist - Title #ProgressTop20 #PositionTop10`

!!!!!!!!!!!!NOTE: TAGS ARE CASE SENSITIVE!!!!!!!!!!!!

Valid tags won't be visible in the Now Playing widget track title.

Available Tags are as follows:
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
Universal - Can be used in any mode.
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Day - Only play during daytime
#Night - Only play during nighttime
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Rain - Only play during rainy weather (Requires RainFX)
#Dry - Only play when it's not raining
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
Car Production Year Based - Only play if the car was produced at least or at most this year. WARNING: If the car doesn't have a year defined, it assumes a year 2000!

Minimum Year:
"#YearMin1900",
"#YearMin1910",
"#YearMin1920",
"#YearMin1930",
"#YearMin1940",
"#YearMin1950",
"#YearMin1960",
"#YearMin1970",
"#YearMin1980",
"#YearMin1990",
"#YearMin2000",
"#YearMin2010",
"#YearMin2020",
"#YearMin2030",

Maximum Year:
"#YearMax1900",
"#YearMax1910",
"#YearMax1920",
"#YearMax1930",
"#YearMax1940",
"#YearMax1950",
"#YearMax1960",
"#YearMax1970",
"#YearMax1980",
"#YearMax1990",
"#YearMax2000",
"#YearMax2010",
"#YearMax2020",
"#YearMax2030",
--------------------------------------------------------------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------------------------------------------------------------------
Race only - These will only work when used in Race mode, but it's harmless to have them in filenames anywhere else - don't be afraid of putting these in Other category.
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
Top Position Tags - Only play when you're at least this high in the leaderboard. For example, when you're 5th out of 20 cars, it's Top 25% and when you're 15th out of 20 cars, it's Top 75%
#PositionTop1  - Only play when you're 1st
#PositionTop10 - Top 10%
#PositionTop20 - Top 20%
#PositionTop30 - Top 30%
#PositionTop40 - Top 40%
#PositionTop50 - Top 50%
#PositionTop60 - Top 60%
#PositionTop70 - Top 70%
#PositionTop80 - Top 80%
#PositionTop90 - Top 90%
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
Bottom Position Tags - Only play when you're at least this low in the leaderboard. For example, when you're 5th out of 20 cars, it's Bottom 75% and when you're 15th out of 20 cars, it's Bottom 25%
#PositionBottom10 - Bottom 10%
#PositionBottom20 - Bottom 20%
#PositionBottom30 - Bottom 30%
#PositionBottom40 - Bottom 40%
#PositionBottom50 - Bottom 50%
#PositionBottom60 - Bottom 60%
#PositionBottom70 - Bottom 70%
#PositionBottom80 - Bottom 80%
#PositionBottom90 - Bottom 90%
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
Minimum Progress Tags - Only play when the race has progressed at least this much %
#ProgressMin10 - 10%
#ProgressMin20 - 20%
#ProgressMin30 - 30%
#ProgressMin40 - 40%
#ProgressMin50 - 50%
#ProgressMin60 - 60%
#ProgressMin70 - 70%
#ProgressMin80 - 80%
#ProgressMin90 - 90%
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
Maximum Progress Tags - Only play until the race has progressed this much %
#ProgressMax10 - 10%
#ProgressMax20 - 20%
#ProgressMax30 - 30%
#ProgressMax40 - 40%
#ProgressMax50 - 50%
#ProgressMax60 - 60%
#ProgressMax70 - 70%
#ProgressMax80 - 80%
#ProgressMax90 - 90%