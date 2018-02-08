local com = require("component")
local event = require("event")

local gpu = com.gpu
local rs = com.redstone
local screens = {
  [1] = com.get("90a"),
  [2] = com.get("5d4")
}

local isOpen = true
local textOpen = "Open door"
local textClose = "Close door"
local resX, resY = 12, 6

local players = {
  "Litvinov",
  "denis12345"
}

local colors = {
  gray = 0x202020,
  red = 0xFF0000,
  green = 0x00FF00
}

local function draw()
  for _, addr in pairs(screens) do
    gpu.bind(addr)
    gpu.setResolution(resX, resY)
    gpu.setBackground(colors.gray)
    gpu.fill(1, 1, resX, resY, " ")
    if isOpen then
      gpu.setForeground(colors.green)
      gpu.set(2, 3, textOpen)
    else
      gpu.setForeground(colors.red)
      gpu.set(2, 3, textClose)
    end
  end
end

local function on(side)
  rs.setOutput(side, 15)
end

local function off(side)
  rs.setOutput(side, 0)
end

local function openDoor()
  off(2)
  off(4)
  on(0)
  on(1)
  off(1)
  off(0)
  on(2)
  off(2)
  off(5)
end

local function closeDoor()
  on(5)
  on(0)
  off(0)
  on(4)
  on(2)
end

local function changeDoor()
  if isOpen then
    closeDoor()
    isOpen = false
    draw()
  else
    openDoor()
    isOpen = true
    draw()
  end
  os.sleep(0.5)
end

changeDoor()

while true do
  local e, _, _, _, _, nick = event.pull("touch")
  for _, player in pairs(players) do
    if nick == player then
      changeDoor()
      break
    end
  end
end
