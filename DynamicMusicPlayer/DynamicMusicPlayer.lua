math.randomseed(os.preciseClock())

-- Config
MediumIntensityThreshold = 0.30 -- Low and Medium Intensity switch level. Scale 0 to 1
HighIntensityThreshold = 0.60 -- Medium and High Intensity switch level. Scale 0 to 1

PracticeAlwaysLow = true -- Always play Low Intensity tracks in Practice mode
QualifyingAlwaysLow = true -- Always play Low Intensity tracks in Qualifying mode
PodiumFinishTop25Percent = true -- if true, podium music plays if you end up in top 25%, if false, plays when you end up in the podium. // Apparently Finish music is broken in Online, yay!

MaxVolume = 0.3
MinTargetVolumeMultiplier = 0.3 -- How much can the volume be turned down by dynamic volume controllers
PauseVolumeMultiplier = 0.1 -- Music Volume modifier for when game is paused
FadeSpeed = 0.01 -- Percentage per frame. too low might cause problems.

EnableInterruptions = true -- cut off mid-tracks on significant intensity changes

EnableDynamicCautionVolume = true -- turn down music volume during blue and yellow flags.
EnableDynamicProximityVolume = true -- turn down music volume when opponents are nearby - Only works in race! // Actually broken as hell in Online right now. This option is force disabled in online for the time being.
EnableDynamicSpeedVolume = true -- turn down music volume depending on speed of your car

