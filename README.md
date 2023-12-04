Dynamic Music Player for Assetto Corsa! REQUIRES CUSTOM SHADERS PATCH!

Music Player that reacts to what's happening on the track, controlling music playlists and volume.

MUSIC IS NOT INCLUDED WITH THE APP, FILL IT WITH YOUR OWN FILES. MP3 AND OGG CONFIRMED TO WORK, WHATEVER ELSE IS SUPPORTED BY ASSETTO CORSA CSP WILL ALSO WORK.

Download: https://github.com/Damgam/Assetto-Corsa-Dynamic-Music-Player/releases

Install: Drop the DynamicMusicPlayer folder into assettocorsa\apps\lua\
Music Install: Drop your music files into assettocorsa\apps\lua\DynamicMusicPlayer\Music\ folders

Features:
- Fully automated playlist creation, just drag and drop your audio files to folders,
- 2 "Intensity" levels for race music,
- 2 Levels of race finish music, one for podium finish and one for the rest,
- Dedicated playlist for waiting, , practice, qualification and replay sessions,
- Dynamic volume adjustments, reducing volume of the music when you're driving slow, have opponents nearby, and when yellow and blue flags pop up,
- Configurability (Currently only by editing files, dedicated ingame config app coming sometime soon).

Todo:
- Ingame config app - Config stuff is at the very top of the Lua file right now if you need to change volume or some parameters,
- Bugfixing,
- Possible extra features if I come up with ideas for such.

Known Issues:
- Each playlist needs to have at least 2 files to avoid infinite loop (that prevents the same track to play twice in a row),
- (FIXED) Playback can bug out when you restart the race without quitting to desktop, or when you jump between replay and live game,
- App does not respect ingame volume sliders, not even the Master one. (There's no slider for music). Option to adjust volume will come with an app, until then you can adjust volume in the lua file,
- Due to Lua API call for leaderboards being broken, online mode does not use features related to your position in the race. Intensity levels are purely race progression based,
- For the same reason, finish music will certainly be wrong in Online. It will work, but it will use your bugged position to determine if it should play podium music or lose music,
- Default volume balancing might be a bit too wild for some. Config coming soon, until then you can edit the Lua file with your own values. Config stuff is at the very top of the file.

Presentation Video:

[![Assetto Corsa WiP Dynamic Music Player Mod Teaser/Presentation](http://img.youtube.com/vi/FhkFGFNKvd0/0.jpg)](http://www.youtube.com/watch?v=FhkFGFNKvd0 "Assetto Corsa WiP Dynamic Music Player Mod Teaser/Presentation")
