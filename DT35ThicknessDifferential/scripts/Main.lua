require("Serves")
-- require("NTP") 
require("Device")
require("Database")
require("Timer")
require("Viewer")
require("DateTime")

Main = {}
Main.DistanceBetweenSensors = 300
Main.NumDevices = 2
Database.DbFileName = "/sdcard/0/database/SIM.API.Test.db"
TimerHandle.Timer:setExpirationTime(1000)
-- DateTime.setDateTime(2024, 11, 8, 11, 45, 30, false) -- One Time
print(DateTime.getTimeZone())

local function main()
  if DatabaseHandle.DatabaseExists() and DatabaseHandle.DatabaseInitialised() and DatabaseHandle.InitialiseStatements() then
    Device.PowerA:enable(true)
    Device.PowerB:enable(true)
    Device.Timer:register('OnExpired', Device.HandleOnExpired) -- Waits for devices to connect
    TimerHandle.Timer:start() -- Starts taking measurements
  else return end
end
Script.register("Engine.OnStarted", main)

