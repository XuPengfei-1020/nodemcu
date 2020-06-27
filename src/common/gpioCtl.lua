-- 接收 cmd，对 gpio 执行一系列连续的控制动作
-- cmd 为 table 类型，参数
-- action: 'sleep' 表示休眠 , 'op' 表示操作, 'loop' 表示循环
-- interval: 执行完动作后或者每次循环后的休眠时间，单位 ms，格式数字或者 tab {base, add}, action 为 op 或者 loop 时生效
-- gp ：tab
-- 示例：
-- {{act = 'op', gp = {1, 1}}, {act = 'sleep', itvl=1000}, {act = 'op', gp = {1, 0}}} -- 将 1 设置为 output 模式，休眠 1000 ms，将 1 设置为 input 模式
-- {{act = 'op', gp = {1, 1}, itvl={2000, 500}}, {act = 'loop', times = 3, cmd = {{act = 'op', gp = {2, 1}}, {act = 'sleep', itvl=1000}, {act = 'op', gp = {2, 0}}}, itvl={800, 20}}, {act = 'op', gp = {1, 0}}} 
--     1. 将 1 设置为 output 模式，然后休眠 2000 ~ 2500 ms，2. 循环：{将 2 设置为 output 休眠 1000 ms，将 2 设置为 input 模式} 3 次，每次循环后休眠 800 ~ 820 ms, 3. 将 1 设置 input 模式

local gpio_async=0

-- return a interval section of ms, param unit: ms
local function _ms(base, add)
	if add == 0 then
		return base
	end
	return base + math.random(add)
end

-- return a interval section of us, param unit: ms
local function _us(base, add)
	return _ms(base, add) * 1000;
end

-- error msg
local function _errcode(errMsg)
	return {code = -1, msg = errMsg}
end

-- ok msg
local function _okcode(msg)
	return {code = 0, msg = msg}
end

function _sleep(itvl, doaction, debug)
	if itvl == nil then
		return _errcode('interval is nil')
	end

	local time = nil
	if type(itvl) == 'number' then 
		time = itvl
	elseif type(itvl) == 'table' then
		if type(itvl[1]) ~= 'number' or type(itvl[2]) ~= 'number' then
			return _errcode('interval is invalid.')
		end
		time = _us(itvl[1], itvl[2])
	else 
		return _errcode(string.format('unsupported interval type: %s', type(itvl)))
	end

	if debug then
		print(string.format('sleep: %d ms', time / 1000))
	end

	if doaction then
		tmr.delay(time)
	end
	return _okcode()
end

gpioctl = {}

-- 同步运行
function gpioctl:cmdasync(cmd, doaction, debug)
	if gpio_async ~= 0 then
		return _errcode('gpio is running.')
	end

	gpio_async = 1
	local ok, rs = pcall(function() return gpioctl:cmd(cmd, doaction, debug) end)
	gpio_async = 0

	if not ok then 
		return _errcode(rs)
	end

	return rs
end

-- cmd, 
function gpioctl:cmd(cmd, doaction, debug)
	if cmd == nil then
		return _errcode('cmd is nil.')
	end

	if #cmd == 0 then
		return _errcode('cmd is not array.')
	end

	if doaction then
		local predict = gpioctl:cmd(cmd)
		if predict.code == -1 then
			return predict;
		end
	end

	for i= 1, #cmd do
		local item = cmd[i]
		if debug then
			print('\nact:', item.act)
		end

		if item.act == 'sleep' then
			-- sleep 指令
			local rs = _sleep(item.itvl, doaction, debug)
			
			if rs.code == -1 then
				return rs
			end
		elseif item.act == 'op' then
			-- 操作 gpio 指令
			local gp = item.gp
			if gp == nil or type(gp[1]) ~= 'number' or type(gp[2]) ~= 'number' then
				return _errcode('gp is invalid')
			end

			if debug then
				print(string.format('gpio:set mode %s: %s', gp[1], gp[2]))
			end
			if doaction then
				gpio.mode(gp[1], gp[2])
			end

			if item.itvl ~= nil then
				local rs = _sleep(item.itvl, doaction, debug)

				if rs.code == -1 then
					return rs
				end
			end
		elseif item.act == 'loop' then
			-- 循环指令
			local times = item.times;
			if type(times) ~= 'number' then
				return _errcode('times is invalid')
			end

			for j = 1, times do
				local rs = gpioctl:cmd(item.cmd, doaction, debug)
				if rs.code == -1 then
					return rs
				end

				if item.itvl ~= nil then 
					local rs = _sleep(item.itvl, doaction, debug)

					if rs.code == -1 then
						return rs
					end
				end
			end
		elseif item.act == nil then
			return _errcode('action is nil')
		else
			return _errcode(string.format('unsupported action: %s', item.act))
		end
	end
	return _okcode()
end