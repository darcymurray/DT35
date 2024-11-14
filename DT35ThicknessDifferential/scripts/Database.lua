DatabaseHandle = {}

-- function DatabaseHandle.Exec(sqlQuery)
--   if (DatabaseHandle.db ~= nil) then
--     local tempStmt = DatabaseHandle.db:prepare(sqlQuery)
--     if (tempStmt ~= nil) then
--       local stepResult = tempStmt:step()
--       if (stepResult == "DONE") then print("OK")
--       elseif (stepResult == "ROW") then
--         local str = tempStmt:getColumnsAsString()
--         while (tempStmt:step() == "ROW") do str = str .. "\r\n" .. tempStmt:getColumnsAsString() end
--         print(str)
--       elseif (stepResult == "ERROR") then print("Error: " .. tempStmt:getErrorMessage()) end
--     else print("Could not exec statement: " .. DatabaseHandle.db:getErrorMessage()) end
--   else print("DB is not correctly set-up") end
-- end

-- function DatabaseHandle.SaveDb()
--   local file = CSV.CsvWriter.create("public/databaseAsTextFile.txt")
--   local testStatement = DatabaseHandle.db:prepare("SELECT * FROM measurements;")
--   local stepResult
--   local stepString
--   if testStatement ~= nil then
--     stepResult = testStatement:step()
--     while stepResult == "ROW" do
--       stepString = testStatement:getColumnsAsString()
--       if file:writeRow({stepString}) == false then print("Failed to write row") end
--       stepResult = testStatement:step()
--     end
--     assert(stepResult == "DONE", "ERROR")
--   end
-- end

function DatabaseHandle.DatabaseExists()
  if File.isdir("/sdcard/0") then
    if File.isdir("/sdcard/0/database") == false then 
      if File.mkdir("/sdcard/0/database") == true then
        if File.open("/sdcard/0/database/SIM.API.Test.db", "w") == nil then 
          print("Failed to create database file, can't open database") 
        else 
          print("Database file created")
          return true
        end
      else
        print("Failed to create database folder in SD card 0 directory, can't open database")
      end
    else
      if File.open("/sdcard/0/database/SIM.API.Test.db", "r") == nil then 
        if File.open("/sdcard/0/database/SIM.API.Test.db", "w") == nil then 
          print("Failed to create database file, can't open database") 
        else
          print("Database file created")
          return true
        end
      else 
        print("Database file exists")
        return true
      end
    end
  else
    print("SD card 0 directory not found, can't open database")
  end
  return false
end

function DatabaseHandle.DatabaseInitialised()
  -- Init
  DatabaseHandle.db = Database.SQL.SQLite.create()
  print("Database connection status: " .. tostring(DatabaseHandle.db:openFile(Main.DbFilePath, "READ_WRITE_CREATE")))
  print("Database SQLite version: " .. DatabaseHandle.db:getVersion())

  -- Schema
  local testStatement = DatabaseHandle.db:prepare("select * from measurements")
  if testStatement == nil then
    local initSchemaStatement = DatabaseHandle.db:prepare("CREATE TABLE measurements (Id INTEGER PRIMARY KEY AUTOINCREMENT, datetime TEXT NOT NULL, thickness REAL, error REAL);")
    if initSchemaStatement:step() == "DONE" then print("Database schema created") return true
    else print("Failed to create database schema") return false end

  else
    local sizeStatement = DatabaseHandle.db:prepare("select count(*) from measurements")
    if sizeStatement:step() == "ROW" then DatabaseHandle.Size = sizeStatement:getColumnInt(0)
    else DatabaseHandle.Size = 0 end
    Script.notifyEvent('UpdateDatabaseSizeDisplay', DatabaseHandle.Size)
    return true
  end
end

