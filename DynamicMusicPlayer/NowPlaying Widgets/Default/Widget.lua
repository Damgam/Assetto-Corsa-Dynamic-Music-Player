EnableNowPlayingIcon = ConfigFile:get("nowplayingDefault", "nowplayingicon", true)
EnableAnimatedNowPlayingIcon = ConfigFile:get("nowplayingDefault", "nowplayinganimatedicon", false)
EnableNowPlayingTime = ConfigFile:get("nowplayingDefault", "nowplayingtime", true)
EnableNowPlayingWidgetFadeout = ConfigFile:get("nowplayingDefault", "nowplayingfadeout", true)
NowPlayingWidgetFadeoutTime = ConfigFile:get("nowplayingDefault", "nowplayingfadeouttime", 10)

function NowPlayingOptions()
    checkbox = ui.checkbox("Enable Icon (Or Cover Art if available)", EnableNowPlayingIcon)
    if checkbox then
        EnableNowPlayingIcon = not EnableNowPlayingIcon
        ConfigFile:set("nowplayingDefault", "nowplayingicon", EnableNowPlayingIcon)
        NeedToSaveConfig = true
    end

    if EnableNowPlayingIcon then
        checkbox = ui.checkbox("Enable Animated Icon (Disables Cover Arts)", EnableAnimatedNowPlayingIcon)
        if checkbox then
            EnableAnimatedNowPlayingIcon = not EnableAnimatedNowPlayingIcon
            ConfigFile:set("nowplayingDefault", "nowplayinganimatedicon", EnableAnimatedNowPlayingIcon)
            NeedToSaveConfig = true
        end
    end

    checkbox = ui.checkbox("Enable Timer", EnableNowPlayingTime)
    if checkbox then
        EnableNowPlayingTime = not EnableNowPlayingTime
        ConfigFile:set("nowplayingDefault", "nowplayingtime", EnableNowPlayingTime)
        NeedToSaveConfig = true
    end

    checkbox = ui.checkbox("Show the widget only when new track starts", EnableNowPlayingWidgetFadeout)
    if checkbox then
        EnableNowPlayingWidgetFadeout = not EnableNowPlayingWidgetFadeout
        ConfigFile:set("nowplayingDefault", "nowplayingfadeout", EnableNowPlayingWidgetFadeout)
        NeedToSaveConfig = true
    end

    if EnableNowPlayingWidgetFadeout then
        ui.text('Show the widget for first ' .. math.ceil(NowPlayingWidgetFadeoutTime) .. ' seconds of new track')
        local sliderValue7 = ConfigFile:get("nowplayingDefault", "nowplayingfadeouttime", 10)
        sliderValue7 = ui.slider("Seconds (Default 10) ##slider7", sliderValue7, 5, 30, "%.1f")
        if NowPlayingWidgetFadeoutTime ~= sliderValue7 then
            NowPlayingWidgetFadeoutTime = sliderValue7
            ConfigFile:set("nowplayingDefault", "nowplayingfadeouttime", sliderValue7)
            NeedToSaveConfig = true
        end
    end
end

ac.setWindowSizeConstraints('main', vec2(650,100), vec2(650,600))
local nowplayingicon = ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer/" .. "iconFlipped.png"
local nowplayingbar = ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer/" .. "nowplayingbar.png"

NowPlayingBars = {
    [1] = {current = math.random(0,128)/128, target = math.random(0,128)/128},
    [2] = {current = math.random(0,128)/128, target = math.random(0,128)/128},
    [3] = {current = math.random(0,128)/128, target = math.random(0,128)/128},
    [4] = {current = math.random(0,128)/128, target = math.random(0,128)/128},
    [5] = {current = math.random(0,128)/128, target = math.random(0,128)/128},
    [6] = {current = math.random(0,128)/128, target = math.random(0,128)/128},
    [7] = {current = math.random(0,128)/128, target = math.random(0,128)/128},
}

NowPlayingOpacityCurrent = 0
NowPlayingOpacityTarget = 0
   
