TimerHandle = {}
TimerHandle.StartDate = 1731495600000
TimerHandle.StartDateString = "14/11/2024"
TimerHandle.EndDate = 1731495600000
TimerHandle.EndDateString = "14/11/2024"
TimerHandle.StartTime = 45240000
TimerHandle.StartTimeString = "12:34:00"
TimerHandle.EndTime = 45300000
TimerHandle.EndTimeString = "12:35:00"
TimerHandle.Timer = Timer.create()
TimerHandle.Timer:setExpirationTime(Main.TimerExpirationTime)
TimerHandle.Timer:setPeriodic(true)

-- Main timer expiry and measurement reading function
local zeroA = 130 * 1000000
local zeroB = 30 * 1000000
local distanceBetweenSensors = 159.4
local realLength = 67.9
Script.serveEvent('DT35ThicknessDifferential.UpdateLiveThicknessDisplay', 'UpdateLiveThicknessDisplay')
Script.serveEvent('DT35ThicknessDifferential.UpdateLiveErrorDisplay', 'UpdateLiveErrorDisplay')
local function OD2HandleOnExpired()
  local datetime = DateTime.getDateTime()
  local time = DateTime.getUnixTimeMilliseconds()
  Script.notifyEvent('UpdateDateTimeDisplay', string.sub(datetime, 1, -5))

  if TimerHandle.measuringOn == 1 then
    local dataA, _ = Device.IOLinkA:readProcessData()
    local distanceA = string.unpack('>i4', dataA)
    local distanceAmm = (tonumber(distanceA) + zeroA) / 1000000

    local dataB,  _ = Device.IOLinkB:readProcessData()
    local distanceB = string.unpack('>i4', dataB)
    local distanceBmm = (tonumber(distanceB) + zeroB) / 1000000

    local objectThickness = distanceBetweenSensors - (distanceAmm + distanceBmm)
    if objectThickness < 0 then return end
    local readingError = math.abs(realLength - objectThickness)

    Script.notifyEvent('UpdateLiveThicknessDisplay', string.format("%.4f", objectThickness))
    Script.notifyEvent('UpdateLiveErrorDisplay', string.format("%.4f", readingError))

    DatabaseHandle.Insert(time, objectThickness, readingError)
    -- ViewerLive.DisplayData(ViewerLive.ThicknessViewer, ViewerLive.ThicknessViewerDecoration, time, objectThickness, ViewerLive.Thickness)
    ViewerLive.DisplayData(time, objectThickness, readingError)
  end
end
TimerHandle.Timer:register('OnExpired', OD2HandleOnExpired)

local function OnGetValuesSubmit()
  local startDateTime, endDateTime = TimerHandle.StartDate + TimerHandle.StartTime, TimerHandle.EndDate + TimerHandle.EndTime
  DatabaseHandle.Get(startDateTime, endDateTime)
end
Script.serveFunction("DT35ThicknessDifferential.OnGetValuesSubmit", OnGetValuesSubmit)

TimerHandle.measuringOn = 1
local function OnToggleMeasurementsSubmit()
  if TimerHandle.measuringOn == 1 then TimerHandle.measuringOn = 0 else TimerHandle.measuringOn = 1 end
end
Script.serveFunction("DT35ThicknessDifferential.OnToggleMeasurementsSubmit", OnToggleMeasurementsSubmit)

-- dd/mm/yyyy -> unix
local function OnStartDateChange(change)
  local unix = DT.DateToUnixMSTimestamp(change)
  if unix ~= 0 then
    TimerHandle.StartDate = unix
    TimerHandle.StartDateString = change
    print(string.format("Start date set to: %s (%s)", change, tostring(unix)))
    Script.notifyEvent('UpdateStartDateDisplay', change)
    Script.notifyEvent('UpdateStartDateTimeDisplay', string.format("%s %s", TimerHandle.StartDateString, TimerHandle.StartTimeString))
    -- Script.notifyEvent('UpdateStartDateTimeDisplay', string.format("%s %s (%s)", TimerHandle.StartDateString, TimerHandle.StartTimeString, TimerHandle.StartDate + TimerHandle.StartTime))
  end
end
Script.serveFunction("DT35ThicknessDifferential.OnStartDateChange", OnStartDateChange)

-- dd/mm/yyyy -> unix
local function OnEndDateChange(change)
  local unix = DT.DateToUnixMSTimestamp(change)
  if unix ~= 0 then
    TimerHandle.EndDate = unix
    TimerHandle.EndDateString = change
    print(string.format("End date set to: %s (%s)", change, tostring(unix)))
    Script.notifyEvent('UpdateEndDateDisplay', change)
    Script.notifyEvent('UpdateEndDateTimeDisplay', string.format("%s %s", TimerHandle.EndDateString, TimerHandle.EndTimeString))
    -- Script.notifyEvent('UpdateEndDateTimeDisplay', string.format("%s %s (%s)", TimerHandle.EndDateString, TimerHandle.EndTimeString, TimerHandle.EndDate + TimerHandle.EndTime))
  end
end
Script.serveFunction("DT35ThicknessDifferential.OnEndDateChange", OnEndDateChange)

-- hh:mm:ss -> unix
local function OnStartTimeChange(change)
  local unix = DT.TimeToUnixMSTimestamp(change)
  if unix ~= 0 then
    TimerHandle.StartTime = unix
    TimerHandle.StartTimeString = change
    print(string.format("Start time set to: %s (%s)", change, tostring(unix)))
    Script.notifyEvent('UpdateStartTimeDisplay', change)
    Script.notifyEvent('UpdateStartDateTimeDisplay', string.format("%s %s", TimerHandle.StartDateString, TimerHandle.StartTimeString))
    -- Script.notifyEvent('UpdateStartDateTimeDisplay', string.format("%s %s (%s)", TimerHandle.StartDateString, TimerHandle.StartTimeString, TimerHandle.StartDate + TimerHandle.StartTime))
  end
end
Script.serveFunction("DT35ThicknessDifferential.OnStartTimeChange", OnStartTimeChange)

-- hh:mm:ss -> unix
local function OnEndTimeChange(change)
  local unix = DT.TimeToUnixMSTimestamp(change)
  if unix ~= 0 then
    TimerHandle.EndTime = unix
    TimerHandle.EndTimeString = change
    print(string.format("End time set to: %s (%s)", change, tostring(unix)))
    Script.notifyEvent('UpdateEndTimeDisplay', change)
    Script.notifyEvent('UpdateEndDateTimeDisplay', string.format("%s %s", TimerHandle.EndDateString, TimerHandle.EndTimeString))
    -- Script.notifyEvent('UpdateEndDateTimeDisplay', string.format("%s %s (%s)", TimerHandle.EndDateString, TimerHandle.EndTimeString, TimerHandle.EndDate + TimerHandle.EndTime))
  end
end
Script.serveFunction("DT35ThicknessDifferential.OnEndTimeChange", OnEndTimeChange)

