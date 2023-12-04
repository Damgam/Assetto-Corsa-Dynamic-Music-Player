math.randomseed(os.preciseClock())

-- Config
HighIntensityThreshold = 0.60 -- Low and High Intensity switch level. Scale 0 to 1

EnablePracticePlaylist = true -- Enable Practice mode playlist, otherwise use Race music
EnableQualifyingPlaylist = true -- Enable Qualification mode playlist, otherwise use Race music
PodiumFinishTop25Percent = true -- if true, podium music plays if you end up in top 25%, if false, plays when you end up in the podium. // Apparently Finish music is broken in Online, yay!

MaxVolume = 0.3
MinTargetVolumeMultiplier = 0.3 -- How much can the volume be turned down by dynamic volume controllers
PauseVolumeMultiplier = 0.1 -- Music Volume modifier for when game is paused
FadeInSpeed = 0.001 -- Percentage per 5 frames. too low might cause problems.
FadeOutSpeed = 0.005 -- Percentage per 5 frames. too low might cause problems.

EnableInterruptions = true -- cut off mid-tracks on significant intensity changes

EnableDynamicCautionVolume = true -- turn down music volume during blue and yellow flags, and when you get a penalty.
EnableDynamicProximityVolume = true -- turn down music volume when opponents are nearby
EnableDynamicSpeedVolume = true -- turn down music volume depending on speed of your car

