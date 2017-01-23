-- Setup defaults --------------------------------------------------
heater_pin = 2
temp_pin = 1
led_pin = 4
time_max = 2147483648	-- when NodeMCU timer overflows

mqtt_address = "m21.cloudmqtt.com"
mqtt_port = 1883
mqtt_username = "qbrabuoq"
mqtt_password = "gagc4ur5Dd9u"
mqtt_clientid = "heater"

-- Intervals and time are in seconds
temp_update_interval = 30
heater_cycle_interval = 2
heater_on_max_time = 60
heater_off_min_time = 60

-- Degrees are in Celsius
temp_max = 22
temp_min = 21

temp_internal = temp_max
temp_external = temp_max
heater_on = false
heater_on_time = nil
heater_off_time = tmr.time()
gpio.mode(heater_pin, gpio.OUTPUT)
gpio.write(heater_pin, gpio.HIGH)

temp_sensor = require("ds18b20")
tmr.delay(800000)
temp_sensor.setup(temp_pin)
temp_sensor.readNumber()
gpio.mode(led_pin, gpio.OUTPUT, gpio.PULLUP)


-- Log to serial & server ------------------------------------------
function log(item)
	print(item)
end


-- Time operation routine ------------------------------------------
function time_since(recent_time)
    -- Check and fix timer overflow
    --local time_now = tmr.time()   --inaccurate https://goo.gl/OeAsfT
    local time_now = tmr.now() / 1000000    -- temp fix
    local time_dif = time_now - recent_time
    if (time_dif < 0) then
        time_dif = time_dif + time_max
    end
    return time_dif
end


-- Heater control --------------------------------------------------
function heater_switch(flag)
    if (flag) then
        gpio.write(heater_pin, gpio.LOW)
        heater_on = true
        heater_on_time = tmr.now() / 1000000    -- temp fix
        heater_off_time = nil
        log("Info: heater enabled on " .. heater_on_time)
        if (m ~= nil) then
            m:publish("/sensors/heater", "ON", 0, 0)
        end
   else
        gpio.write(heater_pin, gpio.HIGH)
        heater_on = false
        heater_on_time = nil
        heater_off_time = tmr.now() / 1000000    -- temp fix
        log("Info: heater disabled on " .. heater_off_time)
        if (m ~= nil) then
            m:publish("/sensors/heater", "OFF", 0, 0)
        end
   end
end


-- Retreive temperature --------------------------------------------
function get_temp()
    local local_temp = temp_sensor.readNumber()
    log("Info: current local temperature is: " .. local_temp)
    return local_temp
end


-- Send temp -------------------------------------------------------
function temp_send()
    local temp = get_temp()
    -- publish a message with data = hello, QoS = 0, retain = 0
    m:publish("/sensors/temp/heater", temp, 0, 0)
end


-- On MQTT message received ---------------------------------------
function on_mqtt_message(client, topic, data)
    log("Info: command received topic " .. topic .. ":" .. data)
    --temp_update_interval
    --temp_max
    --temp_min
    --heater_on_max_time
    --heater_off_min_time
    --heater_on
end


-- Main heating logic ----------------------------------------------
function heating()
    local temp = get_temp()

    -- Main logic
    if (heater_on) then
        local heating_time = time_since(heater_on_time)        
        if (heating_time > heater_on_max_time) then
            -- Error case
            heater_switch(false)
            log("Error: heater_on_max_time exceeded, temperature is not reached!!!")
        elseif (temp >= temp_max) then
            -- Heating is done
            heater_switch(false)
            log("Info: temperature is reached in " .. heating_time .. " s")
        else
            -- All Ok, heating in process for heating_time
            --log("Info: heating in progress")
        end
    else -- (heater_on == false)
        local cooling_time = time_since(heater_off_time)        
        if (temp < temp_min) then
            if (cooling_time > heater_off_min_time) then
                -- Cooling last for cooling_time, heating on
                heater_switch(true)
                log("Info: temperature is low, cooling took " .. cooling_time .. " s")
            else
                -- Error case
                log("Error: temperature is low, heater_off_min_time is not reached!!!")
            end
        else
            -- All Ok, cooling in process for cooling_time
            --log("Info: cooling in progress")
        end
    end
end
tmr.alarm(1, heater_cycle_interval*1000, 1, heating)

tmr.alarm(3, 5000, 1, function()
    gpio.write(led_pin, gpio.LOW)
    tmr.delay(100)
    gpio.write(led_pin, gpio.HIGH)
    tmr.delay(100)
    gpio.write(led_pin, gpio.LOW)
    tmr.delay(100)
    gpio.write(led_pin, gpio.HIGH)
    collectgarbage("collect")
end)

tmr.alarm(2, 1000, 1, function()
    if wifi.sta.getip() == nil then
        --log("Info: Waiting for IP address")
    else
        tmr.stop(2)
        log("Info: WiFi connection established, IP address: " .. wifi.sta.getip())
        
        m = mqtt.Client(mqtt_clientid, 120, mqtt_username, mqtt_password)
        m:on("offline", function(client)
            log("Info: MQTT reconnect")
            m:connect(mqtt_address, mqtt_port, false, true)
        end)
        m:on("message", on_mqtt_message)        
        m:subscribe("/heater/command/+", 0)
        m:connect(mqtt_address, mqtt_port, false, true)

        tmr.alarm(2, temp_update_interval*1000, 1, temp_send)
        
        tmr.alarm(3, 5000, 1, function()
            gpio.write(led_pin, gpio.LOW)
            tmr.delay(100)
            gpio.write(led_pin, gpio.HIGH)
            collectgarbage("collect")
        end)
    end
end)