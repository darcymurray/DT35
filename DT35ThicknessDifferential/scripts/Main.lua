require("CsvWriter")
require("DeviceFunctions")
require("Database")

Main = {}
Main.MinTime = "02:59:24.302"
Main.MaxTime = "02:59:32.302"
Script.serveEvent('DT35ThicknessDifferential.UpdateMinTimeDisplay', 'UpdateMinTimeDisplay')
Script.serveEvent('DT35ThicknessDifferential.UpdateMaxTimeDisplay', 'UpdateMaxTimeDisplay')
Script.notifyEvent('UpdateMinTimeDisplay', Main.MinTime)
Script.notifyEvent('UpdateMaxTimeDisplay', Main.MaxTime)

local distanceBetweenSensors = 300

-- Timer set at interval to read process data
Timer = Timer.create()
Timer:setExpirationTime(100)
Timer:setPeriodic(true)

local function readDeviceInfo(device)
  DeviceFunctions.ReadIOLinkSpecificData(device)
  DeviceFunctions.ReadOutputSettings(device)
  DeviceFunctions.ReadSensorPerformanceSettings(device)
  DeviceFunctions.ReadProcessDataSettings(device)
  DeviceFunctions.ReadOtherSettings(device)
end

local function handleOnConnected()
  print('IO-Link device OD1000 connected')

  -- Device info/parameters/settings
  -- readDeviceInfo(IOLinkDT35A)
  -- readDeviceInfo(IOLinkDT35B)

  -- Actions
  -- DeviceFunctions.FactoryReset(device)
  -- DeviceFunctions.Teach(device, 0)

  -- Timer:start()
end
IOLink.RemoteDevice.register(IOLinkDT35A, 'OnConnected', handleOnConnected)
-- IOLink.RemoteDevice.register(IOLinkDT35B, 'OnConnected', handleOnConnected)

local function handleOnExpired()
  local time = DateTime.getTime()

  local dataA,  _ = IOLinkDT35A:readProcessData() -- equivalent to IOLinkDT35A:readData(40, 0)
  local distanceA = string.unpack('I2', dataA)  -- Extract UINT16 value
  local distanceAmm = ((distanceA % 256) * 256) + (distanceA // 256)

  local dataB,  _ = IOLinkDT35B:readProcessData() -- equivalent to IOLinkDT35B:readData(40, 0)
  local distanceB = string.unpack('I2', dataB)  -- Extract UINT16 value
  local distanceBmm = ((distanceB % 256) * 256) + (distanceB // 256)

  local objectThickness = distanceBetweenSensors - (distanceAmm + distanceBmm)

  print("DistanceA (mm): " .. distanceAmm .. ". DistanceB (mm): " .. distanceBmm .. ". Object Thickness (mm): " .. objectThickness)

  DatabaseHandle.Insert(time, objectThickness)
end
Timer.register(Timer, 'OnExpired', handleOnExpired)

-- Only allows strings in the valid format, and must be less than the maxTime
local function OnMinTimeChange(change)
  if string.match(change, "%d%d:%d%d:%d%d%.%d%d%d") ~= nil then
    if Main.MaxTime == "0" or change <= Main.MaxTime then
      Main.MinTime = change
      Script.notifyEvent('UpdateMinTimeDisplay', Main.MinTime)
      print("MinTime set to: " .. Main.MinTime)
    end
  end
end
Script.serveFunction("DT35ThicknessDifferential.OnMinTimeChange", OnMinTimeChange)

-- Only allows strings in the valid format, and must be greater than the minTime
local function OnMaxTimeChange(change)
  if string.match(change, "%d%d:%d%d:%d%d%.%d%d%d") ~= nil then
    if Main.MinTime == "0" or change > Main.MinTime then
      Main.MaxTime = change
      Script.notifyEvent('UpdateMinTimeDisplay', Main.MaxTime)
      print("MaxTime set to: " .. Main.MaxTime)
    end
  end
end
Script.serveFunction("DT35ThicknessDifferential.OnMaxTimeChange", OnMaxTimeChange)

local function OnGetValuesSubmit()
  print("start: " .. Main.MinTime)
  DatabaseHandle.Get()
  print("end: " .. Main.MaxTime)
end
Script.serveFunction("DT35ThicknessDifferential.OnGetValuesSubmit", OnGetValuesSubmit)

