-- Setup defaults --------------------------------------------------
temp_pin = 1
led_pin = 4
-- Zz513m
mqtt_address = "m21.cloudmqtt.com"
mqtt_port = 1883
mqtt_username = "qbrabuoq"
mqtt_password = "gagc4ur5Dd9u"
mqtt_clientid = "sensor_lounge"
mqtt_send_topic = "/sensors/temp/lounge"

-- Intervals and time are in seconds
temp_update_interval = 30

temp_sensor = require("ds18b20")
tmr.delay(800000)
temp_sensor.setup(temp_pin)
temp_sensor.readNumber()
gpio.mode(led_pin, gpio.OUTPUT, gpio.PULLUP)


-- Log to serial & server ------------------------------------------
function log(item)
	print(item)
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
	m:publish(mqtt_send_topic, temp, 0, 0, function(client) 
		log("Info: temperature data is sent") 
	end)
end


-- Main logic -----------------------------------------------------
tmr.alarm(2, 1000, 1, function()
    if wifi.sta.getip() == nil then
        print("Waiting for IP address...")
    else
        tmr.stop(2)
        print("WiFi connection established, IP address: " .. wifi.sta.getip())
        
        m = mqtt.Client(mqtt_clientid, 120, mqtt_username, mqtt_password)
        m:on("message", function(client, topic, data) 
            if topic == "/sensors/command/update_interval" and data ~= nil then
                log("Info: command received topic " .. topic .. ":" .. data)
                if type(data)=='number' and 0<=data and data<=0xffff then
                    tmr.stop(1)
                    temp_update_interval = data
                    tmr.alarm(1, temp_update_interval*1000, 1, temp_send)
                    log("Info: temp_update_interval set to" .. temp_update_interval)
                end
            end
        end)
        
        tmr.alarm(1, temp_update_interval*1000, 1, temp_send)
        
        m:subscribe("/sensors/command/+", 0)
        m:connect(mqtt_address, mqtt_port, false, true)

        tmr.alarm(2, 5000, 1, function()
            gpio.write(led_pin, gpio.LOW)
            tmr.delay(100)
            gpio.write(led_pin, gpio.HIGH)
        end)
    end
end)