-- List of files to load. Might turn it into dynamic search if I ever figure out how to do it.
LowDir = '/Music/LowIntensity'
LowMusic = table.map(io.scanDir( __dirname .. LowDir, '*'), function (x) return { string.sub(x, 1, #x - 4), LowDir .. '/' .. x } end)

MediumDir = '/Music/MediumIntensity'
MediumMusic = table.map(io.scanDir( __dirname .. MediumDir, '*'), function (x) return { string.sub(x, 1, #x - 4), MediumDir .. '/' .. x } end)

HighDir = '/Music/HighIntensity'
HighMusic = table.map(io.scanDir( __dirname .. HighDir, '*'), function (x) return { string.sub(x, 1, #x - 4), HighDir .. '/' .. x } end)

FinishDir = '/Music/FinishLose'
FinishMusic = table.map(io.scanDir( __dirname .. FinishDir, '*'), function (x) return { string.sub(x, 1, #x - 4), FinishDir .. '/' .. x } end)

FinishPodiumDir = '/Music/FinishPodium'
FinishPodiumMusic = table.map(io.scanDir( __dirname .. FinishPodiumDir, '*'), function (x) return { string.sub(x, 1, #x - 4), FinishPodiumDir .. '/' .. x } end)

ReplayDir = '/Music/Replay'
ReplayMusic = table.map(io.scanDir( __dirname .. ReplayDir, '*'), function (x) return { string.sub(x, 1, #x - 4), ReplayDir .. '/' .. x } end)

TargetVolume = -10
TargetVolumeMultiplier = 1
CurrentVolume = 0
IntensityLevel = 0

-- ac.getCar(N).racePosition
Sim                         = ac.getSim()
Car                         = ac.getCar(Sim.focusedCar)
Session                     = ac.getSession(Sim.currentSessionIndex)
CarsInRace                  = #Session.leaderboard
PlayerCarPosition           = Car.racePosition
PositionIntensity           = (-((PlayerCarPosition - 1)/(CarsInRace - 1)))+1
TimeIntensity               = (-((Sim.sessionTimeLeft/1000/60)/(Session.durationMinutes)))+1
LapIntensity                = (Car.sessionLapCount+1)/Session.laps

MusicInitialised = false
IntensityLevel = 0
local PreviousTrackIntensity = 0

function updateRaceStatusData()

    Sim = ac.getSim()
    Car = ac.getCar(Sim.focusedCar)
    Session = ac.getSession(Sim.currentSessionIndex)
    CarsInRace = #Session.leaderboard
    PlayerCarPosition = Car.racePosition
    PlayerFinished = Session.leaderboard[PlayerCarPosition-1].hasCompletedLastLap
    PositionIntensity = (-((PlayerCarPosition - 1)/(CarsInRace - 1)))+1
    TimeIntensity = (-((Sim.sessionTimeLeft/1000/60)/(Session.durationMinutes)))+1
    LapIntensity = (Car.sessionLapCount+1)/Session.laps
    PlayerCarSpeed = Car.speedKmh
    local CarInFront
    local CarInRear
    for i = 1,CarsInRace do
        local CarIndex = Session.leaderboard[i-1].car.index
        local CarPosition = ac.getCar(CarIndex).racePosition
        if CarPosition == PlayerCarPosition - 1 then
            GapToFront = ac.getGapBetweenCars(CarIndex, Car.index)
            --ac.log("CarInFront", CarPosition)
            CarInFront = true
        end
        if CarPosition == PlayerCarPosition + 1 then
            GapToRear = ac.getGapBetweenCars(CarIndex, Car.index)
            --ac.log("CarInRear", CarPosition)
            CarInRear = true
        end
    end

    if not CarInFront then GapToFront = 10 end
    if not CarInRear then GapToRear = 10 end

    if PlayerFinished then
        TargetVolumeMultiplier = 1
    elseif Sim.isPaused then
        TargetVolumeMultiplier = PauseVolumeMultiplier
    elseif EnableDynamicCautionVolume and (Sim.raceFlagType == 2 or Sim.raceFlagType == 8 or Sim.raceFlagType == 12) then
        TargetVolumeMultiplier = MinTargetVolumeMultiplier
    elseif Session.type == 3 and not Sim.isOnlineRace then -- yet another dirty online fix
        local SpeedVolumeMultiplier
        local ProximityVolumeMultiplier
        if EnableDynamicSpeedVolume then
            SpeedVolumeMultiplier = math.min(math.max(MinTargetVolumeMultiplier, PlayerCarSpeed/300), 1)
        else
            SpeedVolumeMultiplier = 1
        end
        if EnableDynamicProximityVolume then
            ProximityVolumeMultiplier = math.min(math.min(-GapToFront or 10, 1), math.min(GapToRear or 10, 1))
        else
            ProximityVolumeMultiplier = 1
        end
        --ac.log("GapToFront", GapToFront)
        --ac.log("GapToRear", GapToRear)
        TargetVolumeMultiplier = math.max(math.min(SpeedVolumeMultiplier, ProximityVolumeMultiplier), MinTargetVolumeMultiplier)
    else
        if EnableDynamicSpeedVolume then
            TargetVolumeMultiplier = math.min(math.max(MinTargetVolumeMultiplier, PlayerCarSpeed/300), 1)
        else
            TargetVolumeMultiplier = 1
        end
    end

    -- init
    if not MusicInitialised and Sim.timeToSessionStart < 0 and (not PlayerFinished) then
        MusicInitialised = true
        if Session.type == 3 then
            StartMusic = true
        end
        InitDone = true
    end
    if Sim.isOnlineRace then -- yet another dirty fix for broken online
        PositionIntensity = 1
    end
    if (not Session.isTimedRace) and Session.type == 3 then
        IntensityLevel = (PositionIntensity+(LapIntensity*3))/4
    else
        IntensityLevel = (PositionIntensity+(TimeIntensity*3))/4
    end

    if not Sim.isOnlineRace then -- Positions are currently broken in online so lets only use this feature in offline for now
        if IntensityLevel > 0.95 then
            TargetVolumeMultiplier = math.min(TargetVolumeMultiplier + TargetVolumeMultiplier*0.3, 1)
        elseif IntensityLevel > 0.90 then
            TargetVolumeMultiplier = math.min(TargetVolumeMultiplier + TargetVolumeMultiplier*0.2, 1)
        elseif IntensityLevel > 0.85 then
            TargetVolumeMultiplier = math.min(TargetVolumeMultiplier + TargetVolumeMultiplier*0.1, 1)
        end

        if PlayerCarPosition == 1 then
            TargetVolumeMultiplier = math.min(TargetVolumeMultiplier + TargetVolumeMultiplier*0.3, 1)
        elseif PlayerCarPosition <= 3 then
            TargetVolumeMultiplier = math.min(TargetVolumeMultiplier + TargetVolumeMultiplier*0.2, 1)
        elseif PlayerCarPosition <= 5 then
            TargetVolumeMultiplier = math.min(TargetVolumeMultiplier + TargetVolumeMultiplier*0.1, 1)
        end
    end

    if (not Sim.isReplayActive) and EnableInterruptions and (Session.type ~= 1 or Session.type ~= 2) and (not PlayerFinished) then
        if (PreviousTrackIntensity < MediumIntensityThreshold and IntensityLevel > MediumIntensityThreshold*1.10) or
        (PreviousTrackIntensity < HighIntensityThreshold and IntensityLevel > HighIntensityThreshold*1.10) or
        (PreviousTrackIntensity > MediumIntensityThreshold and IntensityLevel < MediumIntensityThreshold*0.9) or
        (PreviousTrackIntensity > HighIntensityThreshold and IntensityLevel < HighIntensityThreshold*0.9) then
            TargetVolume = -10
            ForcePlayNewTrack = true
        end
    end

    if CurrentTrack and CurrentTrack:duration() < CurrentTrack:currentTime() - 5 then
        TargetVolume = -10
        ForcePlayNewTrack = true
    end

end
updateRaceStatusData()


function getNewTrack()

    -- ac.log("IntensityLevel", IntensityLevel)
    -- ac.log("Session Type", Session.type)
    -- ac.log("PositionIntensity", PositionIntensity)
    -- ac.log("TimeIntensity", TimeIntensity)
    -- ac.log("LapIntensity", LapIntensity)
    local testFilePath
    repeat
        if Sim.isReplayActive then
            testFilePath = ReplayMusic[math.random(1,#ReplayMusic)][2]
            PreviousTrackIntensity = 1
        elseif IntensityLevel < MediumIntensityThreshold or (PracticeAlwaysLow and Session.type == 1) or (QualifyingAlwaysLow and Session.type == 2) then
            testFilePath = LowMusic[math.random(1,#LowMusic)][2]
            PreviousTrackIntensity = IntensityLevel
        elseif IntensityLevel < HighIntensityThreshold then
            testFilePath = MediumMusic[math.random(1,#MediumMusic)][2]
            PreviousTrackIntensity = IntensityLevel
        else
            testFilePath = HighMusic[math.random(1,#HighMusic)][2]
            PreviousTrackIntensity = IntensityLevel
        end
        if testFilePath ~= FilePath then -- don't play the same track twice in a row
            FilePath = testFilePath
        end
    until FilePath
    --ac.log(FilePath)
    return FilePath
end

function getFinishTrack(pos)
    if pos <= 3 or (PodiumFinishTop25Percent and pos <= CarsInRace*0.25) then
        FilePath = FinishPodiumMusic[math.random(1,#FinishPodiumMusic)][2]
    else
        FilePath = FinishMusic[math.random(1,#FinishMusic)][2]
    end
    --ac.log(FilePath)
    return FilePath
end

UpdateCounter = 0
local PreviousSessionIndex = Sim.currentSessionIndex
function script.update(dt)
    UpdateCounter = UpdateCounter+1

    if UpdateCounter%60 == 0 or not InitDone then -- Check if player has finished the race

        updateRaceStatusData()

        if PreviousSessionIndex ~= Sim.currentSessionIndex then
            MusicInitialised = false
            if Session.type == 3 then
                StartMusic = true
            end
            InitDone = false
            PlayedFinishMusic = false
            PlayerFinished = false
            PreviousSessionIndex = Sim.currentSessionIndex
            TargetVolume = -10
        end

        if ac.getSim().timeToSessionStart > 0 then
            TargetVolume = -10
        end
        
        if Session.type == 3 and PlayerFinished and (not PlayedFinishMusic) then
            if CurrentTrack then
                CurrentTrack:setCurrentTime(99999999)
            end
            CurrentTrack = ui.MediaPlayer(getFinishTrack(PlayerCarPosition))
            TargetVolume = MaxVolume
            CurrentVolume = TargetVolume
            CurrentTrack:setVolume(CurrentVolume)
            CurrentTrack:play()
            PlayedFinishMusic = true
        end
    end

    if StartMusic or ( MusicInitialised and (CurrentTrack ~= nil and CurrentTrack:ended()) or CurrentTrack == nil ) and (not PlayerFinished) and Sim.timeToSessionStart < 0 then
        updateRaceStatusData()

        CurrentTrack = ui.MediaPlayer(getNewTrack())
        TargetVolume = MaxVolume
        if StartMusic then
            CurrentVolume = TargetVolume*TargetVolumeMultiplier
            StartMusic = false
        else
            CurrentVolume = 0
        end
        CurrentTrack:setVolume(CurrentVolume)
        CurrentTrack:play()
        return
    end
    if UpdateCounter%5 == 1 then
        if CurrentTrack and CurrentVolume > (TargetVolume*TargetVolumeMultiplier) + FadeSpeed then
            CurrentVolume = CurrentVolume - FadeSpeed
            CurrentTrack:setVolume(CurrentVolume)
            if CurrentVolume <= 0 then
                CurrentTrack:setCurrentTime(99999999)
                CurrentTrack:setVolume(0)
                CurrentVolume = 0
                if ForcePlayNewTrack then
                    CurrentTrack = ui.MediaPlayer(getNewTrack())
                    CurrentTrack:setVolume(0)
                    CurrentVolume = 0
                    CurrentTrack:play()
                    ForcePlayNewTrack = false
                end
            end
        elseif CurrentTrack and CurrentVolume < (TargetVolume*TargetVolumeMultiplier) - FadeSpeed then
            CurrentVolume = CurrentVolume + FadeSpeed
            CurrentTrack:setVolume(CurrentVolume)
        end
    end
end