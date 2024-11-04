DatabaseHandle = {}
local dbFileName = "/sdcard/0/database/SIM.API.Test.db"

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

local function databaseExists()
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

local function databaseInitialised()
  -- Init
  DatabaseHandle.db = Database.SQL.SQLite.create()
  print("Database connection status: " .. tostring(DatabaseHandle.db:openFile(dbFileName, "READ_WRITE_CREATE")))
  print("Database SQLite version: " .. DatabaseHandle.db:getVersion())

  -- Schema
  local testStatement = DatabaseHandle.db:prepare("select * from measurements")
  if testStatement == nil then
    local initSchemaStatement = DatabaseHandle.db:prepare("CREATE TABLE measurements (Id INTEGER PRIMARY KEY AUTOINCREMENT, datetime TEXT NOT NULL, thickness REAL);")
    if initSchemaStatement:step() == "DONE" then print("Database schema created") return true
    else print("Failed to create database schema") return false end
  -- setupDb()
  else return true
  end
end

local function initialiseStatements()
  -- Next Id
  local nextIdStatement = DatabaseHandle.db:prepare("select case when max(Id) is null then 1 else max(Id) + 1 end from measurements")
  assert(nextIdStatement ~= nil, "ERROR: nextIdStatement is null")
  nextIdStatement:step()
  DatabaseHandle.nextId = nextIdStatement:getColumnInt(0)
  nextIdStatement = nil

  -- Insert statement
  DatabaseHandle.insertStmt = DatabaseHandle.db:prepare("insert into measurements values(?,?,?)")
  if (DatabaseHandle.insertStmt == nil) then print("Error: " .. DatabaseHandle.db:getErrorMessage()) end

  -- Get statement
  DatabaseHandle.getStmt = DatabaseHandle.db:prepare("select * from measurements where (datetime >= ? and datetime <= ?);")
  if (DatabaseHandle.getStmt == nil) then print("Error: " .. DatabaseHandle.db:getErrorMessage()) end

  return true
end

-- Inserts dataset into the database
function DatabaseHandle.Insert(time, thickness)
  if (DatabaseHandle.insertStmt ~= nil) then
    DatabaseHandle.insertStmt:bind(0, DatabaseHandle.nextId, time, thickness)
    if (DatabaseHandle.insertStmt:step() == "DONE") then
      DatabaseHandle.nextId = DatabaseHandle.nextId + 1
      print(string.format("Inserted into database. Time: " .. time .. ", thickness: " .. thickness))
    else
      print("Coult not insert data: " .. DatabaseHandle.insertStmt:getErrorMessage())
    end
    DatabaseHandle.insertStmt:reset()
  else print("Could not insert data into DB because statement is not pre-compiled") end
end

-- Gets values between two times: Main.MinTime, Main.MaxTime
function DatabaseHandle.Get()
  Timer:stop() Main.timerOn = 0
  assert(Main.MinTime <= Main.MaxTime, "Main.MinTime > Main.MaxTime")
  -- assert(string.match(Main.MinTime, "^%d%d:%d%d:%d%d%.%d%d%d$") ~= nil, "Main.MinTime invalid format")
  -- assert(string.match(Main.MaxTime, "^%d%d:%d%d:%d%d%.%d%d%d$") ~= nil, "Main.MaxTime invalid format")
  local timeStarted = DateTime.getTimestamp()
  if (DatabaseHandle.getStmt ~= nil) then
    DatabaseHandle.getStmt:bind(0, Main.MinTime, Main.MaxTime)
    local stepResult = DatabaseHandle.getStmt:step()
    if (stepResult == "DONE") then print("No results")
    elseif (stepResult == "ERROR") then print("Could not get data: " .. DatabaseHandle.getStmt:getErrorMessage())
    else
      local str = DatabaseHandle.getStmt:getColumnsAsString()
      stepResult = DatabaseHandle.getStmt:step()
      local numEntries = 1
      while (stepResult == "ROW") do
        str = str .. "\r\n" .. DatabaseHandle.getStmt:getColumnsAsString()
        stepResult = DatabaseHandle.getStmt:step()
        numEntries = numEntries + 1
      end
      if (stepResult == "ERROR") then print("Could not get data: " .. DatabaseHandle.getStmt:getErrorMessage()) end
      
      -- for line in string.gmatch(str, "[^\r\n]+") do
      --   local integer, datetime, measurement = string.match(line, "(%d+)%s*|%s*%'(%d%d%d%d%-%d%d%-%d%dT%d%d:%d%d:%d%d%.%d%d%dZ)%'%s*|%s*(%d+%.%d+)")
      --   print(string.format("%-3s | %-20s | %-10s", integer, datetime, measurement))
      -- end
        
      local timeEnded = DateTime.getTimestamp()
      print(string.format("SQL Get query took %ss to process %s entries", tostring((timeEnded - timeStarted) / 1000), tostring(numEntries)))
    end
    DatabaseHandle.getStmt:reset()
  else print("Could not get data into DB because statement is not pre-compiled") end
end

local function main()
  if databaseExists() and databaseInitialised() and initialiseStatements() then DatabaseHandle.Initialised = true
  else DatabaseHandle.Initialised = false end
end

main()


Script.serveEvent('DT35ThicknessDifferential.UpdateNumEntriesDisplay', 'UpdateNumEntriesDisplay')
