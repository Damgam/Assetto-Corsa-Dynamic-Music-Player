---@ext
CSPBuild = ac.getPatchVersionCode()
math.randomseed(os.preciseClock())

function table.shuffle(sequence, firstIndex) -- because i'm not sure if it exists.
    firstIndex = firstIndex or 1
    for i = firstIndex, #sequence - 2 + firstIndex do
        local j = math.random(i, #sequence)
        sequence[i], sequence[j] = sequence[j], sequence[i]
    end
end

function table_append(appendTarget, appendData)
    for _, value in pairs(appendData) do
        table.insert(appendTarget, value)
    end
end

function string_formatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local seconds = math.floor(seconds % 60)
    local hoursString = tostring(hours)
    local minutesString = tostring(minutes)
    local secondsString = tostring(seconds)
    if seconds < 10 then
        secondsString = "0" .. secondsString
    end
    if hours > 0 and minutes < 10 then
        minutesString = "0" .. minutesString
    end
    if hours > 0 then
        return hoursString .. ":" .. minutesString .. ":" .. secondsString
    else
        return minutesString .. ":" .. secondsString
    end
end

function scalePercentage(x, minVolume)
    return minVolume + x * (1 - minVolume)
end

------
local gcSmooth = 0
local gcRuns = 0
local gcLast = 0
local function runGC()
    local before = collectgarbage('count')
    collectgarbage()
    gcSmooth = math.applyLag(gcSmooth, before - collectgarbage('count'), gcRuns < 50 and 0.9 or 0.995, 0.05)
    gcRuns = gcRuns + 1
    gcLast = math.floor(gcSmooth * 100) / 100
end

local function printGC()
ac.debug("Runtime | collectgarbage", gcLast .. " KB")
end
------

ConfigFile = ac.INIConfig.load(ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer/" .. "settings.ini")

-- Config
EnableMusic = ConfigFile:get("settings", "appenabled", true)

EnablePracticePlaylist = ConfigFile:get("settings", "practiceenabled", true) -- Enable Practice mode playlist, otherwise use Race music
EnableQualifyingPlaylist = ConfigFile:get("settings", "qualifyingenabled", true) -- Enable Qualification mode playlist, otherwise use Race music
EnableIdlePlaylist = ConfigFile:get("settings", "idleenabled", true) -- Enable Idle mode playlist
EnableIdlePlaylistOutsidePits = ConfigFile:get("settings", "idleoutsidepits", true) -- Enable Idle mode playlist outside of pits (if the car is standing in place)
EnableFinishPlaylist = ConfigFile:get("settings", "finishenabled", true) -- Enable Finish mode playlist
EnableReplayPlaylist = ConfigFile:get("settings", "replayenabled", true) -- Enable Replay mode playlist
PodiumFinishTop25Percent = ConfigFile:get("settings", "podiumtop25", true) -- if true, podium music plays if you end up in top 25%, if false, plays when you end up in the podium. // Apparently Finish music is broken in Online, yay!

ConfigMaxVolume = ConfigFile:get("settings", "volume", 0.8333) -- Volume relative to ingame Master volume value, percentage.
ConfigMinTargetVolumeMultiplier = ConfigFile:get("settings", "minvolume", 0.4) -- How much can the volume be turned down by dynamic volume controllers. It's percentage of MaxVolume, not an absolute value.
ConfigFadeInSpeed = ConfigFile:get("settings", "fadein", 1) -- Percentage per 5 frames. too low might cause problems. Relative to ingame Master volume value.
ConfigFadeOutSpeed = ConfigFile:get("settings", "fadeout", 1)-- Percentage per 5 frames. too low might cause problems. Relative to ingame Master volume value.

EnableDynamicCautionVolume = ConfigFile:get("settings", "cautionfadeout", true) -- turn down music volume during blue and yellow flags, and when you get a penalty.
EnableDynamicProximityVolume = ConfigFile:get("settings", "proximityfadeout", true) -- turn down music volume when opponents are nearby
EnableDynamicSpeedVolume = ConfigFile:get("settings", "speedfadeout", true) -- turn down music volume depending on speed of your car
EnableDynamicCrashingVolume = ConfigFile:get("settings", "crashingfadeout", true) -- turn down music volume when you crash
EnableDynamicCrashingTrackSkip = ConfigFile:get("settings", "crashingfadeouttrackskip", false) -- turn down music volume when you crash

ConfigMinimumCautionVolume = ConfigFile:get("settings", "mincautionvolume", 0.1)
ConfigMinimumProximityVolume = ConfigFile:get("settings", "minproximityvolume", 0.5)
ConfigMinimumSpeedVolume = ConfigFile:get("settings", "minspeedvolume", 0.5)
ConfigMinimumPauseVolume = ConfigFile:get("settings", "minpausevolume", 0.1)

EnableNowPlayingIcon = ConfigFile:get("settings", "nowplayingicon", true)
EnableAnimatedNowPlayingIcon = ConfigFile:get("settings", "nowplayinganimatedicon", true)
EnableNowPlayingTime = ConfigFile:get("settings", "nowplayingtime", true)
NowPlayingWidgetSize = ConfigFile:get("settings", "nowplayingscale", 1)
EnableNowPlayingWidgetFadeout = ConfigFile:get("settings", "nowplayingfadeout", true)
NowPlayingWidgetFadeoutTime = ConfigFile:get("settings", "nowplayingfadeouttime", 10)


ExternalMusic = require('Music/ExternalMusicPaths')

OtherDir = '/Music/Other'
OtherMusic = table.map(io.scanDir( __dirname .. OtherDir, '*'), function (x) return { string.sub(x, 1, #x - 4), OtherDir .. '/' .. x } end)
if ExternalMusic and ExternalMusic.Other and ExternalMusic.Other[1] then
    for i = 1,#ExternalMusic.Other do
        local table = table.map(io.scanDir( ExternalMusic.Other[i], '*'), function (x) return { string.sub(x, 1, #x - 4), ExternalMusic.Other[i] .. '/' .. x } end)
        table_append(OtherMusic, table)
    end
end
OtherMusicCounter = 0
table.shuffle(OtherMusic)

RaceDir = '/Music/Race'
RaceMusic = table.map(io.scanDir( __dirname .. RaceDir, '*'), function (x) return { string.sub(x, 1, #x - 4), RaceDir .. '/' .. x } end)
if ExternalMusic and ExternalMusic.Race and ExternalMusic.Race[1] then
    for i = 1,#ExternalMusic.Race do
        local table = table.map(io.scanDir( ExternalMusic.Race[i], '*'), function (x) return { string.sub(x, 1, #x - 4), ExternalMusic.Race[i] .. '/' .. x } end)
        table_append(RaceMusic, table)
    end
end
RaceMusicCounter = 0
table.shuffle(RaceMusic)

FinishDir = '/Music/Finish'
FinishMusic = table.map(io.scanDir( __dirname .. FinishDir, '*'), function (x) return { string.sub(x, 1, #x - 4), FinishDir .. '/' .. x } end)
if ExternalMusic and ExternalMusic.Finish and ExternalMusic.Finish[1] then
    for i = 1,#ExternalMusic.Finish do
        local table = table.map(io.scanDir( ExternalMusic.Finish[i], '*'), function (x) return { string.sub(x, 1, #x - 4), ExternalMusic.Finish[i] .. '/' .. x } end)
        table_append(FinishMusic, table)
    end
end
FinishMusicCounter = 0
table.shuffle(FinishMusic)

FinishPodiumDir = '/Music/FinishPodium'
FinishPodiumMusic = table.map(io.scanDir( __dirname .. FinishPodiumDir, '*'), function (x) return { string.sub(x, 1, #x - 4), FinishPodiumDir .. '/' .. x } end)
if ExternalMusic and ExternalMusic.FinishPodium and ExternalMusic.FinishPodium[1] then
    for i = 1,#ExternalMusic.FinishPodium do
        local table = table.map(io.scanDir( ExternalMusic.FinishPodium[i], '*'), function (x) return { string.sub(x, 1, #x - 4), ExternalMusic.FinishPodium[i] .. '/' .. x } end)
        table_append(FinishPodiumMusic, table)
    end
end
FinishPodiumMusicCounter = 0
table.shuffle(FinishPodiumMusic)

ReplayDir = '/Music/Replay'
ReplayMusic = table.map(io.scanDir( __dirname .. ReplayDir, '*'), function (x) return { string.sub(x, 1, #x - 4), ReplayDir .. '/' .. x } end)
if ExternalMusic and ExternalMusic.Replay and ExternalMusic.Replay[1] then
    for i = 1,#ExternalMusic.Replay do
        local table = table.map(io.scanDir( ExternalMusic.Replay[i], '*'), function (x) return { string.sub(x, 1, #x - 4), ExternalMusic.Replay[i] .. '/' .. x } end)
        table_append(ReplayMusic, table)
    end
end
ReplayMusicCounter = 0
table.shuffle(ReplayMusic)

PracticeDir = '/Music/Practice'
PracticeMusic = table.map(io.scanDir( __dirname .. PracticeDir, '*'), function (x) return { string.sub(x, 1, #x - 4), PracticeDir .. '/' .. x } end)
if ExternalMusic and ExternalMusic.Practice and ExternalMusic.Practice[1] then
    for i = 1,#ExternalMusic.Practice do
        local table = table.map(io.scanDir( ExternalMusic.Practice[i], '*'), function (x) return { string.sub(x, 1, #x - 4), ExternalMusic.Practice[i] .. '/' .. x } end)
        table_append(PracticeMusic, table)
    end
end
PracticeMusicCounter = 0
table.shuffle(PracticeMusic)

QualificationDir = '/Music/Qualifying'
QualificationMusic = table.map(io.scanDir( __dirname .. QualificationDir, '*'), function (x) return { string.sub(x, 1, #x - 4), QualificationDir .. '/' .. x } end)
if ExternalMusic and ExternalMusic.Qualification and ExternalMusic.Qualification[1] then
    for i = 1,#ExternalMusic.Qualification do
        local table = table.map(io.scanDir( ExternalMusic.Qualification[i], '*'), function (x) return { string.sub(x, 1, #x - 4), ExternalMusic.Qualification[i] .. '/' .. x } end)
        table_append(QualificationMusic, table)
    end
end
QualificationMusicCounter = 0
table.shuffle(QualificationMusic)

IdleDir = '/Music/Idle'
IdleMusic = table.map(io.scanDir( __dirname .. IdleDir, '*'), function (x) return { string.sub(x, 1, #x - 4), IdleDir .. '/' .. x } end)
if ExternalMusic and ExternalMusic.Idle and ExternalMusic.Idle[1] then
    for i = 1,#ExternalMusic.Idle do
        local table = table.map(io.scanDir( ExternalMusic.Idle[i], '*'), function (x) return { string.sub(x, 1, #x - 4), ExternalMusic.Idle[i] .. '/' .. x } end)
        table_append(IdleMusic, table)
    end
end
IdleMusicCounter = 0
table.shuffle(IdleMusic)


TargetVolume = -10
TargetVolumeMultiplier = 1
CurrentVolume = 0
IdleTimer = 10
HitValue = 0
HitSpeedLast = 0
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
AverageSpeed                = 100
TopSpeed                    = 0
CautionVolume               = 1

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


function updateConfig()
    local MasterVolume = ac.getAudioVolume('main')
    MaxVolume = ConfigMaxVolume * MasterVolume
    MinimumCautionVolume = ConfigMinimumCautionVolume
    MinimumProximityVolume = ConfigMinimumProximityVolume
    MinimumSpeedVolume = ConfigMinimumSpeedVolume
    MinimumPauseVolume = ConfigMinimumPauseVolume
    FadeInSpeed = 0.01 * ConfigFadeInSpeed * MaxVolume
    FadeOutSpeed = 0.05 * ConfigFadeOutSpeed * MaxVolume
end
updateConfig()

local previousSessionStartTimer = 99999999
PlayedFinishTrack = false
SessionSwitched = false
TrackSwitched = false
function updateRaceStatusData()

    Sim = ac.getSim()
    Car = ac.getCar(Sim.focusedCar)
    Session = ac.getSession(Sim.currentSessionIndex)

    CarsInRace = #Session.leaderboard
    PlayerCarRacePosition = Car.racePosition
    PlayerCarSpeed = Car.speedKmh

    if PlayerCarSpeed > TopSpeed then
        TopSpeed = PlayerCarSpeed
    end

    if ((Car.isInPitlane or Car.isInPit) or (Sim.timeToSessionStart > 0)) and EnableIdlePlaylist then
        IdleTimer = math.max(11, IdleTimer)
    elseif PlayerCarSpeed <= 1 and EnableIdlePlaylist and EnableIdlePlaylistOutsidePits then
        IdleTimer = IdleTimer + 1
    else
        IdleTimer = 0
    end

    if Sim.raceSessionType == 3 and Sim.raceFlagType == 13 and EnableFinishPlaylist and (not Sim.isReplayActive) then -- finish flag, maybe this one will work reliably in online, lol.
        PlayerFinished = true
    else
        PlayerFinished = false
    end

    if (not PlayerFinished) and PlayedFinishTrack then
        PlayedFinishTrack = false
    end

    RaceStartVolumeMultiplier = 1
    if Session.type == 3 and Sim.timeToSessionStart > 0 and Sim.timeToSessionStart < 60000 then
        IdleTimer = -10
        --SessionSwitched = true
        RaceStartVolumeMultiplier = math.max(0, math.min(1, (Sim.timeToSessionStart-10000)/60000))
        StartMusic = true
        if Sim.timeToSessionStart < 10000 then
            SessionSwitched = true
        end
    elseif previousSessionStartTimer < Sim.timeToSessionStart-1 and (not Sim.isReplayActive) then
        if EnableIdlePlaylist then
            IdleTimer = math.max(11, IdleTimer)
        end
        SessionSwitched = true
    end

    previousSessionStartTimer = Sim.timeToSessionStart

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
    local lowestDist = 99999

    local lowestDist = 9999999
    for i = 1,9999 do
        if ac.getCar(i-1) and i-1 ~= 0 then
            local distance = math.distance(ac.getCar(0).position, ac.getCar(i-1).position)
            if distance < lowestDist then
                lowestDist = distance
            end
        elseif not ac.getCar(i-1) then
            break
        end
    end

    if PlayerFinished or MusicType == "idle" then
        TargetVolumeMultiplier = 1*RaceStartVolumeMultiplier
        ac.log(RaceStartVolumeMultiplier)
    elseif Sim.isPaused then
        TargetVolumeMultiplier = MinimumPauseVolume
    else
        TargetVolumeMultiplier = 1

        local SpeedVolumeMultiplier = 1
        local ProximityVolumeMultiplier = 1
        local CautionVolumeMultiplier = 1
        local CrashingVolumeMultiplier = 1

        if EnableDynamicSpeedVolume then
            local x = math.min(math.max(0, PlayerCarSpeed/(math.ceil(AverageSpeed+TopSpeed)/2)), 1)
            SpeedVolumeMultiplier = scalePercentage(x, MinimumSpeedVolume)
            --ac.log("SpeedVolumeMultiplier", SpeedVolumeMultiplier)
        else
            SpeedVolumeMultiplier = 1
        end

        if EnableDynamicProximityVolume then
            local x = math.max(math.min(lowestDist/(AverageSpeed*0.2), 1), 0)
            --ac.log("proxydistance", scalePercentage(x, MinimumProximityVolume), lowestDist/(AverageSpeed*0.2))
            ProximityVolumeMultiplier = scalePercentage(x, MinimumProximityVolume)
        else
            ProximityVolumeMultiplier = 1
        end

        if EnableDynamicCrashingVolume and HitValue > 0.01 then
            if PlayerCarSpeed < 5 and EnableDynamicCrashingTrackSkip then
                TrackSwitched = true
            end
            CrashingVolumeMultiplier = CrashingVolumeMultiplier - HitValue
        end

        if EnableDynamicCautionVolume and (Sim.raceFlagType == 2 or Sim.raceFlagType == 8 or Sim.raceFlagType == 12) and CautionVolume > MinimumCautionVolume then
            CautionVolumeMultiplier = math.max(CautionVolume - (MinimumCautionVolume*0.2), MinimumCautionVolume)
            CautionVolume = math.max(CautionVolume - (MinimumCautionVolume*0.1), MinimumCautionVolume)
        elseif EnableDynamicCautionVolume and CautionVolume < 1 then
            CautionVolumeMultiplier = math.min(CautionVolume + (MinimumCautionVolume*0.4), 1)
            CautionVolume = math.min(CautionVolume + (MinimumCautionVolume*0.2), 1)
        end
        --ac.log(CautionVolumeMultiplier)
        TargetVolumeMultiplier = TargetVolumeMultiplier * SpeedVolumeMultiplier * ProximityVolumeMultiplier * CrashingVolumeMultiplier * CautionVolumeMultiplier * RaceStartVolumeMultiplier
    end

    TimeIntensity = math.min(1, (-((Sim.sessionTimeLeft/1000/60)/(Session.durationMinutes)))+1)
    LapIntensity = (Car.sessionLapCount+1)/Session.laps
    
    if (not Session.isTimedRace) and Session.type == 3 then

        if LapIntensity > 0.97 then -- boost the volume a little near the end of the race
            TargetVolumeMultiplier = math.min(TargetVolumeMultiplier + TargetVolumeMultiplier*0.20, 1)
        elseif LapIntensity > 0.95 then
            TargetVolumeMultiplier = math.min(TargetVolumeMultiplier + TargetVolumeMultiplier*0.15, 1)
        elseif LapIntensity > 0.93 then
            TargetVolumeMultiplier = math.min(TargetVolumeMultiplier + TargetVolumeMultiplier*0.10, 1)
        elseif LapIntensity > 0.91 then
            TargetVolumeMultiplier = math.min(TargetVolumeMultiplier + TargetVolumeMultiplier*0.05, 1)
        end

        if LapIntensity < 0.03 then -- boost the volume a little at the start of the race
            TargetVolumeMultiplier = math.min(TargetVolumeMultiplier + TargetVolumeMultiplier*0.20, 1)
        elseif LapIntensity < 0.05 then
            TargetVolumeMultiplier = math.min(TargetVolumeMultiplier + TargetVolumeMultiplier*0.15, 1)
        elseif LapIntensity < 0.07 then
            TargetVolumeMultiplier = math.min(TargetVolumeMultiplier + TargetVolumeMultiplier*0.10, 1)
        elseif LapIntensity < 0.09 then
            TargetVolumeMultiplier = math.min(TargetVolumeMultiplier + TargetVolumeMultiplier*0.05, 1)
        end

    elseif Session.type == 3 then

        if TimeIntensity > 0.97 then -- boost the volume a little near the end of the race
            TargetVolumeMultiplier = math.min(TargetVolumeMultiplier + TargetVolumeMultiplier*0.20, 1)
        elseif TimeIntensity > 0.95 then
            TargetVolumeMultiplier = math.min(TargetVolumeMultiplier + TargetVolumeMultiplier*0.15, 1)
        elseif TimeIntensity > 0.93 then
            TargetVolumeMultiplier = math.min(TargetVolumeMultiplier + TargetVolumeMultiplier*0.10, 1)
        elseif TimeIntensity > 0.91 then
            TargetVolumeMultiplier = math.min(TargetVolumeMultiplier + TargetVolumeMultiplier*0.05, 1)
        end

        if TimeIntensity < 0.03 then -- boost the volume a little at the start of the race
            TargetVolumeMultiplier = math.min(TargetVolumeMultiplier + TargetVolumeMultiplier*0.20, 1)
        elseif TimeIntensity < 0.05 then
            TargetVolumeMultiplier = math.min(TargetVolumeMultiplier + TargetVolumeMultiplier*0.15, 1)
        elseif TimeIntensity < 0.07 then
            TargetVolumeMultiplier = math.min(TargetVolumeMultiplier + TargetVolumeMultiplier*0.10, 1)
        elseif TimeIntensity < 0.09 then
            TargetVolumeMultiplier = math.min(TargetVolumeMultiplier + TargetVolumeMultiplier*0.05, 1)
        end
    end
    
    if ((not Sim.isOnlineRace) or CSPBuild >= 2715) and Session.type == 3 then -- Positions are broken in online on CSP 0.2.0 and below, so we only enable this feature on the recent versions
        if PlayerCarRacePosition == 1 then -- boost the volume a little when player is doing well
            TargetVolumeMultiplier = math.min(TargetVolumeMultiplier + TargetVolumeMultiplier*0.20, 1)
        elseif PlayerCarRacePosition <= 3 then
            TargetVolumeMultiplier = math.min(TargetVolumeMultiplier + TargetVolumeMultiplier*0.15, 1)
        elseif PlayerCarRacePosition <= 5 then
            TargetVolumeMultiplier = math.min(TargetVolumeMultiplier + TargetVolumeMultiplier*0.10, 1)
        elseif PlayerCarRacePosition <= 7 then
            TargetVolumeMultiplier = math.min(TargetVolumeMultiplier + TargetVolumeMultiplier*0.05, 1)
        end
    end

    if MusicType and (
    (MusicType  == "replay" and (not Sim.isReplayActive) and EnableReplayPlaylist) or -- We're not in replay but replay music is playing
    (MusicType  ~= "replay" and Sim.isReplayActive and EnableReplayPlaylist) or -- We're in replay but replay music is not playing
    (MusicType  == "idle" and PlayerCarSpeed >= 1 and (not (Car.isInPitlane or Car.isInPit))) or -- Idle Music is playing but we're moving
    (MusicType  ~= "idle" and ((PlayerCarSpeed < 1 and IdleTimer > 10) or Car.isInPitlane or Car.isInPit) and MusicType  ~= "finish" and MusicType  ~= "replay" and EnableIdlePlaylist and IdleMusic[1]) or -- We're Idle but non-idle music is playing, just make sure it's not playing finish music.
    (MusicType  == "practice" and Session.type ~= 1) or -- Practice music is playing but we're not in practice
    (MusicType  == "quali" and Session.type ~= 2) or -- Qualification music is playing but we're not in qualis
    (MusicType  == "race" and Session.type ~= 3) or -- Race music is playing but we're not in race
    (MusicType  ~= "finish" and PlayerFinished and (not PlayedFinishTrack) and FinishMusic[1]) or -- We finished the race
    (EnableMusic == false) or -- We toggled off the music, turn it off
    (SessionSwitched or TrackSwitched) or -- Session has switched so we should play new track
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

    if MusicType and ((MusicType ~= "finish" and PlayerFinished) or TrackSwitched) then
        FadeOutSpeedMultiplier = 10
    elseif SessionSwitched then
        FadeOutSpeedMultiplier = 2/ConfigFadeOutSpeed
    else
        FadeOutSpeedMultiplier = 1
    end

    if not (SessionSwitched or TrackSwitched) and Sim.timeToSessionStart < 0 then
        if Sim.timeToSessionStart > -20000 then
            FadeOutSpeedMultiplier = FadeOutSpeedMultiplier * 0.05
        elseif Sim.timeToSessionStart > -30000 then
            FadeOutSpeedMultiplier = FadeOutSpeedMultiplier * 0.1
        elseif Sim.timeToSessionStart > -40000 then
            FadeOutSpeedMultiplier = FadeOutSpeedMultiplier * 0.2
        elseif Sim.timeToSessionStart > -50000 then
            FadeOutSpeedMultiplier = FadeOutSpeedMultiplier * 0.4
        elseif Sim.timeToSessionStart > -60000 then
            FadeOutSpeedMultiplier = FadeOutSpeedMultiplier * 0.75
        end
    end

end
updateRaceStatusData()

function getNewTrack()
    local PlayedTracksDatabase = ac.INIConfig.load(ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer/" .. "data.ini")

    for attempts = 1,100 do
        local NextTrack1
        local NextTrack2
        local TrackChoosen = false

        if Sim.isReplayActive and EnableReplayPlaylist then

            if ReplayMusic[1] then
                ReplayMusicCounter = ReplayMusicCounter + 1
                if not ReplayMusic[ReplayMusicCounter] then
                    ReplayMusicCounter = 1
                end

                NextTrack1 = ReplayMusic[ReplayMusicCounter]
                NextTrack2 = ReplayMusic[ReplayMusicCounter+1]
            else
                OtherMusicCounter = OtherMusicCounter + 1
                if not OtherMusic[OtherMusicCounter] then
                    OtherMusicCounter = 1
                end
                NextTrack1 = OtherMusic[OtherMusicCounter]
                NextTrack2 = OtherMusic[OtherMusicCounter+1]
            end
            MusicType = "replay"

        elseif PlayerFinished and (not PlayedFinishTrack) and FinishMusic[1] then

            if ((not PodiumFinishTop25Percent) and PlayerCarRacePosition <= 3 and PlayerCarRacePosition ~= CarsInRace) or (PodiumFinishTop25Percent and PlayerCarRacePosition <= CarsInRace*0.25) and FinishPodiumMusic[1] then
                FinishPodiumMusicCounter = FinishPodiumMusicCounter + 1
                if not FinishPodiumMusic[FinishPodiumMusicCounter] then
                    FinishPodiumMusicCounter = 1
                end
                NextTrack1 = FinishPodiumMusic[FinishPodiumMusicCounter]
                NextTrack2 = FinishPodiumMusic[FinishPodiumMusicCounter+1]
            elseif FinishMusic[1] then
                FinishMusicCounter = FinishMusicCounter + 1
                if not FinishMusic[FinishMusicCounter] then
                    FinishMusicCounter = 1
                end
                NextTrack1 = FinishMusic[FinishMusicCounter]
                NextTrack2 = FinishMusic[FinishMusicCounter+1]
            else
                OtherMusicCounter = OtherMusicCounter + 1
                if not OtherMusic[OtherMusicCounter] then
                    OtherMusicCounter = 1
                end
                NextTrack1 = OtherMusic[OtherMusicCounter]
                NextTrack2 = OtherMusic[OtherMusicCounter+1]
            end
            MusicType = "finish"

        elseif ((PlayerCarSpeed < 1 and IdleTimer > 10) or Car.isInPitlane or Car.isInPit) and EnableIdlePlaylist and IdleMusic[1] then

            IdleMusicCounter = IdleMusicCounter + 1
            if not IdleMusic[IdleMusicCounter] then
                IdleMusicCounter = 1
            end
            NextTrack1 = IdleMusic[IdleMusicCounter]
            NextTrack2 = IdleMusic[IdleMusicCounter+1]
            MusicType = "idle"

        elseif (EnablePracticePlaylist and Session.type == 1) then
            if PracticeMusic[1] then
                PracticeMusicCounter = PracticeMusicCounter + 1
                if not PracticeMusic[PracticeMusicCounter] then
                    PracticeMusicCounter = 1
                end
                NextTrack1 = PracticeMusic[PracticeMusicCounter]
                NextTrack2 = PracticeMusic[PracticeMusicCounter+1]
            else
                OtherMusicCounter = OtherMusicCounter + 1
                if not OtherMusic[OtherMusicCounter] then
                    OtherMusicCounter = 1
                end
                NextTrack1 = OtherMusic[OtherMusicCounter]
                NextTrack2 = OtherMusic[OtherMusicCounter+1]
            end
            MusicType = "practice"

        elseif (EnableQualifyingPlaylist and Session.type == 2) then

            if QualificationMusic[1] then
                QualificationMusicCounter = QualificationMusicCounter + 1
                if not QualificationMusic[QualificationMusicCounter] then
                    QualificationMusicCounter = 1
                end
                NextTrack1 = QualificationMusic[QualificationMusicCounter]
                NextTrack2 = QualificationMusic[QualificationMusicCounter+1]
            else
                OtherMusicCounter = OtherMusicCounter + 1
                if not OtherMusic[OtherMusicCounter] then
                    OtherMusicCounter = 1
                end
                NextTrack1 = OtherMusic[OtherMusicCounter]
                NextTrack2 = OtherMusic[OtherMusicCounter+1]
            end
            MusicType = "quali"

        elseif Session.type == 3 then

            if RaceMusic[1] then
                RaceMusicCounter = RaceMusicCounter + 1
                if not RaceMusic[RaceMusicCounter] then
                    RaceMusicCounter = 1
                end
                NextTrack1 = RaceMusic[RaceMusicCounter]
                NextTrack2 = RaceMusic[RaceMusicCounter+1]
            else
                OtherMusicCounter = OtherMusicCounter + 1
                if not OtherMusic[OtherMusicCounter] then
                    OtherMusicCounter = 1
                end
                NextTrack1 = OtherMusic[OtherMusicCounter]
                NextTrack2 = OtherMusic[OtherMusicCounter+1]
            end
            MusicType = "race"

        else

            OtherMusicCounter = OtherMusicCounter + 1
            if not OtherMusic[OtherMusicCounter] then
                OtherMusicCounter = 1
            end
            NextTrack1 = OtherMusic[OtherMusicCounter]
            NextTrack2 = OtherMusic[OtherMusicCounter+1]
            MusicType = "other"
            
        end

        if (not NextTrack2) or (NextTrack2 and NextTrack2[1] ~= CurrentlyPlaying and (attempts == 10 or (PlayedTracksDatabase:get("data", NextTrack1[1], 0) <= PlayedTracksDatabase:get("data", NextTrack2[1], 0)))) then
            TrackChoosen = true
            FilePath = NextTrack1[2]
            CurrentlyPlaying = NextTrack1[1]
            PlayedTracksDatabase:set("data", NextTrack1[1], PlayedTracksDatabase:get("data", NextTrack1[1], 0)+1)
            PlayedTracksDatabase:save()
        end

        if TrackChoosen and MusicType == "finish" then
            PlayedFinishTrack = true
        end

        if TrackChoosen then
            --ac.log(FilePath)
            break
        end
    end

    return FilePath
end

UpdateCounter = 0
SkipAttempts = 0
function script.update(dt)

    local gameDt = ac.getGameDeltaT()
    UpdateCounter = UpdateCounter+1

    if EnableDynamicCrashingVolume then
        Car = ac.getCar(Sim.focusedCar)
        PlayerCarSpeed = Car.speedKmh

        if HitValue > 0.001 then
            HitValue = HitValue - (PlayerCarSpeed*0.000001) - 0.0005
        elseif HitValue <= 0.001 then
            HitValue = 0
        end

        if Car.collisionDepth > 0 and gameDt > 0 then
            local nHit = math.saturateN((HitSpeedLast - PlayerCarSpeed) / 40)
            if nHit > HitValue and nHit > 0.01 then
                HitValue = nHit
            end
        end
        HitSpeedLast = math.applyLag(HitSpeedLast, PlayerCarSpeed, 0.8, gameDt)
    end

    if UpdateCounter%60 == 0 then -- Script Updates
        updateConfig()
        updateRaceStatusData()
    end

    if (StartMusic == true and Sim.timeToSessionStart < 0) or 
    UpdateCounter%60 == 1 and
    EnableMusic and
    ConfigMaxVolume > 0 and
    HitValue == 0 and
    (not CurrentTrack or CurrentTrack:currentTime() >= CurrentTrack:duration() - 1) and 
    (Session.type ~= 3 or (Session.type == 3 and (Sim.timeToSessionStart < 0 or Sim.timeToSessionStart >= 60000))) then -- Prepare playing new track
        updateRaceStatusData()
        CurrentTrack = ui.MediaPlayer(getNewTrack())
        TargetVolume = MaxVolume
        if StartMusic then
            CurrentVolume = TargetVolume*TargetVolumeMultiplier
            StartMusic = false
        else
            CurrentVolume = 0
        end
        CurrentVolume = math.max(0, CurrentVolume)
        CurrentTrack:setVolume(CurrentVolume)
        CurrentTrack:play()
        if SessionSwitched then -- Session has switched and we just started new track for it
            SessionSwitched = false
        end
        if TrackSwitched then
            TrackSwitched = false
        end
        SkipAttempts = 0
    end

    if UpdateCounter%5 == 1 and (Session.type ~= 3 or (Session.type == 3 and (Sim.timeToSessionStart < -10000 or Sim.timeToSessionStart > 0))) then
        if CurrentTrack then
            CurrentVolume = CurrentTrack:volume()
        end
        if CurrentTrack and CurrentVolume >= (TargetVolume*TargetVolumeMultiplier) then
            if ConfigFadeOutSpeed < 3 then
                CurrentVolume = math.max(CurrentVolume - (FadeOutSpeed*FadeOutSpeedMultiplier), (TargetVolume*TargetVolumeMultiplier))
            else
                CurrentVolume = (TargetVolume*TargetVolumeMultiplier)
            end
            CurrentVolume = math.max(0, CurrentVolume)
            CurrentTrack:setVolume(CurrentVolume)
            --ac.log("we're fading out!", CurrentVolume)
            if CurrentVolume <= 0 and TargetVolume < 0 then
                --ac.log("we're trying to skip the song!", CurrentVolume)
                CurrentTrack:setVolume(0)
                CurrentTrack:setCurrentTime(CurrentTrack:duration())
                CurrentVolume = 0

                SkipAttempts = SkipAttempts + 1
                --ac.log("SkipAttempts", SkipAttempts)
                if EnableMusic and SkipAttempts > 20 and (Session.type ~= 3 or (Session.type == 3 and (Sim.timeToSessionStart < 0 or Sim.timeToSessionStart >= 60000))) then
                    updateRaceStatusData()
                    CurrentTrack = ui.MediaPlayer(getNewTrack())
                    TargetVolume = MaxVolume
                    if StartMusic then
                        CurrentVolume = TargetVolume*TargetVolumeMultiplier
                        StartMusic = false
                    else
                        CurrentVolume = 0
                    end
                    CurrentVolume = math.max(0, CurrentVolume)
                    CurrentTrack:setVolume(CurrentVolume)
                    CurrentTrack:play()
                    if SessionSwitched then -- Session has switched and we just started new track for it
                        SessionSwitched = false
                    end
                    if TrackSwitched then
                        TrackSwitched = false
                    end
                    SkipAttempts = 0
                end
            end
        elseif CurrentTrack and CurrentVolume <= (TargetVolume*TargetVolumeMultiplier) then
            if ConfigFadeInSpeed < 3 then
                CurrentVolume = math.min(CurrentVolume + (FadeInSpeed*FadeInSpeedMultiplier), (TargetVolume*TargetVolumeMultiplier))
            else
                CurrentVolume = (TargetVolume*TargetVolumeMultiplier)
            end
            --ac.log("we're fading in!", CurrentVolume)
            CurrentVolume = math.max(0, CurrentVolume)
            CurrentTrack:setVolume(CurrentVolume)
        end
    end

    --if HitValue > 0 and PlayerCarSpeed < 30 then
    --    CurrentVolume = math.max(0, CurrentVolume)
    --    CurrentTrack:setVolume(CurrentVolume)
    --end

    --runGC()
    --printGC()
end

function TabsFunction()
    --ui.tabItem("Volume", {}, VolumeTab)
    ui.tabItem("Sessions", {}, SessionsTab)
    ui.tabItem("Behaviour", {}, BehaviourTab)
    ui.tabItem("NowPlaying Widget", {}, NowPlayingWidgetTab)
    ui.tabItem("Keybinds", {}, KeybindsTab)
    ui.tabItem("Debug", {}, DebugTab)
    
end

-- function VolumeTab()

-- end

function SessionsTab()
    if PracticeMusic[1] then
        checkbox = ui.checkbox("Enable Practice Playlist (If disabled, using Other music during practice)", EnablePracticePlaylist)
        if checkbox then
            EnablePracticePlaylist = not EnablePracticePlaylist
            ConfigFile:set("settings", "practiceenabled", EnablePracticePlaylist)
            NeedToSaveConfig = true
        end
    end

    if QualificationMusic[1] then
        checkbox = ui.checkbox("Enable Qualifying Playlist (If disabled, using Other music during qualifiers)", EnableQualifyingPlaylist)
        if checkbox then
            EnableQualifyingPlaylist = not EnableQualifyingPlaylist
            ConfigFile:set("settings", "qualifyingenabled", EnableQualifyingPlaylist)
            NeedToSaveConfig = true
        end
    end

    if IdleMusic[1] then
        checkbox = ui.checkbox("Enable Idle mode playlist", EnableIdlePlaylist)
        if checkbox then
            EnableIdlePlaylist = not EnableIdlePlaylist
            ConfigFile:set("settings", "idleenabled", EnableIdlePlaylist)
            NeedToSaveConfig = true
        end

        if EnableIdlePlaylist then
            checkbox = ui.checkbox("Enable Idle mode playlist outside of pits", EnableIdlePlaylistOutsidePits)
            if checkbox then
                EnableIdlePlaylistOutsidePits = not EnableIdlePlaylistOutsidePits
                ConfigFile:set("settings", "idleoutsidepits", EnableIdlePlaylistOutsidePits)
                NeedToSaveConfig = true
            end
        end
    end

    if ReplayMusic[1] then
        checkbox = ui.checkbox("Enable Replay mode playlist", EnableReplayPlaylist)
        if checkbox then
            EnableReplayPlaylist = not EnableReplayPlaylist
            ConfigFile:set("settings", "replayenabled", EnableReplayPlaylist)
            NeedToSaveConfig = true
        end
    end

    if FinishMusic[1] then
        checkbox = ui.checkbox("Enable Finish playlists", EnableFinishPlaylist)
        if checkbox then
            EnableFinishPlaylist = not EnableFinishPlaylist
            ConfigFile:set("settings", "finishenabled", EnableFinishPlaylist)
            NeedToSaveConfig = true
        end
    end

end

function BehaviourTab()

    ui.text('Fade-In Speed Multiplier')

    local sliderValue4 = ConfigFile:get("settings", "fadein", 1)
    sliderValue4 = ui.slider("(Default 1) ##slider4", sliderValue4, 0.25, 3)
    if ConfigFadeInSpeed ~= sliderValue4 then
        ConfigFadeInSpeed = sliderValue4
        ConfigFile:set("settings", "fadein", sliderValue4)
        NeedToSaveConfig = true
    end
    if ui.itemHovered() then
        ui.setTooltip('Higher is faster. Completely disables fade-ins when maxed.')
    end

    ui.separator()
    ui.text('Fade-Out Speed Multiplier')
    
    local sliderValue5 = ConfigFile:get("settings", "fadeout", 1)
    sliderValue5 = ui.slider("(Default 1) ##slider5", sliderValue5, 0.25, 3)
    if ConfigFadeOutSpeed ~= sliderValue5 then
        ConfigFadeOutSpeed = sliderValue5
        ConfigFile:set("settings", "fadeout", sliderValue5)
        NeedToSaveConfig = true
    end
    if ui.itemHovered() then
        ui.setTooltip('Higher is faster. Completely disables fade-outs when maxed.')
    end

    if true then
        ui.separator()
        ui.text('Pause Music Volume')
        local sliderValue3d = ConfigMinimumPauseVolume
        sliderValue3d = ui.slider("(Default 0.1) ##slider3d", sliderValue3d, 0, 1)
        if ConfigMinimumPauseVolume ~= sliderValue3d then
            ConfigMinimumPauseVolume = sliderValue3d
            ConfigFile:set("settings", "minpausevolume", sliderValue3d)
            NeedToSaveConfig = true
        end
        if ui.itemHovered() then
            ui.setTooltip('The app is adjusting current volume based on a few events. This value defines how low the volume can drop relative to Max when the game is paused.')
        end
        ui.separator()
    end

    checkbox = ui.checkbox("Enable Caution Flag Volume Fadeout", EnableDynamicCautionVolume)
    if ui.itemHovered() then
        ui.setTooltip('Volume will drop down when you are under yellow or blue flag. It will also drop when you get a slowdown penalty. It is intended to make you focused during cautious situations.')
    end
    if checkbox then
        EnableDynamicCautionVolume = not EnableDynamicCautionVolume
        ConfigFile:set("settings", "cautionfadeout", EnableDynamicCautionVolume)
        NeedToSaveConfig = true
    end

    if EnableDynamicCautionVolume then
        
        ui.text('Caution Flag Music Volume Multiplier')
        local sliderValue3a = ConfigMinimumCautionVolume
        sliderValue3a = ui.slider("(Default 0.1) ##slider3a", sliderValue3a, 0, 1)
        if ConfigMinimumCautionVolume ~= sliderValue3a then
            ConfigMinimumCautionVolume = sliderValue3a
            ConfigFile:set("settings", "mincautionvolume", sliderValue3a)
            NeedToSaveConfig = true
        end
        if ui.itemHovered() then
            ui.setTooltip('The app is adjusting current volume based on a few events. This value defines how low the volume can drop relative to Max during caution flags.')
        end
        ui.separator()
    end

    checkbox = ui.checkbox("Enable Opponent Proximity Volume Fadeout", EnableDynamicProximityVolume)
    if ui.itemHovered() then
        ui.setTooltip('Volume will drop down when you have other cars around you. Proximity check range also increases with speed.')
    end
    if checkbox then
        EnableDynamicProximityVolume = not EnableDynamicProximityVolume
        ConfigFile:set("settings", "proximityfadeout", EnableDynamicProximityVolume)
        NeedToSaveConfig = true
    end

    if EnableDynamicProximityVolume then
        ui.text('Opponent Proximity Music Volume Multiplier')
        local sliderValue3b = ConfigMinimumProximityVolume
        sliderValue3b = ui.slider("(Default 0.5) ##slider3b", sliderValue3b, 0, 1)
        if ConfigMinimumProximityVolume ~= sliderValue3b then
            ConfigMinimumProximityVolume = sliderValue3b
            ConfigFile:set("settings", "minproximityvolume", sliderValue3b)
            NeedToSaveConfig = true
        end
        if ui.itemHovered() then
            ui.setTooltip('The app is adjusting current volume based on a few events. This value defines how low the volume can drop relative to Max when oppoents are nearby.')
        end
        ui.separator()
    end

    checkbox = ui.checkbox("Enable Low Speed Volume Fadeout", EnableDynamicSpeedVolume)
    if ui.itemHovered() then
        ui.setTooltip('Volume will drop down when you drive slow. The app calibrates itself to your car and track combo after a few laps. Starting value is to use average speed of 200.')
    end
    if checkbox then
        EnableDynamicSpeedVolume = not EnableDynamicSpeedVolume
        ConfigFile:set("settings", "speedfadeout", EnableDynamicSpeedVolume)
        NeedToSaveConfig = true
    end

    if EnableDynamicSpeedVolume then
        
        ui.text('Low Speed Music Volume Multiplier')
        local sliderValue3c = ConfigMinimumSpeedVolume
        sliderValue3c = ui.slider("(Default 0.5) ##slider3c", sliderValue3c, 0, 1)
        if ConfigMinimumSpeedVolume ~= sliderValue3c then
            ConfigMinimumSpeedVolume = sliderValue3c
            ConfigFile:set("settings", "minspeedvolume", sliderValue3c)
            NeedToSaveConfig = true
        end
        if ui.itemHovered() then
            ui.setTooltip('The app is adjusting current volume based on a few events. This value defines how low the volume can drop relative to Max when you are driving slow.')
        end
        ui.separator()
    end

    checkbox = ui.checkbox("Enable Crashing Volume Fadeout", EnableDynamicCrashingVolume)
    if ui.itemHovered() then
        ui.setTooltip('Music will fade away when you crash.')
    end
    if checkbox then
        EnableDynamicCrashingVolume = not EnableDynamicCrashingVolume
        ConfigFile:set("settings", "crashingfadeout", EnableDynamicCrashingVolume)
        NeedToSaveConfig = true
    end

    if EnableDynamicCrashingVolume then
        checkbox = ui.checkbox("Enable Music Track Skip When Crashing Out", EnableDynamicCrashingTrackSkip)
        if ui.itemHovered() then
            ui.setTooltip('When you crash into full stop, current track will be stopped and the new one will start once the crashing effect fades away.')
        end
        if checkbox then
            EnableDynamicCrashingTrackSkip = not EnableDynamicCrashingTrackSkip
            ConfigFile:set("settings", "crashingfadeouttrackskip", EnableDynamicCrashingTrackSkip)
            NeedToSaveConfig = true
        end
    end

    ui.separator()
    if FinishPodiumMusic[1] then
        checkbox = ui.checkbox("Play Victory Music if finished in Top25%, otherwise play only if finished in Top3", PodiumFinishTop25Percent)
        if checkbox then
            PodiumFinishTop25Percent = not PodiumFinishTop25Percent
            ConfigFile:set("settings", "podiumtop25", PodiumFinishTop25Percent)
            NeedToSaveConfig = true
        end
    end

end

function NowPlayingWidgetTab()

    ui.text('Widget size')
    local sliderValue6 = ConfigFile:get("settings", "nowplayingscale", 1)
    sliderValue6 = ui.slider("(Default 1) ##slider6", sliderValue6, 0.5, 2)
    if NowPlayingWidgetSize ~= sliderValue6 then
        NowPlayingWidgetSize = sliderValue6
        ConfigFile:set("settings", "nowplayingscale", sliderValue6)
        NeedToSaveConfig = true
    end

    checkbox = ui.checkbox("Enable Icon", EnableNowPlayingIcon)
    if checkbox then
        EnableNowPlayingIcon = not EnableNowPlayingIcon
        ConfigFile:set("settings", "nowplayingicon", EnableNowPlayingIcon)
        NeedToSaveConfig = true
    end
    
    if EnableNowPlayingIcon then
        checkbox = ui.checkbox("Enable Animated Icon", EnableAnimatedNowPlayingIcon)
        if checkbox then
            EnableAnimatedNowPlayingIcon = not EnableAnimatedNowPlayingIcon
            ConfigFile:set("settings", "nowplayinganimatedicon", EnableAnimatedNowPlayingIcon)
            NeedToSaveConfig = true
        end
    end

    checkbox = ui.checkbox("Enable Timer", EnableNowPlayingTime)
    if checkbox then
        EnableNowPlayingTime = not EnableNowPlayingTime
        ConfigFile:set("settings", "nowplayingtime", EnableNowPlayingTime)
        NeedToSaveConfig = true
    end

    checkbox = ui.checkbox("Show the widget only when new track starts", EnableNowPlayingWidgetFadeout)
    if checkbox then
        EnableNowPlayingWidgetFadeout = not EnableNowPlayingWidgetFadeout
        ConfigFile:set("settings", "nowplayingfadeout", EnableNowPlayingWidgetFadeout)
        NeedToSaveConfig = true
    end

    if EnableNowPlayingWidgetFadeout then
        ui.text('Show the widget for first ' .. math.ceil(NowPlayingWidgetFadeoutTime) .. ' seconds of new track')
        local sliderValue7 = ConfigFile:get("settings", "nowplayingfadeouttime", 10)
        sliderValue7 = ui.slider("Seconds (Default 10) ##slider7", sliderValue7, 5, 30, "%.1f")
        if NowPlayingWidgetFadeoutTime ~= sliderValue7 then
            NowPlayingWidgetFadeoutTime = sliderValue7
            ConfigFile:set("settings", "nowplayingfadeouttime", sliderValue7)
            NeedToSaveConfig = true
        end
    end
end

function KeybindsTab()
    ui.text("On/Off")
    OnOffToggleButton:control()
    ui.text("Increase Volume By 5%")
    IncreaseVolumeButton:control()
    ui.text("Decrease Volume By 5%")
    DecreaseVolumeButton:control()
    ui.text("Skip Track")
    SkipTrackButton:control()
end

function DebugTab()
    ui.text("CurrentlyPlaying: " .. CurrentlyPlaying)
    ui.text("Playlist: " .. MusicType)
    ui.text("Top Speed: " .. TopSpeed)
    ui.text("Average Speed: " .. AverageSpeed)
    ui.text("Crash Value: " .. HitValue)
    ui.text("MaxVolume: " .. MaxVolume)
    ui.text("Volume Modifier: " .. TargetVolumeMultiplier)
    ui.text("Target Volume: " .. (TargetVolume*TargetVolumeMultiplier))
    ui.text("Current Volume: " .. CurrentVolume)
end

function script.windowMain()

    NeedToSaveConfig = false
    local checkbox

    checkbox = ui.checkbox("Enable Music", EnableMusic)
    if checkbox then
        EnableMusic = not EnableMusic
        ConfigFile:set("settings", "appenabled", EnableMusic)
        NeedToSaveConfig = true
    end
    local sliderValue1 = ConfigMaxVolume
    sliderValue1 = ui.slider("Volume (Default 0.833) ##slider1", sliderValue1, 0, 1)
    if ConfigMaxVolume ~= sliderValue1 then
        ConfigMaxVolume = sliderValue1
        ConfigFile:set("settings", "volume", sliderValue1)
        NeedToSaveConfig = true
    end

    ui.tabBar("Categories", {}, TabsFunction)

    if NeedToSaveConfig then
        ConfigFile:save()
    end
end

ac.setWindowSizeConstraints('main', vec2(550,100), vec2(550,1000))
local nowplayingicon = ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer/" .. "iconFlipped.png"
local nowplayingbar = ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer/" .. "nowplayingbar.png"
-- Now Playing
function script.windowNowPlaying()
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
            ui.drawImage(nowplayingicon, vec2(10+10*NowPlayingWidgetSize,10+10*NowPlayingWidgetSize), vec2(10+70*NowPlayingWidgetSize,15+65*NowPlayingWidgetSize), rgbm(1, 1, 1, NowPlayingOpacityCurrent), vec2(1,1), vec2(0,0), ui.ImageFit.Fit)
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
    elseif EnableNowPlayingTime then
        text1 = "Now Playing: " .. "(" .. string_formatTime(math.ceil(CurrentTrack:currentTime())) .. "/" .. string_formatTime(math.ceil(CurrentTrack:duration())) .. ") "
    end
    text2 = CurrentlyPlaying
    local windowWidth = math.max(ui.measureDWriteText(text1, 25*NowPlayingWidgetSize, -1).x, ui.measureDWriteText(text2, 25*NowPlayingWidgetSize, -1).x)
    local windowWidth = vec2(windowWidth)
    ui.dwriteText(text1, 18*NowPlayingWidgetSize, rgbm(1, 1, 1, NowPlayingOpacityCurrent))
    ui.dwriteText(text2, 21*NowPlayingWidgetSize, rgbm(1, 1, 1, NowPlayingOpacityCurrent))
    ui.endOutline(0, 1.5)
    ui.popDWriteFont()

    
    ac.setWindowSizeConstraints('nowplaying', vec2(windowWidth.x+windowWidthRange+75*NowPlayingWidgetSize,100*NowPlayingWidgetSize), vec2(windowWidth.x+windowWidthRange+75*NowPlayingWidgetSize,100*NowPlayingWidgetSize))

    if (not EnableNowPlayingWidgetFadeout) or (CurrentTrack:currentTime() < NowPlayingWidgetFadeoutTime and CurrentTrack:currentTime() > 0.5) then
        NowPlayingOpacityTarget = 1
    else
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



-- Keybindings

function OnOffToggleFunction()
    EnableMusic = not EnableMusic
    ConfigFile:set("settings", "appenabled", EnableMusic)
    ConfigFile:save()
end

function IncreaseVolumeFunction()
    ConfigMaxVolume = math.min(1, ConfigMaxVolume + 0.05)
    ConfigFile:set("settings", "volume", ConfigMaxVolume)
    ConfigFile:save()
end

function DecreaseVolumeFunction()
    ConfigMaxVolume = math.max(0, ConfigMaxVolume - 0.05)
    ConfigFile:set("settings", "volume", ConfigMaxVolume)
    ConfigFile:save()
end

function SkipTrackFunction()
    TrackSwitched = true
    ConfigFile:save()
end

OnOffToggleButton = ac.ControlButton('app.DynamicMusicPlayer/OnOff Toggle Button')
OnOffToggleButton:onPressed(OnOffToggleFunction)

IncreaseVolumeButton = ac.ControlButton('app.DynamicMusicPlayer/Increase Volume Button')
IncreaseVolumeButton:onPressed(IncreaseVolumeFunction)

DecreaseVolumeButton = ac.ControlButton('app.DynamicMusicPlayer/Decrease Toggle Button')
DecreaseVolumeButton:onPressed(DecreaseVolumeFunction)

SkipTrackButton = ac.ControlButton('app.DynamicMusicPlayer/Skip Track Button')
SkipTrackButton:onPressed(SkipTrackFunction)