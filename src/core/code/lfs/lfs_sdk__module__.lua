-- Serving static files

require 'gpioctl'
require 'wificfg'
require 'http_server'

print(sjson.encode(wificfg:cfgwifi()))
httpServer:listen(80)

-- favorite.com
httpServer:use('/favicon.ico', function(req, res)
	res:sendFile('IOT_32px-min.png')
end)

-- gpioctl
httpServer:use('/gpioctl', function(req, res)
	res:type('application/json')
	local body = req.body
	if body == nil then
		res:send(sjson.encode({code = -1, msg = 'Request body is nil (Please post me.)'}))
		return
	end

	if #body > 1024 then
		res:send(sjson.encode({code = -1, msg = 'Request body is too large( < 1024).'}))
		return
	end

	local ok, cmd = pcall(sjson.decode, body)

	if not ok then
		res:send(sjson.encode({code = -1, msg = string.format('Request body is invalid (not well json format), body:%s', body)}))
		return
	end

	local ok, rs = pcall(function () return gpioctl:cmdasync(cmd, true, false) end)
	if not ok then
		res:send(sjson.encode({code = -1, msg = string.format('internal error. %s', rs)}))
	end

	res:send(sjson.encode(rs))
end)

-- set wifi
httpServer:use('/wifi_st_config', function(req, res)
	res:type('application/json')
	local ssid = req.query.ssid
	local pass = req.query.pass
	if ssid == nil or #ssid == 0 then
		res:send(sjson.encode({code = -1, msg = 'ssid can not be empty'}))
		return
	end	
	
	local save = wificfg:savecfg({ssid = ssid, pwd = pass, save = true})
	if save.code == -1 then
		res:send(sjson.encode(save))
		return
	end

	res:send(sjson.encode(wificfg:cfgwifi()))
end)

-- Get status
httpServer:use('/wifi_status', function(req, res)
	res:type('application/json')
	res:send(sjson.encode(wificfg:getstatus()))
end)

-- 闪烁工作指示灯
local wkled = tmr.create()
wkled:register(10000, tmr.ALARM_AUTO, function()
	gpio.mode(4, gpio.OUTPUT)
	tmr.delay(50*1000)
	gpio.mode(4, gpio.INPUT)
	tmr.delay(100*1000)
	gpio.mode(4, gpio.OUTPUT)
	tmr.delay(50*1000)
	gpio.mode(4, gpio.INPUT)
end)
wkled:interval(SDK_CFG and SDK_CFG.led_blink or 10000)
wkled:start()