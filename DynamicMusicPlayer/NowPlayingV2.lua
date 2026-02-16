NowPlayingMainCanvas = ui.ExtraCanvas(vec2(995, 307), 1, render.AntialiasingMode.ExtraSharpCMAA)
NowPlayingTextBoxCanvas = ui.ExtraCanvas(vec2(420, 60), 1, render.AntialiasingMode.ExtraSharpCMAA)

ScrollAnimation = -1

local function renderNowPlayingTextBoxCanvas()
    NowPlayingTextBoxCanvas:clear()

    local text1
    local text2
    if not EnableNowPlayingTime then
        text1 = "Now Playing: "
    elseif EnableNowPlayingTime and CurrentTrack then
        text1 = "Now Playing: " .. "(" .. string_formatTime(math.ceil(CurrentTrack:currentTime())) .. "/" .. string_formatTime(math.ceil(CurrentTrack:duration())) .. ") "
    end
    text2 = CurrentlyPlaying or ""

    ui.pushDWriteFont('OPTIEdgarBold:\\Fonts;Weight=Medium')
    ui.dwriteText("" .. text1, 18, rgbm(0, 1, 0, 1))
    ui.dwriteText(" ", 21, rgbm(0, 1, 0, 1))
    ui.sameLine(ScrollAnimation)
    ScrollAnimation = ScrollAnimation - 5
    text2 = text2 .. "                         ⠀"
    ScrollAnimationResetThreshold = ui.measureDWriteText(text2, 21, -1)
    text2 = text2 .. text2
    if ScrollAnimation < -ScrollAnimationResetThreshold.x then
        ScrollAnimation = -5
    end
    ui.dwriteText("" .. text2, 21, rgbm(0, 1, 0, 1))
    ui.popDWriteFont()
end

local function renderNowPlayingMainCanvas()
    NowPlayingMainCanvas:clear()

    ui.drawImage(ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer/NowPlayingThemes/Assets/PioneerGreen/pioneer.png", vec2(0, 0), vec2(995, 307), rgb(1,1,1))
    NowPlayingTextBoxCanvas:update(renderNowPlayingTextBoxCanvas)
    ui.drawImage(NowPlayingTextBoxCanvas, vec2(370, 140), vec2(790, 200), rgb(1,1,1))
end

local NowPlayingRefreshTimer = 0

function script.windowNowPlayingV2()

    if NowPlayingRefreshTimer >= 5 then
        NowPlayingMainCanvas:update(renderNowPlayingMainCanvas)
        NowPlayingRefreshTimer = 0
    else
        NowPlayingRefreshTimer = NowPlayingRefreshTimer + 1
    end
    windowSize = ac.accessAppWindow("IMGUI_LUA_Dynamic Music Player_nowplayingv2"):size()
    ui.drawImage(NowPlayingMainCanvas, vec2(10,3), vec2(windowSize.x-10, (windowSize.x*0.308)-3), rgbm(1,1,1,NowPlayingOpacityCurrent))
end