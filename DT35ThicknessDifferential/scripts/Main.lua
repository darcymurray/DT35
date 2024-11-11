Main = {}
Main.DistanceBetweenSensors = 300
Main.NumDevices = 2
Main.TimerExpirationTime = 1000
Main.ViewerLiveDurationSeconds = 60
Main.DbFilePath = "/sdcard/0/database/SIM.API.Test.db"

require("Serves")
-- require("NTP") 
require("Device")
require("Database")
require("Timer")
require("ViewerHistorical")
require("ViewerLive")
require("DateTime")

local function main()
  if DatabaseHandle.DatabaseExists() and DatabaseHandle.DatabaseInitialised() and DatabaseHandle.InitialiseStatements() then
    Device.PowerA:enable(true)
    Device.PowerB:enable(true)
    Device.Timer:register('OnExpired', Device.HandleOnExpired) -- Waits for devices to connect
    TimerHandle.Timer:start() -- Starts taking measurements
  else return end
end
Script.register("Engine.OnStarted", main)

