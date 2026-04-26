EnableCoverArt = ConfigFile:get("nowplayingMostWantedBlack", "CoverArt", true)
EnableWidgetFadeout = ConfigFile:get("nowplayingMostWantedBlack", "FadeoutEnabled", true)
SpinCoverArt = ConfigFile:get("nowplayingMostWantedBlack", "SpinCoverArt", false)
WidgetFadeoutTime = ConfigFile:get("nowplayingMostWantedBlack", "DisplayTime", 15)

function NowPlayingOptions()
    checkbox = ui.checkbox("Enable Cover Art (If Available)", EnableCoverArt)
    if checkbox then
        EnableCoverArt = not EnableCoverArt
        ConfigFile:setAndSave("nowplayingMostWantedBlack", "CoverArt", EnableCoverArt)
    end

    checkbox = ui.checkbox("Spin Cover Art", SpinCoverArt)
    if checkbox then
        SpinCoverArt = not SpinCoverArt
        ConfigFile:setAndSave("nowplayingMostWantedBlack", "SpinCoverArt", SpinCoverArt)
    end

    checkbox = ui.checkbox("Enable Widget Fadeout", EnableWidgetFadeout)
    if checkbox then
        EnableWidgetFadeout = not EnableWidgetFadeout
        ConfigFile:setAndSave("nowplayingMostWantedBlack", "FadeoutEnabled", EnableWidgetFadeout)
    end

    if EnableWidgetFadeout then
        ui.text('Show the widget for first ' .. math.ceil(WidgetFadeoutTime) .. ' seconds of new track')
        local sliderValue7 = ConfigFile:get("nowplayingMostWantedBlack", "DisplayTime", 15)
        sliderValue7 = ui.slider("Seconds (Default 15) ##slider7", sliderValue7, 10, 30, "%.1f")
        if WidgetFadeoutTime ~= sliderValue7 then
            WidgetFadeoutTime = sliderValue7
            ConfigFile:setAndSave("nowplayingMostWantedBlack", "DisplayTime", sliderValue7)
            NeedToSaveConfig = true
        end
    end
end

NowPlayingMainCanvas = ui.ExtraCanvas(vec2(2000, 807), 1, render.AntialiasingMode.None)
NowPlayingTextBoxCanvas = ui.ExtraCanvas(vec2(420, 60), 1, render.AntialiasingMode.None)

ScrollAnimation = -1

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

    if (EnableWidgetFadeout and time < WidgetFadeoutTime and time < totalTime-5) or ((not EnableWidgetFadeout) and time < totalTime-5) then
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
        if (EnableWidgetFadeout and time > WidgetFadeoutTime) or time > totalTime-5 then
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

        ui.drawImage(ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer/NowPlaying Widgets/Most Wanted Black/TRAX.png", vec2(270+(StringLength*StringProgress), 116), vec2(425+(StringLength*StringProgress), 308), rgbm(1,1,1,StringProgress))
        ui.drawImage(ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer/NowPlaying Widgets/Most Wanted Black/BAR.png", vec2(196, 116), vec2(352+(StringLength*StringProgress), 316), rgbm(1,1,1,StringFadeIn))
        
        ui.pushDWriteFont('Eurostar:Fonts/Eurostar Black.ttf')
        ui.dwriteDrawText(Title, 45, vec2(342,135), rgbm(0.99,0.99,0.99,TextFadeIn))
        ui.dwriteDrawText(Artist, 45, vec2(342,185), rgbm(0.69,0.69,0.53,TextFadeIn))
        ui.dwriteDrawText(Albums[MusicType], 45, vec2(342,235), rgbm(0.69,0.69,0.53,TextFadeIn))
        StringLength = math.max(500, math.max(ui.measureDWriteText(Title, 40).x*1.2, ui.measureDWriteText(Artist, 40).x*1.2, ui.measureDWriteText(Albums[MusicType], 40).x*1.2))
        ac.debug("StringLength", StringLength)
        ui.popDWriteFont()
        SpinnerRotation = (SpinnerRotation + 2)%360
        if SpinCoverArt then
            ui.beginRotation()
        end
        ui.drawImage(ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer/NowPlaying Widgets/Most Wanted Black/Art Ring.png", vec2(100, 100), vec2(326, 326), rgbm(1,1,1,ArtRingFadeIn))
        if SpinCoverArt then
            ui.endRotation(SpinnerRotation)
        end
        ui.beginRotation()
        ui.drawImage(ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer/NowPlaying Widgets/Most Wanted Black/Spinner.png", vec2(100, 100), vec2(326, 326), rgbm(1,1,1,SpinnerFadeIn))
        ui.endRotation(SpinnerRotation)
        if EnableCoverArt then
            if SpinCoverArt then
                ui.beginRotation()
            end
            ui.drawImageRounded(nowplayingiconcoverart, vec2(74 + CoverArtFadeIn*50, 74 + CoverArtFadeIn*50), vec2(352 - CoverArtFadeIn*50, 352 - CoverArtFadeIn*50), rgbm(1,1,1,CoverArtFadeIn), vec2(0, 0), vec2(1, 1), 100)
            if SpinCoverArt then
                ui.endRotation(SpinnerRotation)
            end
        end
    end
end

local NowPlayingRefreshTimer = 0

function script.windowNowPlayingV2()

    NowPlayingMainCanvas:update(renderNowPlayingMainCanvas)
    windowSize = ac.accessAppWindow("IMGUI_LUA_Dynamic Music Player_nowplayingv2"):size()
    ui.drawImage(NowPlayingMainCanvas, vec2(10*NowPlayingWidgetSize,3*NowPlayingWidgetSize), vec2(1000*NowPlayingWidgetSize, 404*NowPlayingWidgetSize), rgbm(1,1,1,1))--NowPlayingOpacityCurrent))
    ac.setWindowSizeConstraints("nowplayingv2", vec2(342+(StringLength*0.83*NowPlayingWidgetSize), 200*NowPlayingWidgetSize), vec2(342+(StringLength*0.83*NowPlayingWidgetSize), 200*NowPlayingWidgetSize))
end
