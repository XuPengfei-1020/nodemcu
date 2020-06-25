-- Serving static files
dofile('gpioCtl.lc')
dofile('door.lc')
dofile('wifi.lc')
dofile('http_server.lc')

httpServer:listen(80)

-- favorite.com
httpServer:use('/favicon.ico', function(req, res)
	res:sendFile('IOT_32px-min.png')
end)

httpServer:use('/gpioCtl', function(req, res)
	if req.method ~= 'POST' then
		res:send('Please post me.')
		return
	end

	local body = req.body
	if body == nil then
		res:send('Request body is nil.')
		return
	end

	if #body > 1024 then
		res:send('Request body is too large.')
		return
	end

	local ok, cmd = pcall(sjson.decode, body)
	print('ok:', ok)
	print('cmd:', cmd)

	if not ok then
		res:send(string.format('Request body is invalid (not well json format), body:%s' .. body))
		return
	end

	print('gpioCtl execute')
	local rs = gpioCtl:cmd(cmd, false, true)
	print('type:', type(rs))
	print(rs)
	res:send(sjson.encode(rs))
end)

-- test
httpServer:use('/test', function(req, res)
	for k, v in pairs(req.query) do
		print(k, ':', v)
	end

	print('apptype:', req.apptype)
	print('body:', req.body)
	res:send(req.ip)
end)

-- Custom API
httpServer:use('/config', function(req, res)
	res:sendFile('config.html')
end)

-- set wifi
httpServer:use('/wifi_st_config', function(req, res)
	res:type('application/json')
	res:send(wifiStatus:getStatus())
end)

-- Get status
httpServer:use('/wifi_status', function(req, res)
	res:type('application/json')
	res:send(wifiStatus:getStatus())
end)

-- open the door
httpServer:use('/open_the_door', function(req, res)
	door:open_door()
	res:type('application/json')
	res:send('{"door": "open"}')
end)

-- hang up the door
httpServer:use('/hang_up', function(req, res)
	door:hang_up()
	res:type('application/json')
	res:send('{"door": "hang_up"}')
end)