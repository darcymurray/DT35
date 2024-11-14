Device = {}
Device.PowerA = Connector.Power.create('S1')
Device.PowerB = Connector.Power.create('S2')
Device.IOLinkA = IOLink.RemoteDevice.create('S1')
Device.IOLinkB = IOLink.RemoteDevice.create('S2')
Device.ConnectedDevices = 0
Device.Timer = Timer.create()
Device.Timer:setPeriodic(true)
Device.Timer:setExpirationTime(1000)
Device.Timer:start()

local function handleOnConnected()
  print('IO-Link device OD1000 connected')
  Device.ConnectedDevices = Device.ConnectedDevices + 1

  -- local data = string.pack("c32", "test application tag")
  -- print(Device.IOLinkA:writeData(24, 0, data))
  -- local dataRead, _ = Device.IOLinkA:readData(24, 0)
  -- print(dataRead)

end
IOLink.RemoteDevice.register(Device.IOLinkA, 'OnConnected', handleOnConnected)
IOLink.RemoteDevice.register(Device.IOLinkB, 'OnConnected', handleOnConnected)

function Device.HandleOnExpired()
  if (Device.ConnectedDevices == Main.NumDevices) then Device.Timer = nil end
end

