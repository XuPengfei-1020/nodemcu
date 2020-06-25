wifiStatus={}
-- reset ap config
function wifiStatus:setAP(ssid, pass)
    local ap_cfg={}
    ap_cfg.ssid=ssid
    ap_cfg.pwd=pass
    wifi.ap.config(ap_cfg)
end

-- connect new wifi, and remember it
function wifiStatus:setWifi(ssid, pass)
    local station_cfg={}
    station_cfg.ssid=ssid
    station_cfg.pwd=pass
    station_cfg.save=true
    wifi.sta.config(station_cfg)
end

function wifiStatus:getStatus()
    -- station
    local mode=wifi.getmode()
    local st_ssid, st_pass, bssid_set, bssid=wifi.sta.getconfig()
    local st_ip=wifi.sta.getip()
    if (st_ip==nil) then st_ip='lose connect' end;

    --ap
    local ap_ssid, ap_pass=wifi.ap.getconfig()
    local ap_ip = wifi.ap.getip()
    local clients=wifi.ap.getclient()

    local clientStr='[';
    for mac,ip in pairs(clients) do
        clientStr=clientStr..string.format('{"mac": "%s", "ip": "%s"}', mac, ip)
    end
    clientStr=clientStr..']'
    
    return string.format('{"mode": %s, "st": {"ssid": "%s", "pass": "%s", "ip": "%s"}, "ap":{"ssid": "%s", "ip": "%s", "clients": %s}}', 
        mode, st_ssid, st_pass, st_ip, ap_ssid, ap_ip, clientStr);
end

--tests
print(wifiStatus:getStatus())