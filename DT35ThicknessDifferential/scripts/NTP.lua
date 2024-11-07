NTP = {}
NTP.NTPClient = NTPClient.create()
NTP.NTPClient:setApplyEnabled(true)
NTP.NTPClient:setInterface("ETH1")
NTP.NTPClient:setPeriodicUpdateEnabled(true)
NTP.NTPClient:setServerAddress("192.168.1.2")
NTP.NTPClient:setServerPort(123)
NTP.NTPClient:setTimeSource('NTP')
NTP.NTPClient:startManualRequest()