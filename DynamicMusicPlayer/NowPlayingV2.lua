NowPlayingMainCanvas = ui.ExtraCanvas(vec2(2000, 807), 1, render.AntialiasingMode.None)
NowPlayingTextBoxCanvas = ui.ExtraCanvas(vec2(420, 60), 1, render.AntialiasingMode.None)

ScrollAnimation = -1



--local function renderNowPlayingTextBoxCanvas()
--    NowPlayingTextBoxCanvas:clear()
--
--    local text1
--    local text2
--    if not EnableNowPlayingTime then
--        text1 = "Now Playing: "
--    elseif EnableNowPlayingTime and CurrentTrack then
--        text1 = "Now Playing: " .. "(" .. string_formatTime(math.ceil(CurrentTrack:currentTime())) .. "/" .. string_formatTime(math.ceil(CurrentTrack:duration())) .. ") "
--    end
--    text2 = CurrentlyPlaying or ""
--
--    ui.pushDWriteFont('OPTIEdgarBold:\\Fonts;Weight=Medium')
--    ui.dwriteText("" .. text1, 18, rgbm(0, 1, 0, 1))
--    ui.dwriteText(" ", 21, rgbm(0, 1, 0, 1))
--    ui.sameLine(ScrollAnimation)
--    ScrollAnimation = ScrollAnimation - 5
--    text2 = text2 .. "                         ⠀"
--    ScrollAnimationResetThreshold = ui.measureDWriteText(text2, 21, -1)
--    text2 = text2 .. text2
--    if ScrollAnimation < -ScrollAnimationResetThreshold.x then
--        ScrollAnimation = -5
--    end
--    ui.dwriteText("" .. text2, 21, rgbm(0, 1, 0, 1))
--    ui.popDWriteFont()
--end


local SpinnerRotation = 0
local SpinnerFadeIn = 0
local ArtRingFadeIn = 0
local CoverArtFadeIn = 0
local StringFadeIn = 0
local StringProgress = 0
local StringLength = 500
local TextFadeIn = 0

local CurrentlyPlayingCachedTitle = ""
local Artist = ""
local Title = ""
local Albums = {
    ["replay"] = "Replay Music",
    ["finish"] = "Finish Music",
    ["idle"] = "Menu Music",
    ["practice"] = "Practice Session Music",
    ["quali"] = "Qualification Session Music",
    ["race"] = "Race Session Music",
    ["other"] = "Other Session Music",
}