-- List of files to load. Might turn it into dynamic search if I ever figure out how to do it.
LowDir = '/Music/LowIntensity'
LowMusic = table.map(io.scanDir( __dirname .. LowDir, '*'), function (x) return { string.sub(x, 1, #x - 4), LowDir .. '/' .. x } end)

HighDir = '/Music/HighIntensity'
HighMusic = table.map(io.scanDir( __dirname .. HighDir, '*'), function (x) return { string.sub(x, 1, #x - 4), HighDir .. '/' .. x } end)

FinishDir = '/Music/FinishLose'
FinishMusic = table.map(io.scanDir( __dirname .. FinishDir, '*'), function (x) return { string.sub(x, 1, #x - 4), FinishDir .. '/' .. x } end)

FinishPodiumDir = '/Music/FinishPodium'
FinishPodiumMusic = table.map(io.scanDir( __dirname .. FinishPodiumDir, '*'), function (x) return { string.sub(x, 1, #x - 4), FinishPodiumDir .. '/' .. x } end)

ReplayDir = '/Music/Replay'
ReplayMusic = table.map(io.scanDir( __dirname .. ReplayDir, '*'), function (x) return { string.sub(x, 1, #x - 4), ReplayDir .. '/' .. x } end)

PracticeDir = '/Music/Practice'
PracticeMusic = table.map(io.scanDir( __dirname .. PracticeDir, '*'), function (x) return { string.sub(x, 1, #x - 4), PracticeDir .. '/' .. x } end)

QualificationDir = '/Music/Qualifying'
QualificationMusic = table.map(io.scanDir( __dirname .. QualificationDir, '*'), function (x) return { string.sub(x, 1, #x - 4), QualificationDir .. '/' .. x } end)

WaitingDir = '/Music/Waiting'
WaitingMusic = table.map(io.scanDir( __dirname .. WaitingDir, '*'), function (x) return { string.sub(x, 1, #x - 4), WaitingDir .. '/' .. x } end)

TargetVolume = -10
TargetVolumeMultiplier = 1
CurrentVolume = 0
IntensityLevel = 0
IdleTimer = 0

StartMusic = false

Sim                         = ac.getSim()
Car                         = ac.getCar(Sim.focusedCar)
Session                     = ac.getSession(Sim.currentSessionIndex)
CarsInRace                  = #Session.leaderboard
PlayerCarRacePosition           = Car.racePosition
PositionIntensity           = (-((PlayerCarRacePosition - 1)/(CarsInRace - 1)))+1
TimeIntensity               = (-((Sim.sessionTimeLeft/1000/60)/(Session.durationMinutes)))+1
LapIntensity                = (Car.sessionLapCount+1)/Session.laps
PlayerFinished              = false
PlayerBestLapTime           = 180
AverageSpeed                = 200

IntensityLevel = 0

function updateRaceStatusData()

    Sim = ac.getSim()
    Car = ac.getCar(Sim.focusedCar)
    Session = ac.getSession(Sim.currentSessionIndex)

    CarsInRace = #Session.leaderboard
    PlayerCarRacePosition = Car.racePosition
    PlayerCarSpeed = Car.speedKmh

    if PlayerCarSpeed <= 1 then
        IdleTimer = IdleTimer + 1
    else
        IdleTimer = 0
    end

    if Sim.raceSessionType == 3 and Sim.raceFlagType == 13 then -- finish flag, maybe this one will work reliably in online, lol.
        PlayerFinished = true
    else
        PlayerFinished = false
    end

    PositionIntensity = (-((PlayerCarRacePosition - 1)/(CarsInRace - 1)))+1
    TimeIntensity = (-((Sim.sessionTimeLeft/1000/60)/(Session.durationMinutes)))+1
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

    if MusicType and (
    (MusicType  == "replay" and (not Sim.isReplayActive)) or -- We're not in replay but replay music is playing
    (MusicType  ~= "replay" and Sim.isReplayActive) or -- We're in replay but replay music is not playing
    (MusicType  == "waiting" and PlayerCarSpeed >= 1) or -- Idle Music is playing but we're moving
    (MusicType  ~= "waiting" and PlayerCarSpeed < 1 and IdleTimer > 10 and MusicType  ~= "finish") or -- We're Idle but non-idle music is playing, just make sure it's not playing finish music.
    (MusicType  == "practice" and Sim.raceSessionType ~= 1) or -- Practice music is playing but we're not in practice
    (MusicType  == "quali" and Sim.raceSessionType ~= 2) or -- Qualification music is playing but we're not in qualis
    ((MusicType == "lowintensity" or MusicType == "highintensity") and Sim.raceSessionType ~= 3) or -- Race music is playing but we're not in race
    (MusicType  == "lowintensity" and IntensityLevel > HighIntensityThreshold*1.1) or -- Low intensity music is playing but it should be playing high instead
    (MusicType  == "highintensity" and IntensityLevel < HighIntensityThreshold*0.9) or -- High intensity music is playing but it should be playing low instead
    (MusicType  ~= "finish" and PlayerFinished) or -- Player has finished the race
    (CurrentTrack and CurrentTrack:currentTime() > CurrentTrack:duration() - 2) -- Track is almost over, fade it out.
    ) then
        TargetVolume = -10
    end
end
updateRaceStatusData()


function getNewTrack()

    local testFilePath

    repeat
        if Sim.isReplayActive then

            testFilePath = ReplayMusic[math.random(1,#ReplayMusic)][2]
            MusicType = "replay"

        elseif PlayerFinished then

            if PlayerCarRacePosition <= 3 or (PodiumFinishTop25Percent and PlayerCarRacePosition <= CarsInRace*0.25) then
                testFilePath = FinishPodiumMusic[math.random(1,#FinishPodiumMusic)][2]
            else
                testFilePath = FinishMusic[math.random(1,#FinishMusic)][2]
            end
            MusicType = "finish"

        elseif PlayerCarSpeed <= 1 then

            testFilePath = WaitingMusic[math.random(1,#WaitingMusic)][2]
            MusicType = "waiting"

        elseif (EnablePracticePlaylist and Session.type == 1) then

            testFilePath = PracticeMusic[math.random(1,#PracticeMusic)][2]
            MusicType = "practice"

        elseif (EnableQualifyingPlaylist and Session.type == 2) then

            testFilePath = QualificationMusic[math.random(1,#QualificationMusic)][2]
            MusicType = "quali"

        elseif IntensityLevel < HighIntensityThreshold then

            testFilePath = LowMusic[math.random(1,#LowMusic)][2]
            MusicType = "lowintensity"

        else

            testFilePath = HighMusic[math.random(1,#HighMusic)][2]
            MusicType = "highintensity"

        end

        if testFilePath ~= FilePath then -- don't play the same track twice in a row
            FilePath = testFilePath
        end

    until FilePath

    ac.log(FilePath)

    return FilePath
end

UpdateCounter = 0
function script.update(dt)
    UpdateCounter = UpdateCounter+1

    if UpdateCounter%60 == 0 then -- Script Updates
        updateRaceStatusData()
    end

    if UpdateCounter%60 == 1 and (not CurrentTrack or CurrentTrack:currentTime() >= CurrentTrack:duration() - 1) then -- Prepare playing new track
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
            CurrentVolume = CurrentVolume - FadeOutSpeed
            CurrentTrack:setVolume(CurrentVolume)
            if CurrentVolume <= 0 and TargetVolume < 0 then
                CurrentTrack:setVolume(0)
                CurrentTrack:setCurrentTime(999999)
                CurrentVolume = 0
            end
        elseif CurrentTrack and CurrentVolume <= (TargetVolume*TargetVolumeMultiplier) - math.min(FadeInSpeed, FadeOutSpeed) then
            CurrentVolume = CurrentVolume + FadeInSpeed
            CurrentTrack:setVolume(CurrentVolume)
        end
    end

end