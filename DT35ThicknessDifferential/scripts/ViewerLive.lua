ViewerLive = {}

ViewerLive.ThicknessViewer = View.create("ViewerThicknessLive")
ViewerLive.ThicknessViewerDecoration = View.GraphDecoration.create()
ViewerLive.ThicknessViewerDecoration:setYBounds(67.85, 67.95)
-- ViewerLive.ThicknessViewerDecoration:setDrawSize(0.1)
-- ViewerLive.ThicknessViewerDecoration:setDynamicSizing(false)
ViewerLive.ThicknessViewerDecoration:setLabels("Time (s)", "Thickness (mm)")

ViewerLive.ErrorViewer = View.create("ViewerErrorLive")
ViewerLive.ErrorViewerDecoration = View.GraphDecoration.create()
-- ViewerLive.ErrorViewerDecoration:setYBounds(0, 0.25)
-- ViewerLive.ErrorViewerDecoration:setDrawSize(0.1)
-- ViewerLive.ErrorViewerDecoration:setDynamicSizing(false)
ViewerLive.ErrorViewerDecoration:setLabels("Time (s)", "Error (mm)")

ViewerLive.MaximumLivePoints = Main.ViewerLiveDurationSeconds / (Main.TimerExpirationTime / 1000)
ViewerLive.FirstTick = true

ViewerLive.Time = {}
ViewerLive.Thickness = {}
ViewerLive.Error = {}
ErrorMin = 100
ErrorMax = 0
ErrorRange = 100
Script.serveEvent('DT35ThicknessDifferential.UpdateErrorRangeDisplay', 'UpdateErrorRangeDisplay')

function ViewerLive.DisplayData(time, thickness, readingError)
  if readingError > ErrorMax then ErrorMax = readingError end
  if readingError < ErrorMin then ErrorMin = readingError end
  ErrorRange = ErrorMax - ErrorMin
  Script.notifyEvent('UpdateErrorRangeDisplay', string.format("%.5f", ErrorRange))

  if (#ViewerLive.Time >= ViewerLive.MaximumLivePoints) then
    table.remove(ViewerLive.Time, 1)
    table.remove(ViewerLive.Thickness, 1)
    table.remove(ViewerLive.Error, 1)
  end

  if ViewerLive.FirstTick == true then
    ViewerLive.Offset = time
    ViewerLive.FirstTick = nil
  end

  table.insert(ViewerLive.Time, (time - ViewerLive.Offset) / 1000)
  table.insert(ViewerLive.Thickness, thickness)
  table.insert(ViewerLive.Error, readingError)

  ViewerLive.ThicknessViewer:clear()
  ViewerLive.ThicknessViewer:addGraph(ViewerLive.Thickness, ViewerLive.Time, ViewerLive.ThicknessViewerDecoration)
  ViewerLive.ThicknessViewer:present()

  ViewerLive.ErrorViewer:clear()
  ViewerLive.ErrorViewer:addGraph(ViewerLive.Error, ViewerLive.Time, ViewerLive.ErrorViewerDecoration)
  ViewerLive.ErrorViewer:present()
end