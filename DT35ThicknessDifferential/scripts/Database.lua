DatabaseHandle = {}

local dbFileName = "public/SIM.API.Test.Empty.db"
local dbSetupFileName = "public/testDbSchema.sql.txt"

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

-- local function setupDb()
--   local f = File.open(dbSetupFileName, "rb")
--   if f ~= nil then
--     local content = f:read()
--     f:close()
--     print("Database schema setup: " .. tostring(DatabaseHandle.db:execute(content)))
--   end
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

-- Inserts dataset into the database
function DatabaseHandle.Insert(time, thickness)
  if (DatabaseHandle.insertStmt ~= nil) then
    DatabaseHandle.insertStmt:bind(0, DatabaseHandle.nextId, time, thickness)
    
    if (DatabaseHandle.insertStmt:step() == "DONE") then
      DatabaseHandle.nextId = DatabaseHandle.nextId + 1
      print("OK")
    else
      print("Coult not insert data: " .. DatabaseHandle.insertStmt:getErrorMessage())
    end

    DatabaseHandle.insertStmt:reset()
  else print("Could not insert data into DB because statement is not pre-compiled") end
end

local function assertParametersValid()
  assert(Main.MinTime <= Main.MaxTime, "Main.MinTime > Main.MaxTime")
  assert(string.match(Main.MinTime, "^%d%d:%d%d:%d%d%.%d%d%d$") ~= nil, "Main.MinTime invalid format")
  assert(string.match(Main.MaxTime, "^%d%d:%d%d:%d%d%.%d%d%d$") ~= nil, "Main.MaxTime invalid format")
end

-- Gets values between two times: Main.MinTime, Main.MaxTime
function DatabaseHandle.Get()
  assertParametersValid()
  if (DatabaseHandle.getStmt ~= nil) then
    DatabaseHandle.getStmt:bind(0, Main.MinTime, Main.MaxTime)
    local stepResult = DatabaseHandle.getStmt:step()

    if (stepResult == "DONE") then print("No results")
    elseif (stepResult == "ERROR") then print("Could not get data: " .. DatabaseHandle.getStmt:getErrorMessage())
    else
      local str = DatabaseHandle.getStmt:getColumnsAsString()
      stepResult = DatabaseHandle.getStmt:step()
      while (stepResult == "ROW") do
        str = str .. "\r\n" .. DatabaseHandle.getStmt:getColumnsAsString()
        stepResult = DatabaseHandle.getStmt:step()
      end
      if (stepResult == "ERROR") then print("Could not get data: " .. DatabaseHandle.getStmt:getErrorMessage()) end
      print(str)
    end

    DatabaseHandle.getStmt:reset()
  else print("Could not get data into DB because statement is not pre-compiled") end
end

local function main()
  -- Init
  DatabaseHandle.db = Database.SQL.SQLite.create()
  print("Database connection status: " .. tostring(DatabaseHandle.db:openFile(dbFileName, "READ_WRITE_CREATE")))
  print("Database SQLite version: " .. DatabaseHandle.db:getVersion())

  -- Setup
  -- setupDb()

  -- Test query
  -- DatabaseHandle.ListDb()

  -- Get next Id to insert
  local nextIdStatement = DatabaseHandle.db:prepare("select case when max(Id) is null then 1 else max(Id) + 1 end from measurements")
  assert(nextIdStatement ~= nil, "ERROR: nextIdStatement is null")
  nextIdStatement:step()
  DatabaseHandle.nextId = nextIdStatement:getColumnInt(0)

  -- Insert statement
  DatabaseHandle.insertStmt = DatabaseHandle.db:prepare("insert into measurements values(?,?,?)")
  if (DatabaseHandle.insertStmt == nil) then print("Error: " .. DatabaseHandle.db:getErrorMessage()) end

  -- Max Id
  -- DatabaseHandle.selectMaxIdStmt = DatabaseHandle.db:prepare("select max(Id) from measurements")
  -- if (DatabaseHandle.selectMaxIdStmt == nil) then print("Error: " .. DatabaseHandle.db:getErrorMessage()) end

  -- Get statement
  DatabaseHandle.getStmt = DatabaseHandle.db:prepare("select * from measurements where (datetime >= ? and datetime <= ?);")
  if (DatabaseHandle.getStmt == nil) then print("Error: " .. DatabaseHandle.db:getErrorMessage()) end
end

main()

