DT = {}

-- DateTime.setDateTime(2024, 11, 11, 11, 10, 00, false) -- One Time
-- DateTime.setTimeZone("NZ")
-- print(DateTime.getTimeZone())
-- print(DateTime.getDateTime())
-- print(DateTime.getDateTimeValuesUTC())

local function isLeapYear(year)
  return (year % 4 == 0 and year % 100 ~= 0) or (year % 400 == 0)
end

local function daysInMonth(month, year)
  local days = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
  if month == 2 and isLeapYear(year) then return 29
  else return days[month] end
end

function DT.DateToUnixTimestamp(dateStr)
  local day, month, year = string.match(dateStr, "(%d%d)/(%d%d)/(%d%d%d%d)")
  if day == nil or month == nil or year == nil then return 0 end
  day, month, year = tonumber(day), tonumber(month), tonumber(year)

  -- years -> days
  local days = 0
  for y = 1970, year - 1 do
    days = days + (isLeapYear(y) and 366 or 365)
  end
  -- months -> days
  for m = 1, month - 1 do
    days = days + daysInMonth(m, year)
  end
  -- days -> days
  days = days + (day - 1)
  -- days -> seconds
  local timestamp = days * 86400

  return timestamp
end

function DT.DateToUnixMSTimestamp(dateStr)
  return DT.DateToUnixTimestamp(dateStr) * 1000
end

function DT.TimeToUnixTimestamp(timeStr)
  local hours, minutes, seconds = string.match(timeStr, "(%d%d)%:(%d%d)%:(%d%d)")
  if hours == nil or minutes == nil or seconds == nil then return 0 end
  hours, minutes, seconds = tonumber(hours), tonumber(minutes), tonumber(seconds)

  local timestamp = (3600 * hours) + (60 * minutes) + seconds

  return timestamp
end

function DT.TimeToUnixMSTimestamp(timeStr)
  return DT.TimeToUnixTimestamp(timeStr) * 1000
end

