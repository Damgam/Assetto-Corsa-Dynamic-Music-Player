math.randomseed(os.preciseClock())

function table.shuffle(sequence, firstIndex) -- because i'm not sure if it exists.
    firstIndex = firstIndex or 1
    for i = firstIndex, #sequence - 2 + firstIndex do
        local j = math.random(i, #sequence)
        sequence[i], sequence[j] = sequence[j], sequence[i]
    end
end

ConfigFile = ac.INIConfig.load(ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer/" .. "settings.ini")

-- Config
EnableMusic = ConfigFile:get("settings", "appenabled", 1)

ConfigHighIntensityThreshold = ConfigFile:get("settings", "highintensitythreshold", 0.60) -- Low and High Intensity switch level. Scale 0 to 1
--ConfigPauseMusicOnGamePaused = ConfigFile:get("settings", "pauseongamepause", false) -- Completely pause music when game is paused -- Broken, CurrentTrack:isPaused() doesn't exist for some reason

EnablePracticePlaylist = ConfigFile:get("settings", "practiceenabled", true) -- Enable Practice mode playlist, otherwise use Race music
EnableQualifyingPlaylist = ConfigFile:get("settings", "qualifyingenabled", true) -- Enable Qualification mode playlist, otherwise use Race music
EnableIdlePlaylist = ConfigFile:get("settings", "idleenabled", true) -- Enable Waiting mode playlist
EnableFinishPlaylist = ConfigFile:get("settings", "finishenabled", true) -- Enable Finish mode playlist
EnableReplayPlaylist = ConfigFile:get("settings", "replayenabled", true) -- Enable Replay mode playlist
PodiumFinishTop25Percent = ConfigFile:get("settings", "podiumtop25", true) -- if true, podium music plays if you end up in top 25%, if false, plays when you end up in the podium. // Apparently Finish music is broken in Online, yay!

ConfigMaxVolume = ConfigFile:get("settings", "volume", 0.8333) -- Volume relative to ingame Master volume value, percentage.
ConfigMinTargetVolumeMultiplier = ConfigFile:get("settings", "minvolume", 0.4) -- How much can the volume be turned down by dynamic volume controllers. It's percentage of MaxVolume, not an absolute value.
PauseVolumeMultiplier = 0.1 -- Music Volume modifier for when game is paused. It's percentage of MaxVolume, not an absolute value.
ConfigFadeInSpeed = ConfigFile:get("settings", "fadein", 1) -- Percentage per 5 frames. too low might cause problems. Relative to ingame Master volume value.
ConfigFadeOutSpeed = ConfigFile:get("settings", "fadeout", 1)-- Percentage per 5 frames. too low might cause problems. Relative to ingame Master volume value.

EnableDynamicCautionVolume = ConfigFile:get("settings", "cautionfadeout", true) -- turn down music volume during blue and yellow flags, and when you get a penalty.
EnableDynamicProximityVolume = ConfigFile:get("settings", "proximityfadeout", true) -- turn down music volume when opponents are nearby
EnableDynamicSpeedVolume = ConfigFile:get("settings", "speedfadeout", true) -- turn down music volume depending on speed of your car
EnableDynamicCrashingVolume = ConfigFile:get("settings", "crashingfadeout", true) -- turn down music volume when you crash

-- List of files to load. Might turn it into dynamic search if I ever figure out how to do it.
LowDir = '/Music/LowIntensity'
LowMusic = table.map(io.scanDir( __dirname .. LowDir, '*'), function (x) return { string.sub(x, 1, #x - 4), LowDir .. '/' .. x } end)
LowMusicCounter = 0
table.shuffle(LowMusic)

HighDir = '/Music/HighIntensity'
HighMusic = table.map(io.scanDir( __dirname .. HighDir, '*'), function (x) return { string.sub(x, 1, #x - 4), HighDir .. '/' .. x } end)
HighMusicCounter = 0
table.shuffle(HighMusic)

FinishDir = '/Music/FinishLose'
FinishMusic = table.map(io.scanDir( __dirname .. FinishDir, '*'), function (x) return { string.sub(x, 1, #x - 4), FinishDir .. '/' .. x } end)
FinishMusicCounter = 0
table.shuffle(FinishMusic)

FinishPodiumDir = '/Music/FinishPodium'
FinishPodiumMusic = table.map(io.scanDir( __dirname .. FinishPodiumDir, '*'), function (x) return { string.sub(x, 1, #x - 4), FinishPodiumDir .. '/' .. x } end)
FinishPodiumMusicCounter = 0
table.shuffle(FinishPodiumMusic)

ReplayDir = '/Music/Replay'
ReplayMusic = table.map(io.scanDir( __dirname .. ReplayDir, '*'), function (x) return { string.sub(x, 1, #x - 4), ReplayDir .. '/' .. x } end)
ReplayMusicCounter = 0
table.shuffle(ReplayMusic)

PracticeDir = '/Music/Practice'
PracticeMusic = table.map(io.scanDir( __dirname .. PracticeDir, '*'), function (x) return { string.sub(x, 1, #x - 4), PracticeDir .. '/' .. x } end)
PracticeMusicCounter = 0
table.shuffle(PracticeMusic)

QualificationDir = '/Music/Qualifying'
QualificationMusic = table.map(io.scanDir( __dirname .. QualificationDir, '*'), function (x) return { string.sub(x, 1, #x - 4), QualificationDir .. '/' .. x } end)
QualificationMusicCounter = 0
table.shuffle(QualificationMusic)

WaitingDir = '/Music/Waiting'
WaitingMusic = table.map(io.scanDir( __dirname .. WaitingDir, '*'), function (x) return { string.sub(x, 1, #x - 4), WaitingDir .. '/' .. x } end)
WaitingMusicCounter = 0
table.shuffle(WaitingMusic)


TargetVolume = -10
TargetVolumeMultiplier = 1
CurrentVolume = 0
IntensityLevel = 0
IdleTimer = 0
HitValue = 0
HitSpeedLast = 0
IntensityLevel = 0
FadeInSpeedMultiplier = 1
FadeOutSpeedMultiplier = 1

StartMusic = false

Sim                         = ac.getSim()
Car                         = ac.getCar(Sim.focusedCar)
Session                     = ac.getSession(Sim.currentSessionIndex)
CarsInRace                  = #Session.leaderboard
PlayerCarRacePosition       = Car.racePosition
PositionIntensity           = (-((PlayerCarRacePosition - 1)/(CarsInRace - 1)))+1
TimeIntensity               = (-((Sim.sessionTimeLeft/1000/60)/(Session.durationMinutes)))+1
LapIntensity                = (Car.sessionLapCount+1)/Session.laps
PlayerFinished              = false
PlayerBestLapTime           = 180
AverageSpeed                = 200


function updateConfig()
    local MasterVolume = ac.getAudioVolume('main')
    MaxVolume = ConfigMaxVolume * MasterVolume
    MinTargetVolumeMultiplier = ConfigMinTargetVolumeMultiplier
    HighIntensityThreshold = ConfigHighIntensityThreshold
    FadeInSpeed = 0.01 * ConfigFadeInSpeed * MasterVolume * MaxVolume
    FadeOutSpeed = 0.05 * ConfigFadeOutSpeed * MasterVolume * MaxVolume
end
updateConfig()

function updateRaceStatusData()

    Sim = ac.getSim()
    Car = ac.getCar(Sim.focusedCar)
    Session = ac.getSession(Sim.currentSessionIndex)

    CarsInRace = #Session.leaderboard
    PlayerCarRacePosition = Car.racePosition
    PlayerCarSpeed = Car.speedKmh

    if PlayerCarSpeed <= 1 and EnableIdlePlaylist then
        IdleTimer = IdleTimer + 1
    else
        IdleTimer = 0
    end

    if Sim.raceSessionType == 3 and Sim.raceFlagType == 13 and EnableFinishPlaylist then -- finish flag, maybe this one will work reliably in online, lol.
        PlayerFinished = true
    else
        PlayerFinished = false
    end

    if CarsInRace > 1 then
        PositionIntensity = (-((PlayerCarRacePosition - 1)/(CarsInRace - 1)))+1
    else
        PositionIntensity = 1
    end
    TimeIntensity = math.min(1, (-((Sim.sessionTimeLeft/1000/60)/(Session.durationMinutes)))+1)
    LapIntensity = (Car.sessionLapCount+1)/Session.laps

    if Car.sessionLapCount > 0 then
        PlayerBestLapTime = math.max(120, math.ceil(Car.bestLapTimeMs/1000)) -- seconds
        --ac.log("BestLapTime", PlayerBestLapTime)
    end
    
    if PlayerCarSpeed > 10 then -- Ignore standing in place and crashes
        AverageSpeed = math.max(50, (((AverageSpeed*PlayerBestLapTime) + PlayerCarSpeed)/(PlayerBestLapTime+1))) -- funny way to smooth out average value progression
        --ac.log("Average Speed:", AverageSpeed)
    end

    PlayerCarPos = ac.getCar(Car.index).position
    local lowestDistX = 99999
    local lowestDistZ = 99999
    for i = 1,CarsInRace do
        
        local CarIndex = Session.leaderboard[i-1].car.index
        if CarIndex ~= Car.index then
            local CarPos = ac.getCar(CarIndex).position
            local distance = PlayerCarSpeed*0.2
            if CarPos.x >= PlayerCarPos.x-distance and CarPos.x <= PlayerCarPos.x+distance and CarPos.z >= PlayerCarPos.z-distance and CarPos.z <= PlayerCarPos.z+distance then
                local distX = math.abs(PlayerCarPos.x - CarPos.x)
                local distZ = math.abs(PlayerCarPos.z - CarPos.z)
                if distX < lowestDistX then lowestDistX = distX end
                if distZ < lowestDistZ then lowestDistZ = distZ end
            end
        end
    end

    if PlayerFinished then
        TargetVolumeMultiplier = 1
    elseif Sim.isPaused then
        TargetVolumeMultiplier = PauseVolumeMultiplier
    elseif EnableDynamicCautionVolume and (Sim.raceFlagType == 2 or Sim.raceFlagType == 8 or Sim.raceFlagType == 12) then
        TargetVolumeMultiplier = MinTargetVolumeMultiplier
    else
        local SpeedVolumeMultiplier
        local ProximityVolumeMultiplier
        if EnableDynamicSpeedVolume then
            SpeedVolumeMultiplier = math.min(math.max(MinTargetVolumeMultiplier, PlayerCarSpeed/(math.ceil(AverageSpeed)*1.25)), 1)
        else
            SpeedVolumeMultiplier = 1
        end
        if EnableDynamicProximityVolume then
            ProximityVolumeMultiplier = math.max( math.min(math.max(lowestDistX, lowestDistZ)/(PlayerCarSpeed*0.2), 1), MinTargetVolumeMultiplier)
        else
            ProximityVolumeMultiplier = 1
        end
        TargetVolumeMultiplier = math.max(math.min(SpeedVolumeMultiplier, ProximityVolumeMultiplier), MinTargetVolumeMultiplier)
    end
    
    if (not Session.isTimedRace) and Session.type == 3 then
        if not Sim.isOnlineRace then -- Positioning is broken online right now so only use lap count
            IntensityLevel = (PositionIntensity+LapIntensity)/2
        else
            IntensityLevel = LapIntensity
        end

        if LapIntensity > 0.97 then -- boost the volume a little near the end of the race
            TargetVolumeMultiplier = math.min(TargetVolumeMultiplier + TargetVolumeMultiplier*0.20, 1)
        elseif LapIntensity > 0.95 then
            TargetVolumeMultiplier = math.min(TargetVolumeMultiplier + TargetVolumeMultiplier*0.15, 1)
        elseif LapIntensity > 0.93 then
            TargetVolumeMultiplier = math.min(TargetVolumeMultiplier + TargetVolumeMultiplier*0.10, 1)
        end
    else
        if not Sim.isOnlineRace then -- Positioning is broken online right now so only use timer
            --ac.log("posint", PositionIntensity)
            --ac.log("time", TimeIntensity)
            IntensityLevel = (PositionIntensity+TimeIntensity)/2
        else
            IntensityLevel = TimeIntensity
        end

        if TimeIntensity > 0.97 then -- boost the volume a little near the end of the race
            TargetVolumeMultiplier = math.min(TargetVolumeMultiplier + TargetVolumeMultiplier*0.20, 1)
        elseif TimeIntensity > 0.95 then
            TargetVolumeMultiplier = math.min(TargetVolumeMultiplier + TargetVolumeMultiplier*0.15, 1)
        elseif TimeIntensity > 0.93 then
            TargetVolumeMultiplier = math.min(TargetVolumeMultiplier + TargetVolumeMultiplier*0.10, 1)
        end
    end

    if not Sim.isOnlineRace then-- Positions are currently broken in online so lets only use this feature in offline for now
        if PlayerCarRacePosition == 1 then -- boost the volume a little when player is doing well
            TargetVolumeMultiplier = math.min(TargetVolumeMultiplier + TargetVolumeMultiplier*0.20, 1)
        elseif PlayerCarRacePosition <= 3 then
            TargetVolumeMultiplier = math.min(TargetVolumeMultiplier + TargetVolumeMultiplier*0.15, 1)
        elseif PlayerCarRacePosition <= 5 then
            TargetVolumeMultiplier = math.min(TargetVolumeMultiplier + TargetVolumeMultiplier*0.10, 1)
        end
    end

    if EnableDynamicCrashingVolume and HitValue > 0 then
        TargetVolumeMultiplier = TargetVolumeMultiplier*(1-HitValue)
    end

    if MusicType and (
    (MusicType  == "replay" and (not Sim.isReplayActive) and EnableReplayPlaylist) or -- We're not in replay but replay music is playing
    (MusicType  ~= "replay" and Sim.isReplayActive and EnableReplayPlaylist) or -- We're in replay but replay music is not playing
    (MusicType  == "waiting" and PlayerCarSpeed >= 1) or -- Idle Music is playing but we're moving
    (MusicType  ~= "waiting" and PlayerCarSpeed < 1 and IdleTimer > 10 and MusicType  ~= "finish" and MusicType  ~= "replay") or -- We're Idle but non-idle music is playing, just make sure it's not playing finish music.
    (MusicType  == "practice" and Session.type ~= 1) or -- Practice music is playing but we're not in practice
    (MusicType  == "quali" and Session.type ~= 2) or -- Qualification music is playing but we're not in qualis
    ((MusicType == "lowintensity" or MusicType == "highintensity") and Session.type ~= 3) or -- Race music is playing but we're not in race
    (MusicType  == "lowintensity" and IntensityLevel > HighIntensityThreshold*1.1) or -- Low intensity music is playing but it should be playing high instead
    (MusicType  == "highintensity" and IntensityLevel < HighIntensityThreshold*0.9) or -- High intensity music is playing but it should be playing low instead
    (MusicType  ~= "finish" and PlayerFinished) or -- We finished the race
    (EnableMusic == false) or -- We toggled off the music, turn it off
    (CurrentTrack and CurrentTrack:currentTime() > CurrentTrack:duration() - 2) -- Track is almost over, fade it out.
    ) then
        TargetVolume = -10
    else
        TargetVolume = MaxVolume
    end

    if MusicType and ( -- boost fade-in music 
    (MusicType == "finish")
    ) then
        FadeInSpeedMultiplier = 10
    else
        FadeInSpeedMultiplier = 1
    end

    if MusicType and ( -- boost fade-out music 
    (MusicType ~= "finish" and PlayerFinished) or
    HitValue > 0 
    ) then
        FadeOutSpeedMultiplier = 10
    else
        FadeOutSpeedMultiplier = 1
    end

    
end
updateRaceStatusData()

local playedTracks = {}
function getNewTrack()

    local testFilePath

    if Sim.isReplayActive and EnableReplayPlaylist then

        ReplayMusicCounter = ReplayMusicCounter + 1
        testFilePath = ReplayMusic[ReplayMusicCounter]
        MusicType = "replay"

    elseif PlayerFinished then

        if PlayerCarRacePosition <= 3 or (PodiumFinishTop25Percent and PlayerCarRacePosition <= CarsInRace*0.25) then
            FinishPodiumMusicCounter = FinishPodiumMusicCounter + 1
            testFilePath = FinishPodiumMusic[FinishPodiumMusicCounter]
        else
            FinishMusicCounter = FinishMusicCounter + 1
            testFilePath = FinishMusic[FinishMusicCounter]
        end
        MusicType = "finish"

    elseif PlayerCarSpeed <= 1 and EnableIdlePlaylist then

        WaitingMusicCounter = WaitingMusicCounter + 1
        testFilePath = WaitingMusic[WaitingMusicCounter]
        MusicType = "waiting"

    elseif (EnablePracticePlaylist and Session.type == 1) then

        PracticeMusicCounter = PracticeMusicCounter + 1
        testFilePath = PracticeMusic[PracticeMusicCounter]
        MusicType = "practice"

    elseif (EnableQualifyingPlaylist and Session.type == 2) then

        QualificationMusicCounter = QualificationMusicCounter + 1
        testFilePath = QualificationMusic[QualificationMusicCounter]
        MusicType = "quali"

    elseif Session.type == 3 and IntensityLevel < HighIntensityThreshold then

        LowMusicCounter = LowMusicCounter + 1
        testFilePath = LowMusic[LowMusicCounter]
        MusicType = "lowintensity"

    elseif Session.type == 3 then

        HighMusicCounter = HighMusicCounter + 1
        testFilePath = HighMusic[HighMusicCounter]
        MusicType = "highintensity"

    else

        local random = math.random(1,4)
        if EnablePracticePlaylist and random == 1 then

            PracticeMusicCounter = PracticeMusicCounter + 1
            testFilePath = PracticeMusic[PracticeMusicCounter]

        elseif EnableQualifyingPlaylist and random <= 2 then

            QualificationMusicCounter = QualificationMusicCounter + 1
            testFilePath = QualificationMusic[QualificationMusicCounter]

        elseif random <= 3 and HighIntensityThreshold > 0 then

            LowMusicCounter = LowMusicCounter + 1
            testFilePath = LowMusic[LowMusicCounter]

        else

            HighMusicCounter = HighMusicCounter + 1
            testFilePath = HighMusic[HighMusicCounter]

        end
        MusicType = "other"

    end

    ac.log("ReplayMusicCounter", ReplayMusicCounter)
    ac.log("FinishPodiumMusicCounter", FinishPodiumMusicCounter)
    ac.log("FinishMusicCounter", FinishMusicCounter)
    ac.log("WaitingMusicCounter", WaitingMusicCounter)
    ac.log("PracticeMusicCounter", PracticeMusicCounter)
    ac.log("QualificationMusicCounter", QualificationMusicCounter)
    ac.log("LowMusicCounter", LowMusicCounter)
    ac.log("LowMusicCounter", HighMusicCounter)

    FilePath = testFilePath[2]
    ac.log(testFilePath[1], FilePath)

    return FilePath
end

UpdateCounter = 0

function script.update(dt)
    local gameDt = ac.getGameDeltaT()
    UpdateCounter = UpdateCounter+1

    if EnableDynamicCrashingVolume then
        Car = ac.getCar(Sim.focusedCar)
        PlayerCarSpeed = Car.speedKmh

        if HitValue > 0 then
            HitValue = math.max(0, HitValue - FadeInSpeed*0.2)
        elseif HitValue < 0 then
            HitValue = 0
        end

        if Car.collisionDepth > 0 and gameDt > 0 then
            local nHit = math.saturateN((HitSpeedLast - PlayerCarSpeed) / 40)
            if nHit > HitValue then
                HitValue = nHit
            end
        end
        HitSpeedLast = math.applyLag(HitSpeedLast, PlayerCarSpeed, 0.8, gameDt)
    end

    --[[ -- Broken, CurrentTrack:isPaused() doesn't exist for some reason
        if ConfigPauseMusicOnGamePaused then
            local gameIsPaused = ac.getSim().isPaused
            if CurrentTrack and ConfigPauseMusicOnGamePaused and gameIsPaused and (not CurrentTrack:isPaused()) then
                CurrentTrack:pause()
            elseif CurrentTrack and (not gameIsPaused) and CurrentTrack:isPaused() then
                CurrentTrack:play()
            end
        end
    ]]

    if UpdateCounter%60 == 0 then -- Script Updates
        updateConfig()
        updateRaceStatusData()
    end

    if UpdateCounter%60 == 1 and (not CurrentTrack or CurrentTrack:currentTime() >= CurrentTrack:duration() - 1) and ConfigMaxVolume > 0 and EnableMusic then -- Prepare playing new track
        updateRaceStatusData()
        CurrentTrack = ui.MediaPlayer(getNewTrack())
        TargetVolume = MaxVolume
        if StartMusic then
            CurrentVolume = TargetVolume*TargetVolumeMultiplier
            StartMusic = true
        else
            CurrentVolume = 0
        end
        CurrentTrack:setVolume(CurrentVolume)
        CurrentTrack:play()
    end

    if UpdateCounter%5 == 1 then
        if CurrentTrack and CurrentVolume >= (TargetVolume*TargetVolumeMultiplier) + math.min(FadeInSpeed, FadeOutSpeed) then
            if ConfigFadeOutSpeed < 3 then
                CurrentVolume = CurrentVolume - (FadeOutSpeed*FadeOutSpeedMultiplier)
            else
                CurrentVolume = (TargetVolume*TargetVolumeMultiplier)
            end
            CurrentTrack:setVolume(CurrentVolume)
            if CurrentVolume <= 0 and TargetVolume < 0 then
                CurrentTrack:setVolume(0)
                CurrentTrack:setCurrentTime(999999)
                CurrentVolume = 0
            end
        elseif CurrentTrack and CurrentVolume <= (TargetVolume*TargetVolumeMultiplier) - math.min(FadeInSpeed, FadeOutSpeed) then
            if ConfigFadeInSpeed < 3 then
                CurrentVolume = CurrentVolume + (FadeInSpeed*FadeInSpeedMultiplier)
            else
                CurrentVolume = (TargetVolume*TargetVolumeMultiplier)
            end
            CurrentTrack:setVolume(CurrentVolume)
        end
    end

    if HitValue > 0 then
        CurrentTrack:setVolume(CurrentVolume)
    end

end

function script.windowMain()
    local needToSave = false
    local checkbox

    checkbox = ui.checkbox("Enable Music", EnableMusic)
    if checkbox then
        EnableMusic = not EnableMusic
        ConfigFile:set("settings", "appenabled", EnableMusic)
        needToSave = true
    end

    ui.separator()
    ui.text("VOLUME")
    ui.separator()

    ui.text('Maximum Music Volume (Relative to Master volume)')
    local sliderValue1 = ConfigMaxVolume
    sliderValue1 = ui.slider("(Default 0.833) ##slider1", sliderValue1, 0, 1)
    if ConfigMaxVolume ~= sliderValue1 then
        ConfigMaxVolume = sliderValue1
        ConfigFile:set("settings", "volume", sliderValue1)
        needToSave = true
    end

    ui.separator()
    ui.text("SESSIONS")
    ui.separator()

    checkbox = ui.checkbox("Enable Practice Playlist (If disabled, using race music during practice)", EnablePracticePlaylist)
    if checkbox then
        EnablePracticePlaylist = not EnablePracticePlaylist
        ConfigFile:set("settings", "practiceenabled", EnablePracticePlaylist)
        needToSave = true
    end

    checkbox = ui.checkbox("Enable Qualifying Playlist (If disabled, using race music during qualifiers)", EnableQualifyingPlaylist)
    if checkbox then
        EnableQualifyingPlaylist = not EnableQualifyingPlaylist
        ConfigFile:set("settings", "qualifyingenabled", EnableQualifyingPlaylist)
        needToSave = true
    end

    checkbox = ui.checkbox("Enable Idle mode playlist", EnableIdlePlaylist)
    if checkbox then
        EnableIdlePlaylist = not EnableIdlePlaylist
        ConfigFile:set("settings", "idleenabled", EnableIdlePlaylist)
        needToSave = true
    end

    checkbox = ui.checkbox("Enable Replay mode playlist", EnableReplayPlaylist)
    if checkbox then
        EnableReplayPlaylist = not EnableReplayPlaylist
        ConfigFile:set("settings", "replayenabled", EnableReplayPlaylist)
        needToSave = true
    end

    checkbox = ui.checkbox("Enable Finish playlists", EnableFinishPlaylist)
    if checkbox then
        EnableFinishPlaylist = not EnableFinishPlaylist
        ConfigFile:set("settings", "finishenabled", EnableFinishPlaylist)
        needToSave = true
    end

    checkbox = ui.checkbox("Play Victory Music if finished in Top25%, otherwise play only if finished in Top3", PodiumFinishTop25Percent)
    if checkbox then
        PodiumFinishTop25Percent = not PodiumFinishTop25Percent
        ConfigFile:set("settings", "podiumtop25", PodiumFinishTop25Percent)
        needToSave = true
    end

    ui.separator()
    ui.text("BEHAVIOUR")
    ui.separator()

    ui.text('Intensity Level Threshold')
    ui.text('#Intensity percentage at which HighIntensity playlist is used.')
    local sliderValue2 = ConfigHighIntensityThreshold
    sliderValue2 = ui.slider("(Default 0.6) ##slider2", sliderValue2, 0, 1)
    if ConfigHighIntensityThreshold ~= sliderValue2 then
        ConfigHighIntensityThreshold = sliderValue2
        ConfigFile:set("settings", "highintensitythreshold", sliderValue2)
        needToSave = true
    end
    ui.text('?You can drop this all the way to 0 to completely skip')
    ui.text('  low intensity tier and have only one tier of music for races.')
    ui.text('?The value is calculated based on your position related to ')
    ui.text('  the amount of cars in the race, and on how far the race has progressed.')
    ui.text('  Both values contribute 50% of their value, so 100% intensity happens')
    ui.text('  on last lap when you are first.')

    ui.separator()
    ui.text('Minimum Music Volume (For dynamic adjustments)')
    ui.text('#Percentage of Maximum Volume, not an absolute value.')
    local sliderValue3 = ConfigMinTargetVolumeMultiplier
    sliderValue3 = ui.slider("(Default 0.4) ##slider3", sliderValue3, 0, 1)
    if ConfigMinTargetVolumeMultiplier ~= sliderValue3 then
        ConfigMinTargetVolumeMultiplier = sliderValue3
        ConfigFile:set("settings", "minvolume", sliderValue3)
        needToSave = true
    end
    ui.text('?The app is adjusting current volume based on a few events.')
    ui.text('  This value defines how low the volume can drop relative to Max.')
    
    --[[ -- Broken, CurrentTrack:isPaused() doesn't exist for some reason
    ui.separator()
    checkbox = ui.checkbox("Pause music when game is paused", ConfigPauseMusicOnGamePaused)
    if checkbox then
        ConfigPauseMusicOnGamePaused = not ConfigPauseMusicOnGamePaused
        ConfigFile:set("settings", "pauseongamepause", ConfigPauseMusicOnGamePaused)
        needToSave = true
    end
    ui.text('?If disabled, music volume turns very low when paused.')
    ]]
    ui.separator()
    ui.text("FADE TRANSITIONS")
    ui.separator()

    ui.text('Fade-In Speed Multiplier')

    local sliderValue4 = ConfigFile:get("settings", "fadein", 1)
    sliderValue4 = ui.slider("(Default 1) ##slider4", sliderValue4, 0.25, 3)
    if ConfigFadeInSpeed ~= sliderValue4 then
        ConfigFadeInSpeed = sliderValue4
        ConfigFile:set("settings", "fadein", sliderValue4)
        needToSave = true
    end
    ui.text('?Higher is faster. Completely disables fade-ins when maxed.')

    ui.separator()
    ui.text('Fade-Out Speed Multiplier')
    
    local sliderValue5 = ConfigFile:get("settings", "fadeout", 1)
    sliderValue5 = ui.slider("(Default 1) ##slider5", sliderValue5, 0.25, 3)
    if ConfigFadeOutSpeed ~= sliderValue5 then
        ConfigFadeOutSpeed = sliderValue5
        ConfigFile:set("settings", "fadeout", sliderValue5)
        needToSave = true
    end
    ui.text('?Higher is faster. Completely disables fade-outs when maxed.')

    ui.separator()
    ui.text("DYNAMIC VOLUME FADEOUT")
    ui.separator()

    checkbox = ui.checkbox("Enable caution flag volume fadeout", EnableDynamicCautionVolume)
    ui.text('?Volume will drop down when you are under yellow or blue flag.')
    ui.text('  It will also drop when you get a slowdown penalty.')
    ui.text('  It is intended to make you focused during cautious situations.')
    if checkbox then
        EnableDynamicCautionVolume = not EnableDynamicCautionVolume
        ConfigFile:set("settings", "cautionfadeout", EnableDynamicCautionVolume)
        needToSave = true
    end
    ui.separator()

    checkbox = ui.checkbox("Enable opponent proximity volume fadeout", EnableDynamicProximityVolume)
    ui.text('?Volume will drop down when you have other cars around you.')
    ui.text('  Proximity check range also increases with speed.')
    if checkbox then
        EnableDynamicProximityVolume = not EnableDynamicProximityVolume
        ConfigFile:set("settings", "proximityfadeout", EnableDynamicProximityVolume)
        needToSave = true
    end
    ui.separator()

    checkbox = ui.checkbox("Enable low speed volume fadeout", EnableDynamicSpeedVolume)
    ui.text('?Volume will drop down when you drive slow.')
    ui.text('  The app calibrates itself to your car and track combo after a few laps.')
    ui.text('  Starting value is to use average speed of 200.')
    if checkbox then
        EnableDynamicSpeedVolume = not EnableDynamicSpeedVolume
        ConfigFile:set("settings", "speedfadeout", EnableDynamicSpeedVolume)
        needToSave = true
    end
    ui.separator()

    checkbox = ui.checkbox("Enable crashing volume fadeout", EnableDynamicCrashingVolume)
    ui.text('?Volume will drop down when you crash into wall or another car.')
    ui.text('  The harder the crash, the more the volume drops.')
    if checkbox then
        EnableDynamicCrashingVolume = not EnableDynamicCrashingVolume
        ConfigFile:set("settings", "crashingfadeout", EnableDynamicCrashingVolume)
        needToSave = true
    end

    ui.separator()
    ui.text("")
    ui.separator()

    if needToSave then
        ConfigFile:save()
    end
end