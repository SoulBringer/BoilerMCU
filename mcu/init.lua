function startup()
    if file.open("init.lua") == nil then
        print("init.lua deleted or renamed")
    else
        print("Running")
        file.close("init.lua")
        -- the actual application is stored in file below
        --dofile("sensor.lua");
        dofile("boiler.lua");
    end
end

-- consider to move from init
print("Connecting to WiFi access point...")
wifi.setmode(wifi.STATION)
wifi.sta.config("Soul Home Net", "0556CCA2")
print("You have 3 seconds to abort")
print("Waiting...")
tmr.alarm(0, 3000, 0, startup)
