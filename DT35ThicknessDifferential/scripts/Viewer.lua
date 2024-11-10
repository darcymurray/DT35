Viewer = {}

Viewer.ViewerHistorical = View.create("ViewerHistorical")
Viewer.ViewerHistoricalDecoration = View.GraphDecoration.create()
Viewer.ViewerHistoricalDecoration:setYBounds(75, 120)
Viewer.ViewerHistoricalDecoration:setDrawSize(0.1)
Viewer.ViewerHistoricalDecoration:setLabels("Time", "Thickness")
Viewer.ViewerHistoricalDecoration:setLabelsVisible(false)

local function presentPoints(times, thickness)
  local title = "Between " .. DateTime.formatUnixTime(math.floor(times[1] / 1000)) .. " and " .. DateTime.formatUnixTime(math.floor(times[#times] / 1000))
  local minTime = times[1] - 100
  for key, time in pairs(times) do times[key] = (time - minTime) / 1000 end
  Viewer.ViewerHistoricalDecoration:setTitle(title)
  Viewer.ViewerHistorical:addGraph(thickness, times, Viewer.ViewerHistoricalDecoration)
end

local function getStringFromUnixTime(unixTime, unit)
  local day, month, year, hour, minute, second = DateTime.convertUnixTime(unixTime)
  
end

local function presentTimeLabels(times)
  local minTime = times[1]
  local maxTime = times[#times]
  local unixTimeRange = maxTime - minTime
  local xLabelUnit
  local numLabels = 6
  if unixTimeRange <= 180000 then -- <=3m
    xLabelUnit = "seconds"
  elseif unixTimeRange <= 1080000 then -- <=3h
    xLabelUnit = "minutes"
  else -- >3h
    xLabelUnit = "hours"
  end
  local increment = math.ceil(unixTimeRange / numLabels)
  local timeLabels = {}
  local xValues = {}
  for _, value in pairs(numLabels) do
    local unixTime = minTime + (increment * value)
    table.insert(xValues, unixTime)
    local stringTimeLabel = getStringFromUnixTime(unixTime, xLabelUnit)
    table.insert(timeLabels, stringTimeLabel)
  end

  for key, value in pairs(timeLabels) do
    local textDecoration = View.TextDecoration.create()
    textDecoration:setPosition(xValues[key], -10)
    Viewer.ViewerHistorical:addText(value, textDecoration)
  end
  
  -- 4 labels/strings
  -- time range
  -- 4 coords
end

local function presentThicknessLabels(times)

end

function Viewer.Present(times, thickness)
  Viewer.ViewerHistorical:clear()
  presentPoints(times, thickness) -- Normalises times and converts to seconds
  presentTimeLabels(times)
  presentThicknessLabels(thickness)
  Viewer.ViewerHistorical:present()
end

function Viewer.UpdateViewerHistoricalDisplay()
  Script.notifyEvent('UpdateStartDateDisplay', TimerHandle.StartDateString)
  Script.notifyEvent('UpdateEndDateDisplay', TimerHandle.EndDateString)
  Script.notifyEvent('UpdateStartTimeDisplay', TimerHandle.StartTimeString)
  Script.notifyEvent('UpdateEndTimeDisplay', TimerHandle.EndTimeString)
  Script.notifyEvent('UpdateStartDateTimeDisplay', string.format("%s %s", TimerHandle.StartDateString, TimerHandle.StartTimeString))
  Script.notifyEvent('UpdateEndDateTimeDisplay', string.format("%s %s", TimerHandle.EndDateString, TimerHandle.EndTimeString))
end
Viewer.ViewerHistorical:register('OnConnect', Viewer.UpdateViewerHistoricalDisplay)

