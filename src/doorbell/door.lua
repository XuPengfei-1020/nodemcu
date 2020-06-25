door_async=0
door={}

-- open the door
function door:open_door()
    if (door_async ~= 0) then print('running...') return end;
    door_async=1

    gpio.mode(1, gpio.OUTPUT)
    open_door_tmr = tmr.create()
    open_door_tmr:register(1200, tmr.ALARM_SINGLE, function() 
        for i=1,10 do        
            gpio.mode(2, gpio.OUTPUT)
            -- 200ms ~ 700ms
            tmr.delay(us(200, 400))
            gpio.mode(2, gpio.INPUT)
            -- 200ms ~ 400ms
            tmr.delay(us(200, 200))
        end

        tmr.delay(us(1000, 500))
        gpio.mode(2, gpio.INPUT)
        gpio.mode(1, gpio.INPUT)
        open_door_tmr:stop()
        open_door_tmr=nil
        door_async=0
    end)
    open_door_tmr:start()
end

-- hood the door！！！ hood door！ hood door！ ^-^
function door:hang_up()
    if (door_async ~= 0) then print('running...') return end;
    door_async=1
    gpio.mode(1, gpio.OUTPUT)
    hang_up_tmr = tmr.create()
    hang_up_tmr:register(ms(1000, 1000), tmr.ALARM_SINGLE, function()
        gpio.mode(1, gpio.INPUT)
        hang_up_tmr:stop()
        hang_up_tmr=nil
        door_async=0
    end)
    hang_up_tmr:start()
end

-- return a interval section of ms, param unit: ms
function ms(base, add)
    return base + math.random(add)
end

-- return a interval section of us, param unit: ms
function us(base, add)
    return ms(base,add)*1000;
end