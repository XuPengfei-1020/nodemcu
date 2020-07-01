wificfg = {}
local filename = 'wifi.cfg'

-- load wifi cfg
function wificfg:cfgwifi()
    local fd = file.open(filename, 'r');
    if not fd then
        local ssid = 'ESP-8266-'..node.chipid()
        wifi.ap.config({ssid = ssid, pwd = ssid..'!'})
        return {code = -1, msg = 'cfg file open failed, exists?'}
    end

    local content = fd:read()
    fd:close()
    print('load config:', content)
    local ok, config = pcall(sjson.decode, content)

    if not ok then
		return {code = -1, msg = 'parse json failed, cfg is invalid'}
    end

    if config.ap == nil or config.sta == nil then
        return {code = -1, msg = 'cfg has no ap nor sta'}
    end

    wifi.setmode(3, true)
    wifi.ap.config(config.ap)
    wifi.sta.config(config.sta)
    return {code = 0, msg = 'load cfg from '..filename}
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