PowerA = Connector.Power.create('S1')
PowerB = Connector.Power.create('S2')
PowerA:enable(true)
PowerB:enable(true)
IOLinkDT35A = IOLink.RemoteDevice.create('S1')
IOLinkDT35B = IOLink.RemoteDevice.create('S2')
DeviceFunctions = {}

function DeviceFunctions.ReadIOLinkSpecificData(device)
  local indicies = {vendorName = 16, vendorText = 17, productName = 18, productID = 19, serialNumber = 21, appSpecificName = 24, userTagA = 84, userTagB = 85, processData = 40}

  local vendorName      = device:readData(indicies["vendorName"], 0)
  local vendorText      = device:readData(indicies["vendorText"], 0)
  local productName     = device:readData(indicies["productName"], 0)
  local productID       = device:readData(indicies["productID"], 0)
  local serialNumber    = device:readData(indicies["serialNumber"], 0)
  local appSpecificName = device:readData(indicies["appSpecificName"], 0)
  local userTagA        = device:readData(indicies["userTagA"], 0)
  local userTagB        = device:readData(indicies["userTagB"], 0)
  local processData     = device:readData(indicies["processData"], 0)

  print("Current vendorName value: " .. vendorName)
  print("Current vendorText value: " .. vendorText)
  print("Current productName value: " .. productName)
  print("Current productID value: " .. productID)
  print("Current serialNumber value: " .. serialNumber)
  print("Current appSpecificName value: " .. appSpecificName .. " (writeable)")
  print("Current userTagA value: " .. string.unpack("I4", userTagA) .. " (writeable)")
  print("Current userTagB value: " .. string.unpack("I2", userTagB) .. " (writeable)")
  print("Current processData value: " .. string.unpack("I2", processData))
end

function DeviceFunctions.ReadOutputSettings(device)
  local indicies = {}
end

function DeviceFunctions.ReadSensorPerformanceSettings(device)
  local indicies = {responseTime = 103, integrationTime = 64, averaging = 67, bitFilter = 66}

  local responseTime = device:readData(indicies["responseTime"], 0)
  local integrationTime = device:readData(indicies["integrationTime"], 0)
  local averaging = device:readData(indicies["averaging"], 0)
  local bitFilter = device:readData(indicies["bitFilter"], 0)

  print("Current responseTime value: " .. string.unpack("I1", responseTime) .. " (writeable)")
  print("Current integrationTime value: " .. string.unpack("I1", integrationTime) .. " (writeable)")
  print("Current averaging value: " .. string.unpack("I1", averaging) .. " (writeable)")
  print("Current bitFilter value: " .. string.unpack("I1", bitFilter) .. " (writeable)")
end

function DeviceFunctions.ReadProcessDataSettings(device)
  local indicies = {structure = 83, resolution = 105, normalisation = 107}

  local structure,     _ = device:readData(indicies["structure"], 0)
  local resolution,    _ = device:readData(indicies["resolution"], 0)
  local normalisation, _ = device:readData(indicies["normalisation"], 0)

  print("Current structure value: "     .. string.unpack("I1", structure)     .. " (writeable)")
  print("Current resolution value: "    .. string.unpack("I1", resolution)    .. " (writeable)")
  print("Current normalisation value: " .. string.unpack("I2", normalisation) .. " (writeable)")
end

function DeviceFunctions.ReadOtherSettings(device)
  local indicies = {mfFunction = 81, mfLevel = 99, alarmFunction = 104, pushButtonLock = 82, laserStatus = 68}
  
  local mfFunction, _ = device:readData(indicies["mfFunction"], 0)
  local mfLevel, _ = device:readData(indicies["mfLevel"], 0)
  local alarmFunction, _ = device:readData(indicies["alarmFunction"], 0)
  local pushButtonLock, _ = device:readData(indicies["pushButtonLock"], 0)
  local laserStatus, _ = device:readData(indicies["laserStatus"], 0)

  print("Current mfFunction value: " .. string.unpack("I1", mfFunction) .. " (writeable)")
  print("Current mfLevel value: " .. string.unpack("I1", mfLevel) .. " (writeable)")
  print("Current alarmFunction value: " .. string.unpack("I1", alarmFunction) .. " (writeable)")
  print("Current pushButtonLock value: " .. string.unpack("I1", pushButtonLock) .. " (writeable)")
  print("Current laserStatus value: " .. string.unpack("I1", laserStatus) .. " (writeable)")
end

function DeviceFunctions.FactoryReset(device)
  print("Factory reset status: " .. device:writeData(2, 0, "\x82"))
end

function DeviceFunctions.Teach(device, num) -- 0 <= num <= 16
  print("Teach status: " .. device:writeData(130, 0, string.pack("I2", num)))
end

