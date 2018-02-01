local computer = require("computer")
local com = require("component")
local event = require("event")

local m = com.modem
local gpu = com.gpu

local port = 1234
local showInterface = false
local curtail = false
local keyExit = 41
local keyCurtail = 15
local xRes, yRes = gpu.getResolution()
local oldBackground = gpu.getBackground()
local oldForeground = gpu.getForeground()

local colors = {
  white = 0xFFFFFF,
  black = 0x000000,
  gray = 0x2D2D2D,
  red = 0xFF0000,
  green = 0x00FF00,
  green2 = 0x336600,
  yellow = 0xFFFF00,
  blue = 0x336699,
  purple = 0x9933CC,
}

local color = {
  background = colors.black,
  background_TextArea = colors.gray,
  line = colors.gray,
  text_TextArea = colors.white,
  textSender = colors.white,
  textRecipient = colors.white,
  textLine = colors.green,
}

local function reciveMessage(...)
  local tbl = {...}
  computer.beep()
  if showInterface then
    for k, v in pairs(tbl) do
      print(k, v)
    end
  end
end

local function screenClear(bgrColor, fgrColor)
  bgrColor = bgrColor or colors.black
  fgrColor = fgrColor or colors.white
  gpu.setBackground(bgrColor)
  gpu.fill(1, 1, xRes, yRes, " ")
  gpu.setForeground(fgrColor)
end

local function programExit()
  event.ignore("modem_message", reciveMessage)
  event.ignore("key_down", keyDown)
  m.close(port)
  screenClear(oldBackground, oldForeground)
end

local function drawInterface()
  screenClear(color.background)
  gpu.setBackground(color.line)
  gpu.fill(1, 1, xRes, 1, " ")
  gpu.setForeground(color.textLine)
  gpu.set(xRes / 2 - 2, 1, "Chat")
  gpu.setBackground(color.background)
  gpu.setForeground(color.text_TextArea)
end

local function keyDown(_, _, _, key)
  print(key)
  if key == keyCurtail then
    if curtail then
      curtail = false
      drawInterface()
    else
      curtail = true
      screenClear(oldBackground, oldForeground)
    end
  elseif key == keyExit then
    programExit()
  end
end

local function start(arg)
  if arg ~= "noint" then
    showInterface = true
  end

  if not m.isOpen(port) then
    m.open(port)
  end

  event.listen("modem_message", reciveMessage)
  event.listen("key_down", keyDown)

  if showInterface then
    drawInterface()
  end
end

start(...)
