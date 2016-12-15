t=require("ds18b20")
t.setup(4)
addrs=t.addrs()

while true do
    print(t.readNumber())
    tmr.delay(1000000)
end

-- Don't forget to release it after use
t = nil
ds18b20 = nil
package.loaded["ds18b20"]=nil