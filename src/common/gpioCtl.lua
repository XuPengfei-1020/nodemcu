-- 接收 cmd，对 gpio 执行一系列连续的控制动作
-- cmd 为 table 类型，参数
-- action: 'sleep' 表示休眠 , 'op' 表示操作, 'loop' 表示循环
-- interval: 执行完动作后或者每次循环后的休眠时间，单位 ms，格式数字或者 tab {base, add}, action 为 op 或者 loop 时生效
-- gp ：tab
-- 示例：
-- {{act = 'op', gp = {1, 1}}, {act = 'sleep', itvl=100}, {act = 'op', gp = {1, 0}}} -- 将 1 设置为 output 模式，休眠 100 ms，将 1 设置为 input 模式
-- {{act = 'op', gp = {1, 1}, itvl={2000, 500}}, {act = 'loop', times = 3, cmd = {{act = 'op', gp = {2, 1}}, {act = 'sleep', itvl=100}, {act = 'op', gp = {2, 0}}}, itvl={200, 20}}} 
--     1. 将 1 设置为 output 模式，然后休眠 2000 ~ 2500 ms，2. 循环：{将 2 设置为 output 休眠 100 ms，将 2 设置为 input 模式} 3 次，每次循环后休眠 200 ~ 220 ms

gpio_async=0
gpioCtl = {
	code = {
		ERROR = -1,
		OK = 1
	},
	types = {
		NUM = 'number',
		TAB = 'table'
	}, 
	actions = {
		SLEEP = 'sleep',
		OP = 'op',
		LOOP = 'loop'
	}
}

-- cmd, 
function gpioCtl:cmd(cmd, doaction, debug)
	if cmd == nil then
		return gpioCtl:errCode('cmd is nil.')
	end

	if #cmd == 0 then
		return gpioCtl:errCode('cmd is not array.')
	end

	for i= 1, #cmd do
		local item = cmd[i]
		if debug then
			print('\nact:', item.act)
		end

		if item.act == gpioCtl.actions.SLEEP then
			-- sleep 指令
			local rs = gpioCtl:sleep(gpioCtl:us(item.itvl, 0), doaction, debug)
			
			if rs.code == gpioCtl.code.ERROR then
				return rs
			end
		elseif item.act == gpioCtl.actions.OP then
			-- 操作 gpio 指令
			local gp = item.gp
			if gp == nil or type(gp[1]) ~= gpioCtl.types.NUM or type(gp[2]) ~= gpioCtl.types.NUM then
				return gpioCtl:errCode('gp is invalid')
			end

			if debug then
				print(string.format('gpio:set mode %s: %s', gp[1], gp[2]))
			end
			if doaction then
				gpio.mode(gp[1], gp[2])
			end

			if item.itvl ~= nil then
				local rs = gpioCtl:sleep(item.itvl, doaction, debug)

				if rs.code == gpioCtl.code.ERROR then
					return rs
				end
			end
		elseif item.act == gpioCtl.actions.LOOP then
			-- 循环指令
			local times = item.times;
			if type(times) ~= 'number' then
				return gpioCtl:errCode('times is invalid')
			end

			for j = 1, times do
				local rs = gpioCtl:cmd(item.cmd, doaction, debug)
				if rs.code == gpioCtl.code.ERROR then
					return rs
				end

				if item.itvl ~= nil then 
					local rs = gpioCtl:sleep(item.itvl, doaction, debug)

					if rs.code == gpioCtl.code.ERROR then
						return rs
					end
				end
			end
		elseif item.act == nil then
			return gpioCtl:errCode('action is nil')
		else
			return gpioCtl:errCode(string.format('unsupported action: %s', item.act))
		end
	end
	return gpioCtl:okCode()
end

-- return a interval section of ms, param unit: ms
function gpioCtl:ms(base, add)
	if add == 0 then
		return base
	end
	return base + math.random(add)
end

-- return a interval section of us, param unit: ms
function gpioCtl:us(base, add)
	return gpioCtl:ms(base, add) * 1000;
end

function gpioCtl:sleep(itvl, doaction, debug)
	if itvl == nil then
		return gpioCtl:errCode('interval is nil')
	end

	local time = nil
	if type(itvl) == gpioCtl.types.NUM then 
		time = itvl
	elseif type(itvl) == gpioCtl.types.TAB then
		if type(itvl[1]) ~= gpioCtl.types.NUM or type(itvl[2]) ~= gpioCtl.types.NUM then
			return gpioCtl:errCode('interval is invalid.')
		end
		time = gpioCtl:us(itvl[1], itvl[2])
	else 
		return gpioCtl:errCode(string.format('unsupported interval type: %s', type(itvl)))
	end

	if debug then
		print(string.format('sleep: %d ms', time / 1000))
	end

	if doaction then
		tmr.delay(time)
	end
	return gpioCtl:okCode()
end

-- check type
function gpioCtl:validType(obj, types) 
	if obj == nil then
		return false
	end

	local type = type(obj)
	for i = 1, #types do 
		if type == types[i] then
			return true
		end
	end
	return false
end

-- error msg
function gpioCtl:errCode(errMsg)
	return {code = gpioCtl.code.ERROR, msg = errMsg}
end

-- ok msg
function gpioCtl:okCode(msg)
	return {code = gpioCtl.code.OK, msg = msg}
end

print('Load gpioCtl file')