function DatabaseHandle.InitialiseStatements()
  -- Next Id
  local nextIdStatement = DatabaseHandle.db:prepare("select case when max(Id) is null then 1 else max(Id) + 1 end from measurements")
  assert(nextIdStatement ~= nil, "ERROR: nextIdStatement is null")
  nextIdStatement:step()
  DatabaseHandle.nextId = nextIdStatement:getColumnInt(0)

  -- Insert statement
  DatabaseHandle.insertStmt = DatabaseHandle.db:prepare("insert into measurements values(?,?,?,?)")
  if (DatabaseHandle.insertStmt == nil) then print("Error: " .. DatabaseHandle.db:getErrorMessage()) end

  -- Get statement
  DatabaseHandle.getStmt = DatabaseHandle.db:prepare("select * from measurements where (cast(datetime as float) >= ? and cast(datetime as float) <= ?);")
  if (DatabaseHandle.getStmt == nil) then print("Error: " .. DatabaseHandle.db:getErrorMessage()) end

  return true
end

DatabaseHandle.Size = 0
-- Inserts dataset into the database
function DatabaseHandle.Insert(time, thickness, errorAbs)
  if (DatabaseHandle.insertStmt ~= nil) then
    DatabaseHandle.insertStmt:bind(0, DatabaseHandle.nextId, time, thickness, errorAbs)
    if (DatabaseHandle.insertStmt:step() == "DONE") then
      DatabaseHandle.nextId = DatabaseHandle.nextId + 1
      DatabaseHandle.Size = DatabaseHandle.Size + 1
      Script.notifyEvent('UpdateDatabaseSizeDisplay', string.format("%.0f", DatabaseHandle.Size))
      print(string.format("Inserted into database: time, thickness, error = %s, %.4f, %.4f", time, thickness, errorAbs))
    else
      print("Coult not insert data: " .. DatabaseHandle.insertStmt:getErrorMessage())
    end
    DatabaseHandle.insertStmt:reset()
  else print("Could not insert data into DB because statement is not pre-compiled") end
end

-- Gets values between two times: Main.MinTime, Main.MaxTime
function DatabaseHandle.Get(startDateTime, endDateTime)
  TimerHandle.Timer:stop()
  TimerHandle.measuringOn = 0
  assert(startDateTime <= endDateTime, "Start time > End time")
  local datetime = {}
  local thickness = {}
  if (DatabaseHandle.getStmt ~= nil) then
    DatabaseHandle.getStmt:bind(0, startDateTime, endDateTime)
    local timeStarted = DateTime.getTimestamp()
    local stepResult = DatabaseHandle.getStmt:step()
    if (stepResult == "DONE") then print("No results")
    elseif (stepResult == "ERROR") then print("Could not get data: " .. DatabaseHandle.getStmt:getErrorMessage())
    else
      local numEntries = 1
      while (stepResult == "ROW") do
        local result = DatabaseHandle.getStmt:getColumsForLuaTable()
        local loadFunction = load("return " .. result)
        local resultTable = loadFunction()
        table.insert(datetime, tonumber(resultTable["datetime"]))
        table.insert(thickness, resultTable["thickness"])
        stepResult = DatabaseHandle.getStmt:step()
        numEntries = numEntries + 1
      end
      if (stepResult == "ERROR") then print("Could not get data: " .. DatabaseHandle.getStmt:getErrorMessage()) end
      local timeEnded = DateTime.getTimestamp()
      Script.notifyEvent('UpdateSQLExecTimeDisplay', string.format("SQL Get query took %ss to process %s entries", tostring((timeEnded - timeStarted) / 1000), tostring(numEntries)))
      Viewer.Present(datetime, thickness)
    end
    DatabaseHandle.getStmt:reset()
  else print("Could not get data into DB because statement is not pre-compiled") end
  TimerHandle.Timer:start()
  TimerHandle.measuringOn = 1
end

local function OnResetDatabaseSubmit()
  TimerHandle.Timer:stop() 
  TimerHandle.measuringOn = 0
  DatabaseHandle.db = nil
  DatabaseHandle.Initialised = false
  if File.del("/sdcard/0/database/SIM.API.Test.db") then print("Database deleted") end
  if DatabaseHandle.DatabaseExists() and DatabaseHandle.DatabaseInitialised() and DatabaseHandle.InitialiseStatements() then
    DatabaseHandle.Initialised = true
    TimerHandle.Timer:start() 
    TimerHandle.measuringOn = 1
  else DatabaseHandle.Initialised = false end
end
Script.serveFunction("DT35ThicknessDifferential.OnResetDatabaseSubmit", OnResetDatabaseSubmit)

