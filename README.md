Dynamic Music Player for Assetto Corsa! 
Music Player that reacts to what's happening on the track, controlling music playlists and volume!

IMPORTANT: IF YOU UPDATE FROM ANY OF THE 1.X VERSIONS INTO 2.0+, FRESH INSTALL IS HIGHLY RECOMMENDED. A LOT OF THINGS HAVE CHANGED AND YOUR APP WILL LIKELY MISBEHAVE IF YOU DON'T WIPE OFF ALL THE REMNANTS OF THE OLD VERSION. COPY YOUR MUSIC FOLDER SOMEWHERE, AND RE-ADD YOUR MUSIC TO NEW FOLDERS AFTER THE REINSTALL.

REQUIRES CUSTOM SHADERS PATCH 0.2.2 OR LATER!

Older versions of CSP may work but I don't guarantee it.

YOU HAVE BEEN WARNED!

Also available on https://www.overtake.gg/downloads/dynamic-music-player.65459/

Installation: Copy the DynamicMusicPlayer folder into assettocorsa\apps\lua folder.

Music Install: Copy your music files into assettocorsa\apps\lua\DynamicMusicPlayer\Music\ folders.

ALL THE FOLDERS, EXCEPT THE *OTHER* FOLDER, ARE OPTIONAL.

More details on how to install music:

Make sure you include music at least in the 'Other' folder. That one serves as a fallback for every other folder, if it's left empty, but also as music source for all gamemodes that are not practice, qualification and race.Every other folder can be left empty, and adding any music into them, makes these playlist not use the Other music.
For Finish music to work, there must be some music in the Finish folder. Don't just add music to the FinishPodium folder, it will then be ignored. However, the other way around works perfectly fine, and if FinishPodium is left empty, but Finish is not, it will just play Finish folder music on every finish!
For advanced users, there's a Lua file left in the Music folder, where they can specify paths to other folders in their system to take music from. BEWARE, make sure these folders don't contain any files that are not music. Images, text files, and similar stuff might break the app. I am also not taking any responsibility for anyone breaking that file. It has been confirmed to work, so if you break it, it's your fault.


Features of this app:

- Fully automated playlist creation, just drag and drop your audio files to folders,
- Dedicated playlist for idle, practice, qualification, race, finish and replay sessions,
- Dynamic volume adjustments, reducing volume of the music when you're driving slow, crashing, have opponents nearby or when yellow and blue flags pop up,
- Configurability via ingame Settings app. You can make it as complex or as simple as you like,
- On-screen widget showing you currently playing track.

Known Issues:
- If by any chance you got your Assetto Corsa to work on Linux, or some debloated version of Windows that is missing Microsoft applications, this app won't work there. It depends on Windows Media Player to exist on your system since that's what CSP Media API depends on. 
- If you find any other bugs, please report them in GitHub Issues Page
