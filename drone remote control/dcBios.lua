--Universal drone remote control(drone) version: 1.0 by Litvinov
local d = component.proxy(component.list('drone')())
local m = component.proxy(component.list('modem')())
local leash = component.proxy(component.list('leash')())

local receivePort = 1010
local sendPort = 1011

m.open(receivePort)
m.setWakeMessage('droneSwitch')
d.move(0, -d.getOffset(), 0)

local function send(...)
  m.broadcast(sendPort, ...)
end

local function catch()
  for i = 0, 5 do
    if leash.leash(i) then
      return
    end
  end
end

local function suck_dropAll(side, action)
  for i = 1, d.inventorySize() do
    d.select(i)
    if action == 'suck' then
      d.suck(side)
    elseif action == 'drop' then
      d.drop(side)
    end
  end
  send('cSelectSlot', d.select(num), d.count())
end

local commands = {
  ['move'] = function(x, y, z) d.move(x, y, z) end,
  ['swing'] = function(side) d.swing(side) end,
  ['place'] = function(side) d.place(side) end,
  ['suck'] = function(side) d.suck(side) end,
  ['drop'] = function(side) d.drop(side) end,
  ['suckAll'] = function(side) suck_dropAll(side, 'suck') end,
  ['dropAll'] = function(side) suck_dropAll(side, 'drop') end,
  ['leash'] = function() catch() end,
  ['unleash'] = function() leash.unleash() end,
  ['select'] = function(num) if num <= d.inventorySize() then send('cSelectSlot', d.select(num), d.count()) end end,
  ['getPing'] = function() send('ping') end,
  ['changeColor'] = function(color) d.setLightColor(color) end,
  ['setAcceleration'] = function(value) d.setAcceleration(value) send('cAcceleration', d.getAcceleration()) end,
  ['getAcceleration'] = function() send('cAcceleration', d.getAcceleration()) end,
  ['droneSwitch'] = function() computer.shutdown() end
}

while true do
  local event = {computer.pullSignal()}
  if event[1] == 'modem_message' then
    commands[event[6]](event[7], event[8], event[9])
  end
end
