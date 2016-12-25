-- Setup defaults --------------------------------------------------
heater_pin = 2
temp_pin = 1
time_max = 2147483648	-- when NodeMCU timer overflows

mqtt_address = "192.168.11.118"
mqtt_port = 1883
mqtt_username = ""
mqtt_password = ""
mqtt_clientid = ""

-- Intervals and time are in seconds
config_update_interval = 30
heater_cycle_interval = 2
heater_on_max_time = 10
heater_off_min_time = 10

-- Degrees are in Celsius
temp_max = 28
temp_min = 26

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


-- Log to serial & server ------------------------------------------
function log(item)
	print(item)
end


-- Time operation routine ------------------------------------------
function time_since(recent_time)
    -- Check and fix timer overflow
    local time_dif = tmr.time() - recent_time
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
        heater_on_time = tmr.time()
        heater_off_time = nil
        log("Info: heater enabled on " .. heater_on_time)
   else
        gpio.write(heater_pin, gpio.HIGH)
        heater_on = false
        heater_on_time = nil
        heater_off_time = tmr.time()
        log("Info: heater disabled on " .. heater_off_time)
   end
end

-- Retreive remote temperature --------------------------------------------
function get_remote_temp()
	http.get("http://httpbin.org/ip", nil, function(code, data)
		if (code < 0) then
			print("HTTP request failed")
		else
			print(code, data)
		end
	end)
end


-- Retreive temperature --------------------------------------------
function get_temp()
    local local_temp = temp_sensor.readNumber()
    log("Info: current local temperature is: " .. local_temp)
    log("Info: current remote temperature is: " .. remote_temp)
    return local_temp
end


-- Read configuration from server ----------------------------------
function read_config()
    log("Info: reading config from server")
    -- TODO: Implement this
end
tmr.alarm(2, config_update_interval*1000, 1, read_config)


-- Main heating logic ----------------------------------------------
function heating()
    --log("Info: -------------------------------------------------")
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

m = mqtt.Client(mqtt_clientid, 120, mqtt_username, mqtt_password)
m:on("message", function(client, topic, data) 
	if topic == "/data/sensors/temp" and data ~= nil then
		log("Info: command received topic " .. topic .. ":" .. data)
		if type(data)=='number' and 0<=data and data<=0xffff then
			remote_temp = data
 			log("Info: remote_temp received: " .. remote_temp)
		end
	end
end)
m:subscribe("/commands/heater/*", 0)
m:connect(mqtt_address, mqtt_port, false, true)