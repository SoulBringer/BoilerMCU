heater_pin = 3
led_pin = 4
heater_on = false

gpio.mode(heater_pin, gpio.OUTPUT)
gpio.write(heater_pin, gpio.HIGH)
gpio.mode(led_pin, gpio.OUTPUT, gpio.PULLUP)
gpio.write(led_pin, gpio.HIGH)


tmr.alarm(1, 900, 1, function()
    gpio.write(led_pin, gpio.LOW)
    tmr.delay(100)
    gpio.write(led_pin, gpio.HIGH)
end)

tmr.alarm(2, 10000, 1, function()
    heater_on = not heater_on
    if (heater_on) then
        gpio.write(heater_pin, gpio.LOW)
    else
        gpio.write(heater_pin, gpio.HIGH)
    end
end)
