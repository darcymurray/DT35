require("Serves")
require("NTP")
require("Viewer")
require("Device")
require("Database")
require("Timer")

Main = {}
Main.DistanceBetweenSensors = 300
Main.DbFileName = "/sdcard/0/database/SIM.API.Test.db"
Main.NumDevices = 2

local function main()
  if DatabaseHandle.DatabaseExists() and DatabaseHandle.DatabaseInitialised() and DatabaseHandle.InitialiseStatements() then
    Device.PowerA:enable(true)
    Device.PowerB:enable(true)
    TimerHandle.Timer:start()
  else return end
end
Script.register("Engine.OnStarted", main)

