-- a simple HTTP server
srv = net.createServer(net.TCP)
srv:listen(80, function(conn)
    conn:on("receive", function(sck, payload)
        print(payload)
        local _, _, method, path, vars = string.find(payload, "([A-Z]+) (.+)?(.+) HTTP");
        if(method == nil)then
            _, _, method, path = string.find(payload, "([A-Z]+) (.+) HTTP");
        end

        if (path == "/") then
            local status, temp, humi, temp_dec, humi_dec = dht.read(4)
            sck:send("HTTP/1.0 200 OK\r\nContent-Type: text/html\r\n\r\n")
            sck:send("<H1> " .. temp .. " " .. humi .. " </H1>")
        end
    end)
    conn:on("sent", function(sck) sck:close() end)
end)


    sk=net.createConnection(net.TCP, 0)
    sk:on("receive", function(sck, c) print(c) end )
    sk:connect(80,"192.168.0.66")
    sk:send("GET / HTTP/1.1\r\nHost: 192.168.0.66\r\nConnection: keep-alive\r\nAccept: */*\r\n\r\n")

	
m = mqtt.Client("clientid", 120, "user", "password")
	
-- On publish message receive event
m:on("message", function(client, topic, data) 
	print(topic .. ":" ) 
	if data ~= nil then
		print(data)
	end
end)

-- subscribe topic with qos = 0
m:subscribe("/topic",0, function(client) print("subscribe success") end)

-- publish a message with data = hello, QoS = 0, retain = 0
m:publish("/topic", "hello", 0, 0, function(client) print("sent") end)
