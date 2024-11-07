Viewer = {}

Viewer.ViewerHistorical = View.create("ViewerHistorical")
Viewer.ViewerHistoricalDecoration = View.GraphDecoration.create()
Viewer.ViewerHistoricalDecoration:setYBounds(75, 120)
Viewer.ViewerHistoricalDecoration:setDrawSize(0.1)
Viewer.ViewerHistoricalDecoration:setLabels("Time", "Thickness")
-- Viewer.ViewerHistoricalDecoration:setLabelsVisible(false)

function Viewer.Present(times, thickness)
  Viewer.ViewerHistorical:clear()
  local title = "Between " .. DateTime.formatUnixTime(math.floor(times[1] / 1000)) .. " and " .. DateTime.formatUnixTime(math.floor(times[#times] / 1000))
  local minTime = times[1] - 100
  for key, time in pairs(times) do
    times[key] = (time - minTime) / 1000
  end
  Viewer.ViewerHistoricalDecoration:setTitle(title)
  Viewer.ViewerHistorical:addGraph(thickness, times, Viewer.ViewerHistoricalDecoration)
  Viewer.ViewerHistorical:present()
end