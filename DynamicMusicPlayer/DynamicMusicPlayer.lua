---@ext
CSPBuild = ac.getPatchVersionCode()
math.randomseed(os.preciseClock())

CoverArtExportCanvas = ui.ExtraCanvas(vec2(256, 256), 1, render.AntialiasingMode.ExtraSharpCMAA)
function RenderCoverArtExportCanvas()
    CoverArtExportCanvas:clear()
    if nowplayingiconcoverart and nowplayingiconcoverart ~= ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer/" .. "icon.png" then
        ui.drawImage(nowplayingiconcoverart, vec2(0, 0), vec2(256, 256), rgb(1,1,1))
    else
        ui.drawImage(ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer/OBS Stuff/BlankCoverArt.png", vec2(0, 0), vec2(256, 256), rgb(1,1,1))
    end
end

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

function table_copy(tbl)
	local copy = {}
	for key, value in pairs(tbl) do
		copy[key] = value
	end
	return copy
end

function getInitialBase64Symbols(string, length)
    if not length then length = 64 end
    local cutString = ""
    cutString = ac.encodeBase64(string, true)
    cutString = string.sub(cutString, 1, length)
    return cutString
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
TracksMemory = {}

--for trackTitle, lastPlayedTime in pairs(TracksMemory) do
--    --local base64code = getInitialBase64Symbols(trackTitle, 10)
--    local trackMemoryFile = ac.INIConfig.load(ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer/TracksPlayedMemory/" .. trackTitle ..".ini", ac.INIFormat.Extended)
--    local trackMemoryTable = trackMemoryFile:get("lastplayedtimes", "time", 0)
--    trackMemoryFile:set("lastplayedtimes", "time", lastPlayedTime)
--    trackMemoryFile:save()
--end

io.createDir(__dirname .. '/TracksPlayedMemory')
local TracksMemoryFolder = table.map(io.scanDir( __dirname .. '/TracksPlayedMemory', '*'), function (x) return { string.sub(x, 1, #x - 4), '/TracksPlayedMemory' .. '/' .. x } end)
for i = 1,#TracksMemoryFolder do
    local trackTitle = TracksMemoryFolder[i][1]
    TracksMemory[trackTitle] = ac.INIConfig.load(ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer/TracksPlayedMemory/" .. trackTitle .. ".ini", ac.INIFormat.Extended):get("lastplayedtimes", "time", 0)
end



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
EnableAnimatedNowPlayingIcon = ConfigFile:get("settings", "nowplayinganimatedicon", false)
EnableNowPlayingTime = ConfigFile:get("settings", "nowplayingtime", true)
NowPlayingWidgetSize = ConfigFile:get("settings", "nowplayingscale", 1)
EnableNowPlayingWidgetFadeout = ConfigFile:get("settings", "nowplayingfadeout", true)
NowPlayingWidgetFadeoutTime = ConfigFile:get("settings", "nowplayingfadeouttime", 10)

MusicListHideWithCoverArt = ConfigFile:get("settings", "musiclisthidewithcoverart", false)


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
OtherMusicSorted = table_copy(OtherMusic)
table.sort(OtherMusicSorted, function(a,b) return string.upper(a[1]) < string.upper(b[1]) end)

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
RaceMusicSorted = table_copy(RaceMusic)
table.sort(RaceMusicSorted, function(a,b) return string.upper(a[1]) < string.upper(b[1]) end)

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
FinishMusicSorted = table_copy(FinishMusic)
table.sort(FinishMusicSorted, function(a,b) return string.upper(a[1]) < string.upper(b[1]) end)

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
FinishPodiumMusicSorted = table_copy(FinishPodiumMusic)
table.sort(FinishPodiumMusicSorted, function(a,b) return string.upper(a[1]) < string.upper(b[1]) end)

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
ReplayMusicSorted = table_copy(ReplayMusic)
table.sort(ReplayMusicSorted, function(a,b) return string.upper(a[1]) < string.upper(b[1]) end)

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
PracticeMusicSorted = table_copy(PracticeMusic)
table.sort(PracticeMusicSorted, function(a,b) return string.upper(a[1]) < string.upper(b[1]) end)

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
QualificationMusicSorted = table_copy(QualificationMusic)
table.sort(QualificationMusicSorted, function(a,b) return string.upper(a[1]) < string.upper(b[1]) end)

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
IdleMusicSorted = table_copy(IdleMusic)
table.sort(IdleMusicSorted, function(a,b) return string.upper(a[1]) < string.upper(b[1]) end)

CoverArtDir = '/Music/CoverArts'
CoverArts = table.map(io.scanDir( __dirname .. CoverArtDir, '*'), function (x) return { string.sub(x, 1, #x - 4), CoverArtDir .. '/' .. x } end)
CoverArtConfig = require('Music/CoverArtConfig')


TargetVolume = -10
TargetVolumeMultiplier = 1
CurrentVolume = 0
IdleTimer = 10
HitValue = 0
HitSpeedLast = 0
FadeInSpeedMultiplier = 1
FadeOutSpeedMultiplier = 1

StartMusic = false
MusicQueue = {}
CoverArtCache = {}

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

    if ((Car.isInPitlane or Car.isInPit or Sim.isInMainMenu) or (Sim.timeToSessionStart > 0)) and EnableIdlePlaylist then
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
    if Session.type == 3 and Sim.timeToSessionStart > 0 and Sim.timeToSessionStart < 60000 and (not Sim.isReplayActive) then
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
    local lowestDist = 9999999
    for i = 1,9999 do
        if ac.getCar(i) and i ~= 0 then
            local distance = math.distance(ac.getCar(0).position, ac.getCar(i).position)
            if distance < lowestDist and (not ac.getCar(i).isInPit) and (not ac.getCar(i).isInPitlane) and ac.getCar(i).isConnected then
                lowestDist = distance
            end
        elseif not ac.getCar(i) then
            break
        end
    end

    if Sim.isReplayActive then
        TargetVolumeMultiplier = 1
    elseif PlayerFinished or MusicType == "idle" then
        TargetVolumeMultiplier = 1*RaceStartVolumeMultiplier
        --ac.log(RaceStartVolumeMultiplier)
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
            CautionVolumeMultiplier = math.max(CautionVolume - (MinimumCautionVolume*0.5), MinimumCautionVolume)
            CautionVolume = math.max(CautionVolume - (MinimumCautionVolume*0.25), MinimumCautionVolume)
        elseif EnableDynamicCautionVolume and CautionVolume < 1 then
            CautionVolumeMultiplier = math.min(CautionVolume + (MinimumCautionVolume*0.2), 1)
            CautionVolume = math.min(CautionVolume + (MinimumCautionVolume*0.1), 1)
        end
        --ac.log(CautionVolumeMultiplier)
        TargetVolumeMultiplier = TargetVolumeMultiplier * SpeedVolumeMultiplier * ProximityVolumeMultiplier * CrashingVolumeMultiplier * CautionVolumeMultiplier * RaceStartVolumeMultiplier
    end

    TimeIntensity = math.min(1, (-((Sim.sessionTimeLeft/1000/60)/(Session.durationMinutes)))+1)
    LapIntensity = (Car.sessionLapCount+1)/Session.laps
    PositionIntensity = (-((PlayerCarRacePosition - 1)/(CarsInRace - 1)))+1
    if Sim.timeToSessionStart > -10 then
        TimeIntensity = 0
        LapIntensity = 0
    end

    if MusicType and ((not DontSkipCurrentTrack) or TrackSwitched or (PlayerFinished and (not PlayedFinishTrack) and FinishMusic[1])) and (
    (MusicType  == "replay" and (not Sim.isReplayActive) and EnableReplayPlaylist) or -- We're not in replay but replay music is playing
    (MusicType  ~= "replay" and Sim.isReplayActive and EnableReplayPlaylist) or -- We're in replay but replay music is not playing
    (MusicType  == "idle" and PlayerCarSpeed >= 1 and (not (Car.isInPitlane or Car.isInPit or Sim.isInMainMenu))) or -- Idle Music is playing but we're moving
    (MusicType  ~= "idle" and ((PlayerCarSpeed < 1 and IdleTimer > 10) or Car.isInPitlane or Car.isInPit or Sim.isInMainMenu) and MusicType  ~= "finish" and MusicType  ~= "replay" and EnableIdlePlaylist and IdleMusic[1]) or -- We're Idle but non-idle music is playing, just make sure it's not playing finish music.
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

    if not (SessionSwitched or TrackSwitched) and Sim.timeToSessionStart < 0 and (not Sim.isReplayActive) then
        if Sim.timeToSessionStart > -40000 then
            FadeOutSpeedMultiplier = FadeOutSpeedMultiplier * 0
            TargetVolumeMultiplier = 1
        elseif Sim.timeToSessionStart > -60000 then
            FadeOutSpeedMultiplier = FadeOutSpeedMultiplier * 0.05
            TargetVolumeMultiplier = math.max(TargetVolumeMultiplier, 0.9)
        elseif Sim.timeToSessionStart > -80000 then
            FadeOutSpeedMultiplier = FadeOutSpeedMultiplier * 0.1
            TargetVolumeMultiplier = math.max(TargetVolumeMultiplier, 0.8)
        elseif Sim.timeToSessionStart > -100000 then
            FadeOutSpeedMultiplier = FadeOutSpeedMultiplier * 0.2
            TargetVolumeMultiplier = math.max(TargetVolumeMultiplier, 0.7)
        elseif Sim.timeToSessionStart > -120000 then
            FadeOutSpeedMultiplier = FadeOutSpeedMultiplier * 0.4
            TargetVolumeMultiplier = math.max(TargetVolumeMultiplier, 0.6)
        elseif Sim.timeToSessionStart > -120000 then
            FadeOutSpeedMultiplier = FadeOutSpeedMultiplier * 0.6
            TargetVolumeMultiplier = math.max(TargetVolumeMultiplier, 0.5)
        elseif Sim.timeToSessionStart > -140000 then
            FadeOutSpeedMultiplier = FadeOutSpeedMultiplier * 0.8
            TargetVolumeMultiplier = math.max(TargetVolumeMultiplier, 0.4)
        end
    end

    if MusicType and ((MusicType ~= "finish" and PlayerFinished) or TrackSwitched) then
        FadeOutSpeedMultiplier = 10
    else
        FadeOutSpeedMultiplier = 1
    end

    if CurrentTrack then
        local nowplayingOBStext = "Now Playing: " .. "(" .. string_formatTime(math.ceil(CurrentTrack:currentTime())) .. "/" .. string_formatTime(math.ceil(CurrentTrack:duration())) .. ") "
        io.save(ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer/OBS Stuff/nowplayingtime.txt", nowplayingOBStext, false)
    else
        local nowplayingOBStext = ""
        io.save(ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer/OBS Stuff/nowplayingtime.txt", nowplayingOBStext, false)
    end
end
updateRaceStatusData()

local trimmedWords = {
    "#Day",
    "#Night",

    "#Rain",
    "#Dry",

    "#PositionTop10",
    "#PositionTop20",
    "#PositionTop30",
    "#PositionTop40",
    "#PositionTop50",
    "#PositionTop60",
    "#PositionTop70",
    "#PositionTop80",
    "#PositionTop90",

    "#PositionBottom10",
    "#PositionBottom20",
    "#PositionBottom30",
    "#PositionBottom40",
    "#PositionBottom50",
    "#PositionBottom60",
    "#PositionBottom70",
    "#PositionBottom80",
    "#PositionBottom90",

    "#ProgressMin10",
    "#ProgressMin20",
    "#ProgressMin30",
    "#ProgressMin40",
    "#ProgressMin50",
    "#ProgressMin60",
    "#ProgressMin70",
    "#ProgressMin80",
    "#ProgressMin90",

    "#ProgressMax10",
    "#ProgressMax20",
    "#ProgressMax30",
    "#ProgressMax40",
    "#ProgressMax50",
    "#ProgressMax60",
    "#ProgressMax70",
    "#ProgressMax80",
    "#ProgressMax90",

    "#YearMin1900",
    "#YearMin1910",
    "#YearMin1920",
    "#YearMin1930",
    "#YearMin1940",
    "#YearMin1950",
    "#YearMin1960",
    "#YearMin1970",
    "#YearMin1980",
    "#YearMin1990",
    "#YearMin2000",
    "#YearMin2010",
    "#YearMin2020",
    "#YearMin2030",

    "#YearMax1900",
    "#YearMax1910",
    "#YearMax1920",
    "#YearMax1930",
    "#YearMax1940",
    "#YearMax1950",
    "#YearMax1960",
    "#YearMax1970",
    "#YearMax1980",
    "#YearMax1990",
    "#YearMax2000",
    "#YearMax2010",
    "#YearMax2020",
    "#YearMax2030",
}

local function readTrackTags(filename)
    local canPlay = true
    local trimmedFilename = filename
    local ProgressIntensity
    if Session.isTimedRace then
        ProgressIntensity = TimeIntensity
    else
        ProgressIntensity = LapIntensity
    end
    --ac.debug("PositionIntensity", PositionIntensity)
    --ac.debug("ProgressIntensity", ProgressIntensity)
    ------------------------------------------------------------------------------------
    -- Trim the filename:
    ------------------------------------------------------------------------------------
    ---
    for i = 1,#trimmedWords do
        if string.find(trimmedFilename, trimmedWords[i]) then
            trimmedFilename = string.gsub(trimmedFilename, trimmedWords[i], "")
        end
    end

    for i = 1,100 do
        trimmedFilename = string.gsub(trimmedFilename, "  ", " ")
        if string.sub(trimmedFilename, -1, -1) == " " then
            trimmedFilename = string.sub(trimmedFilename, 1, -2)
        end
    end

    --ac.log("trimmedFilename", "'" .. trimmedFilename .. "'")

    ------------------------------------------------------------------------------------
    -- Allow to play:
    ------------------------------------------------------------------------------------

    -- Daytime/Nighttime
    if string.find(filename, "#Day") and string.find(filename, "#Night") then
        
    elseif string.find(filename, "#Day") and ac.getSunAngle() >= 85 then -- night
        canPlay = false
    elseif string.find(filename, "#Night") and ac.getSunAngle() <= 92 then -- day
        canPlay = false
    end



    -- Rain/Dry
    if string.find(filename, "#Rain") and string.find(filename, "#Dry") then
    
    elseif string.find(filename, "#Rain") and Sim.rainIntensity < 0.01 then -- dry
        canPlay = false
    elseif string.find(filename, "#Dry") and Sim.rainIntensity >= 0.01 then -- rainy
        canPlay = false
    end



    -- Position Top
    if string.find(filename, "#PositionTop1") and PositionIntensity < 1 then
        if MusicType == "race" then
            canPlay = false
        end
    elseif string.find(filename, "#PositionTop10") and PositionIntensity < 0.9 or
           string.find(filename, "#PositionTop20") and PositionIntensity < 0.8 or
           string.find(filename, "#PositionTop30") and PositionIntensity < 0.7 or
           string.find(filename, "#PositionTop40") and PositionIntensity < 0.6 or
           string.find(filename, "#PositionTop50") and PositionIntensity < 0.5 or
           string.find(filename, "#PositionTop60") and PositionIntensity < 0.4 or
           string.find(filename, "#PositionTop70") and PositionIntensity < 0.3 or
           string.find(filename, "#PositionTop80") and PositionIntensity < 0.2 or
           string.find(filename, "#PositionTop90") and PositionIntensity < 0.1 then
        if MusicType == "race" then
            canPlay = false
        end
    end
    -- Position Bottom
    if     string.find(filename, "#PositionBottom10") and PositionIntensity > 0.1 or
           string.find(filename, "#PositionBottom20") and PositionIntensity > 0.2 or
           string.find(filename, "#PositionBottom30") and PositionIntensity > 0.3 or
           string.find(filename, "#PositionBottom40") and PositionIntensity > 0.4 or
           string.find(filename, "#PositionBottom50") and PositionIntensity > 0.5 or
           string.find(filename, "#PositionBottom60") and PositionIntensity > 0.6 or
           string.find(filename, "#PositionBottom70") and PositionIntensity > 0.7 or
           string.find(filename, "#PositionBottom80") and PositionIntensity > 0.8 or
           string.find(filename, "#PositionBottom90") and PositionIntensity > 0.9 then
        if MusicType == "race" then
            canPlay = false
        end
    end

    -- Progress Minimum
    if     string.find(filename, "#ProgressMin10") and ProgressIntensity < 0.1 or
           string.find(filename, "#ProgressMin20") and ProgressIntensity < 0.2 or
           string.find(filename, "#ProgressMin30") and ProgressIntensity < 0.3 or
           string.find(filename, "#ProgressMin40") and ProgressIntensity < 0.4 or
           string.find(filename, "#ProgressMin50") and ProgressIntensity < 0.5 or
           string.find(filename, "#ProgressMin60") and ProgressIntensity < 0.6 or
           string.find(filename, "#ProgressMin70") and ProgressIntensity < 0.7 or
           string.find(filename, "#ProgressMin80") and ProgressIntensity < 0.8 or
           string.find(filename, "#ProgressMin90") and ProgressIntensity < 0.9 then
        if MusicType == "race" then
            canPlay = false
        end
    end
    -- Progress Maximum
    if  string.find(filename, "#ProgressMax10") and ProgressIntensity > 0.1 or
        string.find(filename, "#ProgressMax20") and ProgressIntensity > 0.2 or
        string.find(filename, "#ProgressMax30") and ProgressIntensity > 0.3 or
        string.find(filename, "#ProgressMax40") and ProgressIntensity > 0.4 or
        string.find(filename, "#ProgressMax50") and ProgressIntensity > 0.5 or
        string.find(filename, "#ProgressMax60") and ProgressIntensity > 0.6 or
        string.find(filename, "#ProgressMax70") and ProgressIntensity > 0.7 or
        string.find(filename, "#ProgressMax80") and ProgressIntensity > 0.8 or
        string.find(filename, "#ProgressMax90") and ProgressIntensity > 0.9 then
        if MusicType == "race" then
            canPlay = false
        end
    end

    -- Car Production Year Minimum
    local carProductionYear = ac.getCar(ac.getSim().focusedCar).year
    if  string.find(filename, "#YearMin1900") and carProductionYear <= 1900 or
        string.find(filename, "#YearMin1910") and carProductionYear <= 1910 or
        string.find(filename, "#YearMin1920") and carProductionYear <= 1920 or
        string.find(filename, "#YearMin1930") and carProductionYear <= 1930 or
        string.find(filename, "#YearMin1940") and carProductionYear <= 1940 or
        string.find(filename, "#YearMin1950") and carProductionYear <= 1950 or
        string.find(filename, "#YearMin1960") and carProductionYear <= 1960 or
        string.find(filename, "#YearMin1970") and carProductionYear <= 1970 or
        string.find(filename, "#YearMin1980") and carProductionYear <= 1980 or
        string.find(filename, "#YearMin1990") and carProductionYear <= 1990 or
        string.find(filename, "#YearMin2000") and carProductionYear <= 2000 or
        string.find(filename, "#YearMin2010") and carProductionYear <= 2010 or
        string.find(filename, "#YearMin2020") and carProductionYear <= 2020 or
        string.find(filename, "#YearMin2030") and carProductionYear <= 2030 then
            canPlay = false
    end

    if  string.find(filename, "#YearMax1900") and carProductionYear >= 1900 or
        string.find(filename, "#YearMax1910") and carProductionYear >= 1910 or
        string.find(filename, "#YearMax1920") and carProductionYear >= 1920 or
        string.find(filename, "#YearMax1930") and carProductionYear >= 1930 or
        string.find(filename, "#YearMax1940") and carProductionYear >= 1940 or
        string.find(filename, "#YearMax1950") and carProductionYear >= 1950 or
        string.find(filename, "#YearMax1960") and carProductionYear >= 1960 or
        string.find(filename, "#YearMax1970") and carProductionYear >= 1970 or
        string.find(filename, "#YearMax1980") and carProductionYear >= 1980 or
        string.find(filename, "#YearMax1990") and carProductionYear >= 1990 or
        string.find(filename, "#YearMax2000") and carProductionYear >= 2000 or
        string.find(filename, "#YearMax2010") and carProductionYear >= 2010 or
        string.find(filename, "#YearMax2020") and carProductionYear >= 2020 or
        string.find(filename, "#YearMax2030") and carProductionYear >= 2030 then
            canPlay = false
    end

    return trimmedFilename, canPlay
end

for i = 1,#PracticeMusic do
    PracticeMusic[i][3] = readTrackTags(PracticeMusic[i][1])
    PracticeMusicSorted[i][3] = readTrackTags(PracticeMusicSorted[i][1])
end
for i = 1,#QualificationMusic do
    QualificationMusic[i][3] = readTrackTags(QualificationMusic[i][1])
    QualificationMusicSorted[i][3] = readTrackTags(QualificationMusicSorted[i][1])
end
for i = 1,#RaceMusic do
    RaceMusic[i][3] = readTrackTags(RaceMusic[i][1])
    RaceMusicSorted[i][3] = readTrackTags(RaceMusicSorted[i][1])
end
for i = 1,#IdleMusic do
    IdleMusic[i][3] = readTrackTags(IdleMusic[i][1])
    IdleMusicSorted[i][3] = readTrackTags(IdleMusicSorted[i][1])
end
for i = 1,#FinishMusic do
    FinishMusic[i][3] = readTrackTags(FinishMusic[i][1])
    FinishMusicSorted[i][3] = readTrackTags(FinishMusicSorted[i][1])
end
for i = 1,#FinishPodiumMusic do
    FinishPodiumMusic[i][3] = readTrackTags(FinishPodiumMusic[i][1])
    FinishPodiumMusicSorted[i][3] = readTrackTags(FinishPodiumMusicSorted[i][1])
end
for i = 1,#ReplayMusic do
    ReplayMusic[i][3] = readTrackTags(ReplayMusic[i][1])
    ReplayMusicSorted[i][3] = readTrackTags(ReplayMusicSorted[i][1])
end
for i = 1,#OtherMusic do
    OtherMusic[i][3] = readTrackTags(OtherMusic[i][1])
    OtherMusicSorted[i][3] = readTrackTags(OtherMusicSorted[i][1])
end

function getCoverArt(track)
    local CoverArtForThisTrack = false
    if CoverArtCache[track] ~= nil then return CoverArtCache[track] end

    if CoverArtConfig[track] and CoverArtConfig[track] == "blank" then
        CoverArtForThisTrack = ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer/" .. "icon.png"
    end
    
    if CoverArtConfig[track] and io.fileExists(ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer/Music/CoverArts/" .. CoverArtConfig[track]) then
        CoverArtForThisTrack = ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer/Music/CoverArts/" .. CoverArtConfig[track]
    end
    
    if not CoverArtForThisTrack then
        if io.fileExists(ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer/Music/CoverArts/" .. track .. ".png") then
            CoverArtForThisTrack = ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer/Music/CoverArts/" .. track .. ".png"
        elseif io.fileExists(ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer/Music/CoverArts/" .. track .. ".jpg") then
            CoverArtForThisTrack = ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer/Music/CoverArts/" .. track .. ".jpg"
        elseif io.fileExists(ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer/Music/CoverArts/" .. track .. ".jpeg") then
            CoverArtForThisTrack = ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer/Music/CoverArts/" .. track .. ".jpeg"
        elseif io.fileExists(ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer/Music/CoverArts/" .. track .. ".gif") then
            CoverArtForThisTrack = ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer/Music/CoverArts/" .. track .. ".gif"
        end
    end
    
    if not CoverArtForThisTrack then
        for i = 1,#CoverArts do
            if string.find(track, CoverArts[i][1]) then
                CoverArtForThisTrack = ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer" .. CoverArts[i][2]
                break
            end
        end
    end
    CoverArtCache[track] = CoverArtForThisTrack
    return CoverArtForThisTrack
end

function getNewTrack()
    --ac.log(TracksMemory)
    for attempts = 1,10000 do
        local NextTracksTable = {}
        local TrackChoosen = false
        if Sim.isReplayActive and EnableReplayPlaylist then

            if ReplayMusic[1] then
                ReplayMusicCounter = ReplayMusicCounter + 1
                if not ReplayMusic[ReplayMusicCounter] then
                    ReplayMusicCounter = 1
                end
                for i = 1,math.ceil(math.max(5, #ReplayMusic * 0.1)) do
                    if ReplayMusic[ReplayMusicCounter+i-1] then
                        NextTracksTable[i] = ReplayMusic[ReplayMusicCounter+i-1]
                    else
                        NextTracksTable[i] = ReplayMusic[ReplayMusicCounter+i-1-#ReplayMusic]
                    end
                end
            else
                OtherMusicCounter = OtherMusicCounter + 1
                if not OtherMusic[OtherMusicCounter] then
                    OtherMusicCounter = 1
                end
                for i = 1,math.ceil(math.max(5, #OtherMusic * 0.1)) do
                    if OtherMusic[OtherMusicCounter+i-1] then
                        NextTracksTable[i] = OtherMusic[OtherMusicCounter+i-1]
                    else
                        NextTracksTable[i] = OtherMusic[OtherMusicCounter+i-1-#OtherMusic]
                    end
                end
            end
            MusicType = "replay"

        elseif PlayerFinished and (not PlayedFinishTrack) and FinishMusic[1] then

            if ((not PodiumFinishTop25Percent) and PlayerCarRacePosition <= 3 and PlayerCarRacePosition ~= CarsInRace) or (PodiumFinishTop25Percent and PlayerCarRacePosition <= CarsInRace*0.25) and FinishPodiumMusic[1] then
                FinishPodiumMusicCounter = FinishPodiumMusicCounter + 1
                if not FinishPodiumMusic[FinishPodiumMusicCounter] then
                    FinishPodiumMusicCounter = 1
                end
                for i = 1,math.ceil(math.max(5, #FinishPodiumMusic * 0.1)) do
                    if FinishPodiumMusic[FinishPodiumMusicCounter+i-1] then
                        NextTracksTable[i] = FinishPodiumMusic[FinishPodiumMusicCounter+i-1]
                    else
                        NextTracksTable[i] = FinishPodiumMusic[FinishPodiumMusicCounter+i-1-#FinishPodiumMusic]
                    end
                end
            elseif FinishMusic[1] then
                FinishMusicCounter = FinishMusicCounter + 1
                if not FinishMusic[FinishMusicCounter] then
                    FinishMusicCounter = 1
                end
                for i = 1,math.ceil(math.max(5, #FinishMusic * 0.1)) do
                    if FinishMusic[FinishMusicCounter+i-1] then
                        NextTracksTable[i] = FinishMusic[FinishMusicCounter+i-1]
                    else
                        NextTracksTable[i] = FinishMusic[FinishMusicCounter+i-1-#FinishMusic]
                    end
                end
            else
                OtherMusicCounter = OtherMusicCounter + 1
                if not OtherMusic[OtherMusicCounter] then
                    OtherMusicCounter = 1
                end
                for i = 1,math.ceil(math.max(5, #OtherMusic * 0.1)) do
                    if OtherMusic[OtherMusicCounter+i-1] then
                        NextTracksTable[i] = OtherMusic[OtherMusicCounter+i-1]
                    else
                        NextTracksTable[i] = OtherMusic[OtherMusicCounter+i-1-#OtherMusic]
                    end
                end
            end
            MusicType = "finish"

        elseif ((PlayerCarSpeed < 1 and IdleTimer > 10) or Car.isInPitlane or Car.isInPit or Sim.isInMainMenu) and EnableIdlePlaylist and IdleMusic[1] then

            IdleMusicCounter = IdleMusicCounter + 1
            if not IdleMusic[IdleMusicCounter] then
                IdleMusicCounter = 1
            end
            for i = 1,math.ceil(math.max(5, #IdleMusic * 0.1)) do
                if IdleMusic[IdleMusicCounter+i-1] then
                    NextTracksTable[i] = IdleMusic[IdleMusicCounter+i-1]
                else
                    NextTracksTable[i] = IdleMusic[IdleMusicCounter+i-1-#IdleMusic]
                end
            end
            MusicType = "idle"

        elseif (EnablePracticePlaylist and Session.type == 1) then
            if PracticeMusic[1] then
                PracticeMusicCounter = PracticeMusicCounter + 1
                if not PracticeMusic[PracticeMusicCounter] then
                    PracticeMusicCounter = 1
                end
                for i = 1,math.ceil(math.max(5, #PracticeMusic * 0.1)) do
                    if PracticeMusic[PracticeMusicCounter+i-1] then
                        NextTracksTable[i] = PracticeMusic[PracticeMusicCounter+i-1]
                    else
                        NextTracksTable[i] = PracticeMusic[PracticeMusicCounter+i-1-#PracticeMusic]
                    end
                end
            else
                OtherMusicCounter = OtherMusicCounter + 1
                if not OtherMusic[OtherMusicCounter] then
                    OtherMusicCounter = 1
                end
                for i = 1,math.ceil(math.max(5, #OtherMusic * 0.1)) do
                    if OtherMusic[OtherMusicCounter+i-1] then
                        NextTracksTable[i] = OtherMusic[OtherMusicCounter+i-1]
                    else
                        NextTracksTable[i] = OtherMusic[OtherMusicCounter+i-1-#OtherMusic]
                    end
                end
            end
            MusicType = "practice"

        elseif (EnableQualifyingPlaylist and Session.type == 2) then

            if QualificationMusic[1] then
                QualificationMusicCounter = QualificationMusicCounter + 1
                if not QualificationMusic[QualificationMusicCounter] then
                    QualificationMusicCounter = 1
                end
                for i = 1,math.ceil(math.max(5, #QualificationMusic * 0.1)) do
                    if QualificationMusic[QualificationMusicCounter+i-1] then
                        NextTracksTable[i] = QualificationMusic[QualificationMusicCounter+i-1]
                    else
                        NextTracksTable[i] = QualificationMusic[QualificationMusicCounter+i-1-#QualificationMusic]
                    end
                end
            else
                OtherMusicCounter = OtherMusicCounter + 1
                if not OtherMusic[OtherMusicCounter] then
                    OtherMusicCounter = 1
                end
                for i = 1,math.ceil(math.max(5, #OtherMusic * 0.1)) do
                    if OtherMusic[OtherMusicCounter+i-1] then
                        NextTracksTable[i] = OtherMusic[OtherMusicCounter+i-1]
                    else
                        NextTracksTable[i] = OtherMusic[OtherMusicCounter+i-1-#OtherMusic]
                    end
                end
            end
            MusicType = "quali"

        elseif Session.type == 3 then

            if RaceMusic[1] then
                RaceMusicCounter = RaceMusicCounter + 1
                if not RaceMusic[RaceMusicCounter] then
                    RaceMusicCounter = 1
                end
                for i = 1,math.ceil(math.max(5, #RaceMusic * 0.1)) do
                    if RaceMusic[RaceMusicCounter+i-1] then
                        NextTracksTable[i] = RaceMusic[RaceMusicCounter+i-1]
                    else
                        NextTracksTable[i] = RaceMusic[RaceMusicCounter+i-1-#RaceMusic]
                    end
                end
            else
                OtherMusicCounter = OtherMusicCounter + 1
                if not OtherMusic[OtherMusicCounter] then
                    OtherMusicCounter = 1
                end
                for i = 1,math.ceil(math.max(5, #OtherMusic * 0.1)) do
                    if OtherMusic[OtherMusicCounter+i-1] then
                        NextTracksTable[i] = OtherMusic[OtherMusicCounter+i-1]
                    else
                        NextTracksTable[i] = OtherMusic[OtherMusicCounter+i-1-#OtherMusic]
                    end
                end
            end
            MusicType = "race"

        else

            OtherMusicCounter = OtherMusicCounter + 1
            if not OtherMusic[OtherMusicCounter] then
                OtherMusicCounter = 1
            end
            for i = 1,math.ceil(math.max(5, #OtherMusic * 0.1)) do
                if OtherMusic[OtherMusicCounter+i-1] then
                    NextTracksTable[i] = OtherMusic[OtherMusicCounter+i-1]
                else
                    NextTracksTable[i] = OtherMusic[OtherMusicCounter+i-1-#OtherMusic]
                end
            end
            MusicType = "other"
            
        end

        local tracksLastPlayedTime = {}
        local tracksTagsAllowToPlay = {}
        local nextTrackTitle, _  = readTrackTags(NextTracksTable[1][1])
        _, tracksTagsAllowToPlay[1] = readTrackTags(NextTracksTable[1][1])
        --ac.log("--------------------------------------------------------------------")
        --ac.log("Track Title:", nextTrackTitle)
        --ac.log("Tags Allow To Play:", tracksTagsAllowToPlay[1])
        if tracksTagsAllowToPlay[1] then
            local sampleSize = #NextTracksTable
            if sampleSize > 1 then
                for i = 1, sampleSize do
                    tracksLastPlayedTime[i] = TracksMemory[readTrackTags(NextTracksTable[i][1])] or 0
                    if i > 1 then
                        tracksTagsAllowToPlay[i] = readTrackTags(NextTracksTable[i][1])
                    end
                end
            end

            allowDayChanceSkip = true
            if sampleSize > 1 then
                for i = 2, sampleSize do
                    if tracksLastPlayedTime[1] == 0 then
                        nextTracksAllowToPlay = true
                        break
                    elseif tracksLastPlayedTime[i] == 0 then
                        nextTracksAllowToPlay = false
                        allowDayChanceSkip = false
                        break
                    elseif tracksLastPlayedTime[1] <= tracksLastPlayedTime[i] or tracksTagsAllowToPlay[i] == false then
                        nextTracksAllowToPlay = true
                    else
                        nextTracksAllowToPlay = false
                        --ac.log("Next Tested Track,", readTrackTags(NextTracksTable[i][1]), "Was played: ", math.ceil((os.time() - tracksLastPlayedTime[i])/(day)*100)/100, " Days Ago so it disallowed the choice of this one.")
                        break
                    end
                end
            else
                nextTracksAllowToPlay = true
            end

            local day = 86400
            local daychance = math.random()
            local daychanceAllowsToPlay, nextTracksAllowToPlay

            if allowDayChanceSkip then
                --ac.log("Track Was Last Played:", math.ceil((os.time() - tracksLastPlayedTime[1])/(day)*100)/100, " Days Ago")
                for i = 1, 10 do -- We may allow tracks that have not been played for a while, with increasing chance depending on how long ago that was.
                    if tracksLastPlayedTime[1] < os.time()-day*7*i and daychance <= 0.1*i then
                        daychanceAllowsToPlay = true
                        --ac.log("daychance allowed it to play")
                        break
                    else
                        daychanceAllowsToPlay = false
                    end
                end
            else
                daychanceAllowsToPlay = false
            end


            --ac.log("sampleSize", sampleSize, ", daychanceAllowsToPlay", daychanceAllowsToPlay, ", nextTracksAllowToPlay", nextTracksAllowToPlay)
            if not (daychanceAllowsToPlay or nextTracksAllowToPlay) then
                --ac.log("This track is not allowed to play")
                tracksTagsAllowToPlay[1] = false
            end

        end

        if tracksTagsAllowToPlay[1] then
            TrackChoosen = true
            FilePath = NextTracksTable[1][2]
            CurrentlyPlaying = nextTrackTitle
        end

        if TrackChoosen and MusicType == "finish" then
            PlayedFinishTrack = true
        end

        if TrackChoosen then
            --ac.log(FilePath)
            nowplayingiconcoverart = getCoverArt(CurrentlyPlaying)
            TracksMemory[readTrackTags(NextTracksTable[1][1])] = os.time()
            local trackMemoryFile = ac.INIConfig.load(ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer/TracksPlayedMemory/" .. readTrackTags(NextTracksTable[1][1]) ..".ini", ac.INIFormat.Extended)
            trackMemoryFile:set("lastplayedtimes", "time", os.time())
            trackMemoryFile:save()

            io.save(ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer/OBS Stuff/tracktitle.txt", CurrentlyPlaying, false)
            CoverArtExportCanvas:update(RenderCoverArtExportCanvas)
            CoverArtExportCanvas:save(ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer/OBS Stuff/CoverArt.png")

            break
        end
    end

    return FilePath
end

UpdateCounter = 0
SkipAttempts = 0
function script.update(dt)

    ac.debug("sunangle", ac.getSunAngle())
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
        if CurrentTrack then
            CurrentTrack:setVolume(0)
            CurrentTrack:setCurrentTime(CurrentTrack:duration())
            CurrentVolume = 0
        end
        if #MusicQueue == 0 or (PlayerFinished and (not PlayedFinishTrack) and FinishMusic[1]) then
            CurrentTrack = ui.MediaPlayer(getNewTrack())
            DontSkipCurrentTrack = false
        else
            PlaySelectedTrack(MusicQueue[1])
            table.remove(MusicQueue, 1)
        end
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
        NowPlayingOpacityCurrent = 0
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
                if EnableMusic and SkipAttempts > 20 and (Session.type ~= 3 or (Session.type == 3 and (Sim.timeToSessionStart < 0 or Sim.timeToSessionStart >= 60000))) and HitValue == 0 then
                    updateRaceStatusData()
                    if #MusicQueue == 0 or (PlayerFinished and (not PlayedFinishTrack) and FinishMusic[1])  then
                        CurrentTrack = ui.MediaPlayer(getNewTrack())
                        DontSkipCurrentTrack = false
                    else
                        PlaySelectedTrack(MusicQueue[1])
                        table.remove(MusicQueue, 1)
                    end
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
                    NowPlayingOpacityCurrent = 0
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
    ui.tabItem("Music List", {}, MusicListTab)
    ui.tabItem("Debug", {}, DebugTab)
end

function PlaySelectedTrack(selectedTrack)
    CurrentTrack:setVolume(0)
    CurrentTrack:setCurrentTime(CurrentTrack:duration())
    CurrentTrack = ui.MediaPlayer(selectedTrack[2])
    CurrentVolume = TargetVolume*TargetVolumeMultiplier
    CurrentTrack:setVolume(CurrentVolume)
    CurrentTrack:play()
    CurrentlyPlaying = selectedTrack[3]
    DontSkipCurrentTrack = true
    NowPlayingOpacityCurrent = 0
    nowplayingiconcoverart = getCoverArt(CurrentlyPlaying)
    io.save(ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer/OBS Stuff/tracktitle.txt", CurrentlyPlaying, false)
    CoverArtExportCanvas:update(RenderCoverArtExportCanvas)
    CoverArtExportCanvas:save(ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer/OBS Stuff/CoverArt.png")
end

function HandleMusicListItem(item)
    if (not MusicListHideWithCoverArt) or (MusicListHideWithCoverArt and ((not CoverArtCache[item[3]]) or CoverArtCache[item[3]] == ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer/" .. "icon.png")) then
        ui.button("▶")
        if ui.itemHovered() then
            ui.setTooltip('Play Now')
        end
        if ui.itemClicked(ui.MouseButton.Left, false) then
            PlaySelectedTrack(item)
        end
        ui.sameLine()
        ui.button("⏫")
        if ui.itemHovered() then
            ui.setTooltip('Add To Queue')
        end
        if ui.itemClicked(ui.MouseButton.Left, false) then
            table.insert(MusicQueue, item)
        end
        ui.sameLine()
        if CoverArtCache[item[3]] == nil then
            getCoverArt(item[3])
        end
        if CoverArtCache[item[3]] ~= false then
            ui.image(CoverArtCache[item[3]], 22)
        else
            ui.image(ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer/" .. "icon.png", 22)
        end
        ui.sameLine()
        ui.button(item[3])
        if ui.itemHovered() then
            ui.setTooltip('Copy Name To Clipboard')
        end
        if ui.itemClicked(ui.MouseButton.Left, false) then
            ac.setClipboadText(item[3])
        end
        ui.separator()
    end
end

function MusicListTab()
    NeedToSaveConfig = false
    local checkbox

    checkbox = ui.checkbox("Only Show Music Without Cover Art (To make it easier to find which tracks still need one)", MusicListHideWithCoverArt)
    if checkbox then
        MusicListHideWithCoverArt = not MusicListHideWithCoverArt
        ConfigFile:set("settings", "musiclisthidewithcoverart", MusicListHideWithCoverArt)
        NeedToSaveConfig = true
    end

    ui.tabBar("MusicListItems", {}, MusicListTypes)
end

function MusicListTypes()
    ui.tabItem("Idle", {}, MusicListTabIdle)
    ui.tabItem("Practice", {}, MusicListTabPractice)
    ui.tabItem("Qualification", {}, MusicListTabQualification)
    ui.tabItem("Race", {}, MusicListTabRace)
    ui.tabItem("Finish", {}, MusicListTabFinish)
    ui.tabItem("FinishPodium", {}, MusicListTabFinishPodium)
    ui.tabItem("Replay", {}, MusicListTabReplay)
    ui.tabItem("Other", {}, MusicListTabOther)
    ui.tabItem("Queue", {}, MusicListTabQueue)
end

function MusicListTabIdle()
    if #IdleMusicSorted == 0 then
        for i = 1,#OtherMusicSorted do
            HandleMusicListItem(OtherMusicSorted[i])
        end
    end
    for i = 1,#IdleMusicSorted do
        HandleMusicListItem(IdleMusicSorted[i])
    end
end

function MusicListTabPractice()
    if #PracticeMusicSorted == 0 then
        for i = 1,#OtherMusicSorted do
            HandleMusicListItem(OtherMusicSorted[i])
        end
    end
    for i = 1,#PracticeMusicSorted do
        HandleMusicListItem(PracticeMusicSorted[i])
    end
end

function MusicListTabQualification()
    if #QualificationMusicSorted == 0 then
        for i = 1,#OtherMusicSorted do
            HandleMusicListItem(OtherMusicSorted[i])
        end
    end
    for i = 1,#QualificationMusicSorted do
        HandleMusicListItem(QualificationMusicSorted[i])
    end
end

function MusicListTabRace()
    if #RaceMusicSorted == 0 then
        for i = 1,#OtherMusicSorted do
            HandleMusicListItem(OtherMusicSorted[i])
        end
    end
    for i = 1,#RaceMusicSorted do
        HandleMusicListItem(RaceMusicSorted[i])
    end
end

function MusicListTabFinish()
    if #FinishMusicSorted == 0 then
        for i = 1,#OtherMusicSorted do
            HandleMusicListItem(OtherMusicSorted[i])
        end
    end
    for i = 1,#FinishMusicSorted do
        HandleMusicListItem(FinishMusicSorted[i])
    end
end

function MusicListTabFinishPodium()
    if #FinishPodiumMusicSorted == 0 then
        for i = 1,#OtherMusicSorted do
            HandleMusicListItem(OtherMusicSorted[i])
        end
    end
    for i = 1,#FinishPodiumMusicSorted do
        HandleMusicListItem(FinishPodiumMusicSorted[i])
    end
end

function MusicListTabReplay()
    if #ReplayMusicSorted == 0 then
        for i = 1,#OtherMusicSorted do
            HandleMusicListItem(OtherMusicSorted[i])
        end
    end
    for i = 1,#ReplayMusicSorted do
        HandleMusicListItem(ReplayMusicSorted[i])
    end
end

function MusicListTabOther()
    for i = 1,#OtherMusicSorted do
        HandleMusicListItem(OtherMusicSorted[i])
    end
end

function MusicListTabQueue()
    for i = 1, #MusicQueue do
        if MusicQueue[i] then
            ui.button("🔼")
            if ui.itemHovered() then
                ui.setTooltip('Push To Top')
            end
            if ui.itemClicked(ui.MouseButton.Left, false) then
                table.insert(MusicQueue, 1, MusicQueue[i])
                table.remove(MusicQueue, i+1)
            end
            ui.sameLine()
            ui.button("🔽")
            if ui.itemHovered() then
                ui.setTooltip('Push To Bottom')
            end
            if ui.itemClicked(ui.MouseButton.Left, false) then
                table.insert(MusicQueue, MusicQueue[i])
                table.remove(MusicQueue, i)
            end
            ui.sameLine()
            ui.button("🚫")
            if ui.itemHovered() then
                ui.setTooltip('Remove From Queue')
            end
            if ui.itemClicked(ui.MouseButton.Left, false) then
                table.remove(MusicQueue, i)
            end
            ui.sameLine()
            if CoverArtCache[MusicQueue[i][3]] == nil then
                getCoverArt(MusicQueue[i][3])
            end
            if CoverArtCache[MusicQueue[i][3]] ~= false then
                ui.image(CoverArtCache[MusicQueue[i][3]], 22)
            else
                ui.image(ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer/" .. "icon.png", 22)
            end
            ui.sameLine()
            ui.button(i .. ". " .. MusicQueue[i][3])
            if ui.itemHovered() then
                ui.setTooltip('Copy Name To Clipboard')
            end
            if ui.itemClicked(ui.MouseButton.Left, false) then
                ac.setClipboadText(MusicQueue[i][3])
            end
            ui.separator()
        end
    end
end

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

    checkbox = ui.checkbox("Enable Icon (Or Cover Art if available)", EnableNowPlayingIcon)
    if checkbox then
        EnableNowPlayingIcon = not EnableNowPlayingIcon
        ConfigFile:set("settings", "nowplayingicon", EnableNowPlayingIcon)
        NeedToSaveConfig = true
    end
    
    if EnableNowPlayingIcon then
        checkbox = ui.checkbox("Enable Animated Icon (Disables Cover Arts)", EnableAnimatedNowPlayingIcon)
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
    if CurrentlyPlaying then
        ui.text("CurrentlyPlaying: " .. CurrentlyPlaying)
    else
        ui.text("CurrentlyPlaying: Nothing")
    end
    if MusicType then
        ui.text("Playlist: " .. MusicType)
    else
        ui.text("Playlist: None")
    end
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

ac.setWindowSizeConstraints('main', vec2(650,100), vec2(650,600))
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

    
    ac.setWindowSizeConstraints('nowplaying', vec2(windowWidth.x+windowWidthRange+75*NowPlayingWidgetSize,100*NowPlayingWidgetSize), vec2(windowWidth.x+windowWidthRange+75*NowPlayingWidgetSize,100*NowPlayingWidgetSize))

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


local function ACIsShuttingDown()
    io.save(ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer/OBS Stuff/tracktitle.txt", "", false)
    io.save(ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer/OBS Stuff/nowplayingtime.txt", "", false)
    io.copyFile(ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer/OBS Stuff/BlankCoverArt.png", ac.getFolder(ac.FolderID.ACApps) .. "/lua/DynamicMusicPlayer/OBS Stuff/CoverArt.png", false)
end

ac.onRelease(ACIsShuttingDown)