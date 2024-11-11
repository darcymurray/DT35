ViewerLive = {}

ViewerLive.Viewer = View.create("ViewerLive")
ViewerLive.ViewerDecoration = View.GraphDecoration.create()
ViewerLive.ViewerDecoration:setYBounds(80, 120)
ViewerLive.ViewerDecoration:setDrawSize(0.1)
ViewerLive.ViewerDecoration:setLabels("Time", "Thickness")

ViewerLive.Time = {}
ViewerLive.Thickness = {}
ViewerLive.MaximumLivePoints = Main.ViewerLiveDurationSeconds / (Main.TimerExpirationTime / 1000)
ViewerLive.FirstTick = true

function ViewerLive.DisplayData(time, thickness)
  if (#ViewerLive.Thickness >= ViewerLive.MaximumLivePoints) then
    table.remove(ViewerLive.Time, 1)
    table.remove(ViewerLive.Thickness, 1)
  end

  if ViewerLive.FirstTick == true then
    ViewerLive.Offset = time
    ViewerLive.FirstTick = nil
  end
  table.insert(ViewerLive.Time, (time - ViewerLive.Offset) / 1000)
  table.insert(ViewerLive.Thickness, thickness)

  -- Temporarily Disabled
  -- ViewerLive.Viewer:clear()
  -- ViewerLive.Viewer:addGraph(ViewerLive.Thickness, ViewerLive.Time, ViewerLive.ViewerDecoration)
  -- ViewerLive.Viewer:present()
end