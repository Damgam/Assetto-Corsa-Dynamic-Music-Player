-- In this file you can match certain songs with cover arts. Follow the examples on the correct formatting. All cover arts need to be located in CoverArts folder.
-- Uses DISPLAY TITLE to match files!!!, not the filename of the song!!! That includes removing all the tags, and all the double+ spaces as well as the space at the end of the filename. It is also case sensitive!
-- In case you make a typo here, don't worry, the app won't break, but the cover art won't display. If you make a syntax error however, the whole app will break, so make sure to put a , at the end of every entry!

-- In the ingame settings app, you can now find list of tracks loaded by the app. You can copy it's exact display name into clipboard by right clicking on it on the list.

local CoverArts = {
    -- Example:

    -- ["Artist - Title"] = "CoverArtFile.png",
    -- ["AnotherArtist - AnotherTitle"] = "AnotherCoverArtFile.png",

    -- ["YetAnotherArtist - YetAnotherTitle"] = "blank", -- You can set it to "blank" to remove a 'false positive' partial match

    ["Hot Action Cop - Going down on it"] = "Need For Speed Hot Pursuit 2.png",
    ["Hot Action Cop - Fever for the flava"] = "Need For Speed Hot Pursuit 2.png",
    ["The Buzzhorn - Ordinary"] = "Need For Speed Hot Pursuit 2.png",
    ["Course of nature - Wall of shame"] = "Need For Speed Hot Pursuit 2.png",
    ["Humble brothers - Brake stand"] = "Need For Speed Hot Pursuit 2.png",
    ["Humble Brothers - Black Hole"] = "Need For Speed Hot Pursuit 2.png",
    ["Rush - One Little Victory"] = "Need For Speed Hot Pursuit 2.png",
    ["Matt Ragan - Cone Of Silence"] = "Need For Speed Hot Pursuit 2.png",
    ["Bush - The People That We Love"] = "Need For Speed Hot Pursuit 2.png",
    ["Pulse Ultra - Build Your Cages"] = "Need For Speed Hot Pursuit 2.png",
}

return CoverArts