local com = require("component")
local event = require("event")

local m = com.modem
local cb = com.chat_box

local maxRange = 32767
local minRange = 4
local maxLenght = maxRange
local minLenght = minRange
local oldMaxLenght = maxLenght
local oldMinLenght = minLenght

m.open(2525)
cb.setDistance(maxRange)

local function minus()
  oldMaxLenght = maxLenght
  oldMinLenght = minLenght
  maxLenght = ((maxLenght - minLenght) / 2) + minLenght
  cb.setDistance(maxLenght)
  print("Расстояние к цели = "..maxLenght)
  if oldMaxLenght - maxLenght < minRange and oldMaxLenght - maxLenght > 0 then
    print("Done")
    os.exit()
  end
  os.sleep(0.5)
end

local function plus()
  minLenght = maxLenght
  maxLenght = oldMaxLenght
  minus()
end

while true do
  local e = {event.pull()}
  if e[1] == "chat_message" then
    if e[3] == "denis12345" then
		  minus()
    end
  elseif e[1] == "modem_message" then
    plus()
  end
end