local function renderNowPlayingMainCanvas()
    NowPlayingMainCanvas:clear()

    --ui.drawImage(ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer/NowPlayingThemes/Assets/PioneerGreen/pioneer.png", vec2(0, 0), vec2(995, 307), rgb(1,1,1))
    --NowPlayingTextBoxCanvas:update(renderNowPlayingTextBoxCanvas)
    --ui.drawImage(NowPlayingTextBoxCanvas, vec2(370, 140), vec2(790, 200), rgb(1,1,1))
    local time = CurrentTrack:currentTime()
    local totalTime = CurrentTrack:duration()
    if time < 2 then
        SpinnerFadeIn = 0
        ArtRingFadeIn = 0
        CoverArtFadeIn = 0
        StringFadeIn = 0
        StringProgress = 0
        TextFadeIn = 0
    end

    if time < 15 then
        if time > 1.5 then
            SpinnerFadeIn = math.min(1, SpinnerFadeIn + globalDT*5)
        end
        if time > 3 then
            ArtRingFadeIn = math.min(1, ArtRingFadeIn + globalDT*6)
        end
        if ArtRingFadeIn == 1 then
            StringFadeIn = math.min(1, StringFadeIn + globalDT*6)
        end
        if StringFadeIn > 0.1 then
            StringProgress = math.min(1, StringProgress + globalDT*5)
        end
        if StringProgress > 0.5 then
            TextFadeIn = math.min(0.85, TextFadeIn + globalDT*3)
        end
        if TextFadeIn > 0.25 then
            CoverArtFadeIn = math.min(1, CoverArtFadeIn + globalDT*5)
        end
    elseif SpinnerFadeIn > 0 then
        if time > 15 then
        --if time > totalTime-5 then
            TextFadeIn = math.max(0, TextFadeIn - globalDT*3)
            CoverArtFadeIn = math.max(0, CoverArtFadeIn - globalDT*5)
        end
        if TextFadeIn <= 0.5 then
            StringProgress = math.max(0, StringProgress - globalDT*5)
            StringFadeIn = math.max(0, StringFadeIn - globalDT*5)
        end
        if StringProgress == 0 then
            ArtRingFadeIn = math.max(0, ArtRingFadeIn - globalDT*5)
        end
        if ArtRingFadeIn == 0 then
            SpinnerFadeIn = math.max(0, SpinnerFadeIn - globalDT*0.5)
        end
    end

    if CurrentlyPlaying ~= CurrentlyPlayingCachedTitle then
        Artist, Title = CurrentlyPlaying:match("^%s*(.-)%s*%-%s*(.-)%s*$")
        CurrentlyPlayingCachedTitle = CurrentlyPlaying .. ""
    end

    if SpinnerFadeIn > 0 then

        ui.drawImage(ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer/NowPlaying Custom/MW Black/TRAX.png", vec2(270+(StringLength*StringProgress), 116), vec2(425+(StringLength*StringProgress), 308), rgbm(1,1,1,StringProgress))
        ui.drawImage(ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer/NowPlaying Custom/MW Black/BAR.png", vec2(196, 116), vec2(352+(StringLength*StringProgress), 316), rgbm(1,1,1,StringFadeIn))
        
        ui.pushDWriteFont('Eurostar:Fonts/Eurostar Black.ttf')
        ui.dwriteDrawText(Title, 45, vec2(342,135), rgbm(0.99,0.99,0.99,TextFadeIn))
        ui.dwriteDrawText(Artist, 45, vec2(342,185), rgbm(0.69,0.69,0.53,TextFadeIn))
        ui.dwriteDrawText(Albums[MusicType], 45, vec2(342,235), rgbm(0.69,0.69,0.53,TextFadeIn))
        StringLength = math.max(500, math.max(ui.measureDWriteText(Title, 40).x*1.2, ui.measureDWriteText(Artist, 40).x*1.2, ui.measureDWriteText(Albums[MusicType], 40).x*1.2))
        ac.debug("StringLength", StringLength)
        ui.popDWriteFont()
        
        ui.drawImage(ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer/NowPlaying Custom/MW Black/Art Ring.png", vec2(100, 100), vec2(326, 326), rgbm(1,1,1,ArtRingFadeIn))
        ui.beginRotation()
        SpinnerRotation = (SpinnerRotation + 2)%360
        ui.drawImage(ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer/NowPlaying Custom/MW Black/Spinner.png", vec2(100, 100), vec2(326, 326), rgbm(1,1,1,SpinnerFadeIn))
        ui.endRotation(SpinnerRotation)
        ui.drawImageRounded(nowplayingiconcoverart, vec2(74 + CoverArtFadeIn*50, 74 + CoverArtFadeIn*50), vec2(352 - CoverArtFadeIn*50, 352 - CoverArtFadeIn*50), rgbm(1,1,1,CoverArtFadeIn), vec2(0, 0), vec2(1, 1), 100)
    end
end

local NowPlayingRefreshTimer = 0

function script.windowNowPlayingV2()

    --if NowPlayingRefreshTimer >= 5 then
        NowPlayingMainCanvas:update(renderNowPlayingMainCanvas)
        --NowPlayingRefreshTimer = 0
    --else
        --NowPlayingRefreshTimer = NowPlayingRefreshTimer + 1
    --end
    windowSize = ac.accessAppWindow("IMGUI_LUA_Dynamic Music Player_nowplayingv2"):size()
    ui.drawImage(NowPlayingMainCanvas, vec2(10*NowPlayingWidgetSize,3*NowPlayingWidgetSize), vec2(1000*NowPlayingWidgetSize, 404*NowPlayingWidgetSize), rgbm(1,1,1,1))--NowPlayingOpacityCurrent))
    ac.setWindowSizeConstraints("nowplayingv2", vec2(342+(StringLength*0.83*NowPlayingWidgetSize), 200*NowPlayingWidgetSize), vec2(342+(StringLength*0.83*NowPlayingWidgetSize), 200*NowPlayingWidgetSize))
end
