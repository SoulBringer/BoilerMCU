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