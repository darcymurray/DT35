TimerHandle = {}
TimerHandle.StartDate = 1731236400000
TimerHandle.StartDateString = "11/11/2024"
TimerHandle.EndDate = 1731236400000
TimerHandle.EndDateString = "11/11/2024"
TimerHandle.StartTime = 40380000
TimerHandle.StartTimeString = "11:13:00"
TimerHandle.EndTime = 40440000
TimerHandle.EndTimeString = "11:14:00"
TimerHandle.Timer = Timer.create()
TimerHandle.Timer:setExpirationTime(Main.TimerExpirationTime)
TimerHandle.Timer:setPeriodic(true)

-- Main timer expiry and measurement reading function
local function handleOnExpired()
  local datetime = DateTime.getDateTime()
  local time = DateTime.getUnixTimeMilliseconds()
  Script.notifyEvent('UpdateDateTimeDisplay', string.sub(datetime, 1, -5))

  if TimerHandle.measuringOn == 1 then
    local dataA,  _ = Device.IOLinkDT35A:readProcessData() -- equivalent to IOLinkDT35A:readData(40, 0)
    if #dataA ~= 2 then return end
    local distanceA = string.unpack('I2', dataA)  -- Extract UINT16 value
    local distanceAmm = ((distanceA % 256) * 256) + (distanceA // 256)

    local dataB,  _ = Device.IOLinkDT35B:readProcessData() -- equivalent to IOLinkDT35B:readData(40, 0)
    local distanceB = string.unpack('I2', dataB)  -- Extract UINT16 value
    local distanceBmm = ((distanceB % 256) * 256) + (distanceB // 256)

    local objectThickness = Main.DistanceBetweenSensors - (distanceAmm + distanceBmm)

    DatabaseHandle.Insert(time, objectThickness)
    ViewerLive.DisplayData(time, objectThickness)
  end
end
TimerHandle.Timer:register('OnExpired', handleOnExpired)

local function OnGetValuesSubmit()
  DatabaseHandle.Get()
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

