Viewer = {}

Viewer.ViewerHistorical = View.create("ViewerHistorical")
Viewer.ViewerHistoricalDecoration = View.GraphDecoration.create()
-- Viewer.ViewerHistoricalDecoration:setYBounds(80, 120)
Viewer.ViewerHistoricalDecoration:setLabels("Time", "Thickness")
Viewer.ViewerHistoricalDecoration:setLabelsVisible(false)

local function presentPoints(times, thickness)
  local title = "Between " .. DateTime.formatUnixTime(math.floor(times[1] / 1000)) .. " and " .. DateTime.formatUnixTime(math.floor(times[#times] / 1000))
  local minTime = times[1] - 100
  for key, time in pairs(times) do times[key] = (time - minTime) / 1000 end
  Viewer.ViewerHistoricalDecoration:setDrawSize(#times / 7000)
  Viewer.ViewerHistoricalDecoration:setTitle(title)
  Viewer.ViewerHistorical:addGraph(thickness, times, Viewer.ViewerHistoricalDecoration)
end

local function getStringFromUnixTime(unixTime)
  local day, month, year, hour, minute, second = DateTime.convertUnixTime(unixTime)
  local meridiem = hour <= 12
  local meridiemStr
  if meridiem == true then meridiemStr = "AM"
  else hour = hour - 12 meridiemStr = "PM" end
  local result = string.format("%02d:%02d:%02d %s", hour, minute, second, meridiemStr)
  return result
end

local function getTimeLabels(times)
  local numLabels = 6
  local minTime = math.floor(times[1] / 1000)
  local maxTime = math.ceil(times[#times] / 1000)
  local unixTimeRange = maxTime - minTime
  local increment = math.ceil(unixTimeRange / (numLabels))

  local timeLabels = {}
  for i = 1, numLabels, 1 do
    local unixTime = minTime + (increment * i)
    table.insert(timeLabels, getStringFromUnixTime(unixTime))
  end

  return timeLabels
end

local function presentTimeLabels(times, timeLabels)
  local numLabels = 6
  local minTime = times[1]
  local maxTime = times[#times]
  local unixTimeRange = maxTime - minTime
  local increment = math.ceil(unixTimeRange / (numLabels))

  local xValues = {}
  for i = 1, numLabels, 1 do
    local unixTime = minTime + (increment * i)
    table.insert(xValues, unixTime)
  end

  local textDecoration = View.TextDecoration.create()
  textDecoration:setSize(10)
  textDecoration:setColor(0,0,0)
  textDecoration:setHorizontalAlignment("CENTER")
  textDecoration:setVerticalAlignment("CENTER")
  for key, label in pairs(timeLabels) do
    textDecoration:setPosition(xValues[key], 77.5)
    Viewer.ViewerHistorical:addText(label, textDecoration)
  end
end

local function presentThicknessLabels()
  local numLabels = 8
  local min = 0
  local max = 80
  local unixTimeRange = max - min
  local increment = unixTimeRange / numLabels

  local textDecoration = View.TextDecoration.create()
  textDecoration:setSize(10)
  textDecoration:setColor(0,0,0)
  textDecoration:setHorizontalAlignment("CENTER")
  textDecoration:setVerticalAlignment("CENTER")

  for i = 1, numLabels, 1 do
    local y = min + (increment * i)
    textDecoration:setPosition(-1.25, y - 0.25)
    Viewer.ViewerHistorical:addText(string.format("%0d", y), textDecoration)
  end
end

function Viewer.Present(times, thickness)
  Viewer.ViewerHistorical:clear()
  local timeLabels = getTimeLabels(times)
  presentPoints(times, thickness) -- Normalises times and converts to seconds
  presentTimeLabels(times, timeLabels)
  presentThicknessLabels()
  Viewer.ViewerHistorical:present()
end

function Viewer.UpdateViewerHistoricalDisplay()
  Script.notifyEvent('UpdateStartDateDisplay', TimerHandle.StartDateString)
  Script.notifyEvent('UpdateEndDateDisplay', TimerHandle.EndDateString)
  Script.notifyEvent('UpdateStartTimeDisplay', TimerHandle.StartTimeString)
  Script.notifyEvent('UpdateEndTimeDisplay', TimerHandle.EndTimeString)
  -- Script.notifyEvent('UpdateStartDateTimeDisplay', string.format("%s %s (%s)", TimerHandle.StartDateString, TimerHandle.StartTimeString, TimerHandle.StartDate + TimerHandle.StartTime))
  -- Script.notifyEvent('UpdateEndDateTimeDisplay', string.format("%s %s (%s)", TimerHandle.EndDateString, TimerHandle.EndTimeString, TimerHandle.EndDate + TimerHandle.EndTime))
  Script.notifyEvent('UpdateStartDateTimeDisplay', string.format("%s %s", TimerHandle.StartDateString, TimerHandle.StartTimeString))
  Script.notifyEvent('UpdateEndDateTimeDisplay', string.format("%s %s", TimerHandle.EndDateString, TimerHandle.EndTimeString))
end
Viewer.ViewerHistorical:register('OnConnect', Viewer.UpdateViewerHistoricalDisplay)