function script.windowNowPlayingV2()
    ui.columns(2, false, "NowPlayingColumns")
    ui.beginOutline()
    local windowWidthRange = 75
    if EnableNowPlayingIcon and NowPlayingOpacityCurrent > 0 then
        if EnableAnimatedNowPlayingIcon then
            if UpdateCounter%20 == 0 or RefreshBarTargets then
                NowPlayingBars = {
                    [1] = {current = NowPlayingBars[1].current, target = math.random(0,128)/128},
                    [2] = {current = NowPlayingBars[2].current, target = math.random(0,128)/128},
                    [3] = {current = NowPlayingBars[3].current, target = math.random(0,128)/128},
                    [4] = {current = NowPlayingBars[4].current, target = math.random(0,128)/128},
                    [5] = {current = NowPlayingBars[5].current, target = math.random(0,128)/128},
                    [6] = {current = NowPlayingBars[6].current, target = math.random(0,128)/128},
                    [7] = {current = NowPlayingBars[7].current, target = math.random(0,128)/128},
                }
            end

            RefreshBarTargets = true
            for barIndex, barValue in ipairs(NowPlayingBars) do
                if barValue.current > barValue.target then
                    NowPlayingBars[barIndex].current = barValue.current - ((barValue.current - barValue.target)*0.05)
                    RefreshBarTargets = false
                elseif barValue.current < barValue.target then
                    NowPlayingBars[barIndex].current = barValue.current - ((barValue.current - barValue.target)*0.05)
                    RefreshBarTargets = false
                end
                if NowPlayingWidgetSize < 0.80 then
                    barIndex = barIndex+1
                end
                if not (NowPlayingWidgetSize < 0.80 and barIndex == 1) then
                    ui.drawImage(nowplayingbar, vec2((((barIndex)*12)+2)*NowPlayingWidgetSize, (10+50*NowPlayingWidgetSize)*(1-(barValue.current))), vec2((((barIndex+1)*12)+2)*NowPlayingWidgetSize,15+65*NowPlayingWidgetSize), rgbm(1, 1, 1, NowPlayingOpacityCurrent), vec2(1,1), vec2(0,0))
                end
            end
            windowWidthRange = 14*7
        else
            if nowplayingiconcoverart then
                ui.drawImage(nowplayingiconcoverart, vec2(10+10*NowPlayingWidgetSize,10+10*NowPlayingWidgetSize), vec2(10+70*NowPlayingWidgetSize,15+65*NowPlayingWidgetSize), rgbm(1, 1, 1, NowPlayingOpacityCurrent), vec2(0,0), vec2(1,1), ui.ImageFit.Fit)
            else
                ui.drawImage(nowplayingicon, vec2(10+10*NowPlayingWidgetSize,10+10*NowPlayingWidgetSize), vec2(10+70*NowPlayingWidgetSize,15+65*NowPlayingWidgetSize), rgbm(1, 1, 1, NowPlayingOpacityCurrent), vec2(1,1), vec2(0,0), ui.ImageFit.Fit)
            end
            
        end
    end
    ui.nextColumn()
    ui.setColumnWidth(0, windowWidthRange*NowPlayingWidgetSize)
    ui.setColumnWidth(1, 10000)
    ui.beginOutline()
    ui.pushDWriteFont('OPTIEdgarBold:\\Fonts;Weight=Medium')
    ui.dwriteText("", math.floor(5*NowPlayingWidgetSize), rgbm(1, 1, 1, NowPlayingOpacityCurrent))
    
    local text1
    local text2
    if not EnableNowPlayingTime then
        text1 = "Now Playing: "
    elseif EnableNowPlayingTime and CurrentTrack then
        text1 = "Now Playing: " .. "(" .. string_formatTime(math.ceil(CurrentTrack:currentTime())) .. "/" .. string_formatTime(math.ceil(CurrentTrack:duration())) .. ") "
    end
    text2 = CurrentlyPlaying or ""
    local windowWidth = math.max(ui.measureDWriteText(text1, 25*NowPlayingWidgetSize, -1).x, ui.measureDWriteText(text2, 25*NowPlayingWidgetSize, -1).x)
    local windowWidth = vec2(windowWidth)
    ui.dwriteText(text1, 18*NowPlayingWidgetSize, rgbm(1, 1, 1, NowPlayingOpacityCurrent))
    ui.dwriteText(text2, 21*NowPlayingWidgetSize, rgbm(1, 1, 1, NowPlayingOpacityCurrent))
    ui.endOutline(0, 1.5)
    ui.popDWriteFont()

    
    ac.setWindowSizeConstraints('nowplayingv2', vec2(windowWidth.x+windowWidthRange+75*NowPlayingWidgetSize,100*NowPlayingWidgetSize), vec2(windowWidth.x+windowWidthRange+75*NowPlayingWidgetSize,100*NowPlayingWidgetSize))

    if CurrentTrack and ((not EnableNowPlayingWidgetFadeout) or (CurrentTrack:currentTime() < NowPlayingWidgetFadeoutTime and CurrentTrack:currentTime() > 0.5)) then
        NowPlayingOpacityTarget = 1
    else
        NowPlayingOpacityTarget = 0
    end

    if CurrentTrack and NowPlayingOpacityTarget == 1 and (CurrentTrack:currentTime() > CurrentTrack:duration()-2 or CurrentTrack:currentTime() < 1 or (SessionSwitched or TrackSwitched)) then
        NowPlayingOpacityTarget = 0
    end

    if NowPlayingOpacityTarget < 0.75 and ui.mouseLocalPos().x > 0 and ui.mouseLocalPos().y > 0 and ui.mouseLocalPos().x < windowWidth.x+windowWidthRange+75*NowPlayingWidgetSize and ui.mouseLocalPos().y < 100*NowPlayingWidgetSize then
        NowPlayingOpacityTarget = 0.75
    end

    if NowPlayingOpacityTarget > NowPlayingOpacityCurrent then
        NowPlayingOpacityCurrent = NowPlayingOpacityCurrent + 0.02
    elseif NowPlayingOpacityTarget < NowPlayingOpacityCurrent then
        NowPlayingOpacityCurrent = NowPlayingOpacityCurrent - 0.02
    end

    if NowPlayingOpacityCurrent < 0.03 and NowPlayingOpacityTarget < 0.03 then
        NowPlayingOpacityCurrent = 0
    end
end