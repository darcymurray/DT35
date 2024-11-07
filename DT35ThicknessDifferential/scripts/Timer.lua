TimerHandle = {}
TimerHandle.MinTime = "1730945314221"
TimerHandle.MaxTime = "1730945374221"
TimerHandle.Timer = Timer.create()
TimerHandle.Timer:setExpirationTime(100)
TimerHandle.Timer:setPeriodic(true)

-- Main timer expiry and measurement reading function
local function handleOnExpired()
  local datetime = DateTime.getDateTime()
  local time = DateTime.getUnixTimeMilliseconds()
  Script.notifyEvent('UpdateDateTimeDisplay', string.sub(datetime, 1, -5))

  local dataA,  _ = Device.IOLinkDT35A:readProcessData() -- equivalent to IOLinkDT35A:readData(40, 0)
  local distanceA = string.unpack('I2', dataA)  -- Extract UINT16 value
  local distanceAmm = ((distanceA % 256) * 256) + (distanceA // 256)

  local dataB,  _ = Device.IOLinkDT35B:readProcessData() -- equivalent to IOLinkDT35B:readData(40, 0)
  local distanceB = string.unpack('I2', dataB)  -- Extract UINT16 value
  local distanceBmm = ((distanceB % 256) * 256) + (distanceB // 256)

  local objectThickness = Main.DistanceBetweenSensors - (distanceAmm + distanceBmm)

  DatabaseHandle.Insert(time, objectThickness)
end
TimerHandle.Timer.register(TimerHandle.Timer, 'OnExpired', handleOnExpired)

local function OnGetValuesSubmit()
  print("start: " .. TimerHandle.MinTime)
  DatabaseHandle.Get()
  print("end: " .. TimerHandle.MaxTime)
end
Script.serveFunction("DT35ThicknessDifferential.OnGetValuesSubmit", OnGetValuesSubmit)

TimerHandle.timerOn = 1
local function OnToggleMeasurementsSubmit()
  if TimerHandle.timerOn == 1 then TimerHandle.Timer:stop() TimerHandle.timerOn = 0
  else TimerHandle.Timer:start() TimerHandle.timerOn = 1 end
end
Script.serveFunction("DT35ThicknessDifferential.OnToggleMeasurementsSubmit", OnToggleMeasurementsSubmit)

