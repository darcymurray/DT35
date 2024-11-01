require("FileUtils")
CSV = CSV or {}


CSV.CsvWriter = {
  mt = {}
}
CSV.CsvWriter.mt.__index = CSV.CsvWriter
--[[
  Generates a string representing a CSV row from the table given.

  Params:
    tbl:table -- The table for which to generate the CSV row
  Returns:
    rowString:string -- The generated CSV row string

  Author: Adrian Forbes
]]
function CSV.CsvWriter._generateRowString(tbl)
  local rowString = ''

  for i, item in ipairs(tbl) do
    if i ~= 1 then
      rowString = rowString..","
    end

    if type(item) == 'string' then
      if string.match(item, ",") then -- Enclose the string in double quotes if it has any commas inside
        rowString = rowString.."\""..item.."\""
      else
        rowString = rowString..item
      end
    elseif type(item) == 'number' then
      rowString = rowString..tostring(item)
    else
      -- Don't append anything to the string if unknown type.
      -- This entry will be blank.
    end
  end

  rowString = rowString.."\n"

  return rowString
end

function CSV.CsvWriter.create(path)
  local o = {
    path=path
  }
  setmetatable(o, CSV.CsvWriter.mt)

  -- Create file (or truncate if already exists)
  local success, file = FileUtils.createFile(path, "w", true, true)
  if not success then
    error(string.format("Could not create file at path %s", path))
  end

  return o
end

--[[
  Appends the contents of a 1D table containing numbers/strings to the CSV file at the path given.
  A single row is appended. Returns true if successful, false otherwise.

  Params:
    tbl:table           -- The table to append
  Returns:
    success:bool -- Whether the write operation was successful

  Author: Adrian Forbes
]]
function CSV.CsvWriter:writeRow(tbl)
  local success = false

  if self.path == nil then
    success = false
  else
    local file = File.open(self.path, "a")

    if file then
      -- Generate the string to append from the table provided
      local appendString = CSV.CsvWriter._generateRowString(tbl)
      success = file:write(appendString)

      file:close()
    else
      success = false
    end
  end

  return success
end

function CSV.CsvWriter:getPath()
  return self.path
end

