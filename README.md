Dynamic Music Player for Assetto Corsa! REQUIRES CUSTOM SHADERS PATCH 0.2.0+!
Older versions of CSP may work but I don't guarantee it. Some features are only fully enabled online in Custom Shaders Patch 0.2.1 Preview56 and above due to a bug in previous versions.

Music Player that reacts to what's happening on the track, controlling music playlists and volume.

MUSIC IS NOT INCLUDED WITH THE APP, FILL IT WITH YOUR OWN FILES. MP3 AND OGG CONFIRMED TO WORK, WHATEVER ELSE IS SUPPORTED BY ASSETTO CORSA CSP WILL ALSO WORK.

Download: 

https://github.com/Damgam/Assetto-Corsa-Dynamic-Music-Player/releases

https://www.racedepartment.com/downloads/dynamic-music-player.65459/

Install: Drop the DynamicMusicPlayer folder into assettocorsa\apps\lua\
Music Install: Drop your music files into assettocorsa\apps\lua\DynamicMusicPlayer\Music\ folders

Features:
- Fully automated playlist creation, just drag and drop your audio files to folders,
- 2 "Intensity" levels for race music,
- 2 Levels of race finish music, one for podium finish and one for the rest,
- Dedicated playlist for waiting, practice, qualification and replay sessions,
- Dynamic volume adjustments, reducing volume of the music when you're driving slow, crashing, have opponents nearby or when yellow and blue flags pop up,
- Configurability via ingame Settings app. You can make it as complex or as simple as you like.

Todo:
- Bugfixing,
- Possible extra features if I come up with ideas for such.

Known Issues:
- Each playlist needs to have at least 1 file to not crash the app. You can turn off playlists you don't want in the settings app, just keep something in there. Each playlist has one placeholder file included.
- (Fixed in Custom Shaders Patch 0.2.1 Preview56) Due to Lua API call for leaderboards being broken, online mode does not use features related to your position in the race. Intensity levels are purely race progression based,
- For the same reason, finish music will certainly be wrong in Online. It will work, but it will use your bugged position to determine if it should play podium music or lose music,
- Default volume balancing might be a bit too wild for some.
- (Fixed in Custom Shaders Patch 0.2.1 Preview65) OGG files might crash the game on latest Windows 10 versions (they do that to me).

Presentation Video:

[![Dynamic Music Player - LFM Online Race Gameplay](http://img.youtube.com/vi/2Wdc66L4adw/0.jpg)](http://www.youtube.com/watch?v=2Wdc66L4adw/ "Dynamic Music Player - LFM Online Race Gameplay")
