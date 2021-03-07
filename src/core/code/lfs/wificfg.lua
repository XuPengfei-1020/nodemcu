wificfg = {}
local filename = 'wifi.cfg'

-- load wifi cfg
function wificfg:cfgwifi()
    local fd = file.open(filename, 'r')
    local ap, sta
    if not fd then
        local ssid = 'ESP-8266-'..node.chipid()
        ap = {ssid = ssid, pwd = ssid..'!'}
        print('Wifi cfg file not exists?')
    else 
        local content = fd:read()
        fd:close()
        print('Load wifi  config:', content)
        local ok, config = pcall(sjson.decode, content)
        if not ok then
            print('Parse json failed, wifi cfg is invalid')
        end
    end

    wifi.setmode(sta == nil and 2 or 3, true)
    wifi.ap.config(config.ap or ap)
    if (sta ~= nil) then
        wifi.sta.config(config.sta)
    end

    return {code = 0, msg = 'Init wifi complete.'}
end

-- save wifi cfg
function wificfg:savecfg(sta, ap)
    if sta == nil then
        return {code = -1, msg = 'sta is nil'}
    end

    local ssid = 'ESP-8266-'..node.chipid()
    ap = ap or {ssid = ssid, pwd = ssid..'!'}
    file.putcontents(filename, sjson.encode({ap = ap, sta = sta}))
    return {code = 0}
end

function wificfg:getstatus()
    -- station
    local result = {mode = wifi.getmode()}
    local st_ssid, st_pass, _, _ = wifi.sta.getconfig()
    result.sta = {ssid = st_ssid, pass = st_pass, ip = wifi.sta.getip()}

    --ap
    local ap_ssid, ap_pass = wifi.ap.getconfig()
    local clients = wifi.ap.getclient()
    result.ap = {ssid = ap_ssid, pass = ap_pass, ip = wifi.ap.getip()}
    result.ap.clients = {}

    for mac,ip in pairs(clients) do
        result.ap.clients[#result.ap.clients] = {mac = mac, ip = ip}
    end
    
    return result;
end

return wificfg