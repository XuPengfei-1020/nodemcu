local cfg = {interval = 7000}
local detect_tmr =  tmr.create()
local filename = 'earth_water.cfg'

function load_or_def_cfg()
	local cfg_file = file.open(filename, 'r')
	if not cfg_file then
		return {interval = 7000}
	end

	local content = cfg_file:read()
    cfg_file:close()
    print('Load earth_water config:', content)
    local ok, config = pcall(sjson.decode, content)
	if ok then
		return config
	end
    print('Parse json failed, earth_water cfg is invalid')
end

-- save cfg
function savecfg(new_cfg)
	-- 更改 interval
	if new_cfg.adafruit then
		cfg.adafruit = new_cfg.adafruit
	end
	if new_cfg.interval then
		cfg.interval = new_cfg.interval
	end

	detect_tmr:interval(cfg.adafruit.interval)
    file.putcontents(filename, sjson.encode(cfg))
    return {code = 0}
end

-- 将土壤湿度上传到 adafurit 上去
local function upload_data(val)
	val = ('value=%d'):format(val)
	print(val)

	if not cfg.adafruit then
		print('No adafruit configed.')
		return
	end
	if not cfg.adafruit.url then
		print('No adafruit url configed.')
		return
	end
	if not cfg.adafruit.token then
		print('No adafruit token configed.')
		return
	end

	local url = cfg.adafruit.url .. '/data'
	local token = cfg.adafruit.token
	local header = 'Content-Type: application/x-www-form-urlencoded\r\nX-AIO-Key: ' .. token .. '\r\n'
	http.post(url, header, val, function(code, data) print(code, data) end)
end

local function read_adc()
	local val = adc.read(0) / 10
	return 100 - (val > 100 and 100 or val)
end

local function do_detect()
	gpio.write(1,1)
	local read_tmr = tmr.create()
	read_tmr:register(50, tmr.ALARM_SINGLE, function() 
		val = read_adc()
		gpio.write(1,0)
		upload_data(val) 
	end)
	read_tmr:start()
end

cfg = load_or_def_cfg()
detect_tmr:register(2000, tmr.ALARM_AUTO, do_detect)
detect_tmr:interval(cfg.interval)
detect_tmr:start()

-- 例子
-- http.post('https://io.adafruit.com/api/v2/Perfee/feeds/fcs/data', 'Content-Type: application/x-www-form-urlencoded\r\nX-AIO-Key: aio_vFeV04Vq4wWiDXtpgLSnmuRFNxMl\r\n', 'value=96', function(code, data) print(code, data) end)