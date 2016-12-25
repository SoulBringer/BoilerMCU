-- Setup defaults --------------------------------------------------
temp_pin = 1
mqtt_address = "192.168.11.118"
mqtt_port = 1883
mqtt_username = ""
mqtt_password = ""
mqtt_clientid = ""

-- Intervals and time are in seconds
temp_update_interval = 30

temp_sensor = require("ds18b20")
tmr.delay(800000)
temp_sensor.setup(temp_pin)


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
	m:publish("/data/sensors/temp", temp, 0, 0, function(client) 
		log("Info: temperature data is sent") 
	end)
end


-- Main logic -----------------------------------------------------
m = mqtt.Client(mqtt_clientid, 120, mqtt_username, mqtt_password)
m:on("message", function(client, topic, data) 
	if topic == "/commands/sensors/update_interval" and data ~= nil then
		log("Info: command received topic " .. topic .. ":" .. data)
		if type(data)=='number' and 0<=data and data<=0xffff then
			temp_update_interval = data
			tmr.alarm(1, temp_update_interval*1000, 1, temp_send)
			log("Info: temp_update_interval set to" .. temp_update_interval)
		end
	end
end)

tmr.alarm(1, temp_update_interval*1000, 1, temp_send)
m:subscribe("/commands/sensors/*", 0)
m:connect(mqtt_address, mqtt_port, false, true)