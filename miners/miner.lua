-- Miner v1 by Litvinov
local computer = require("computer")
-- local robot = require("robot")
local com = require("component")
local ser = require("serialization")
local fs = require("filesystem")

local robot = com.robot
local inv = com.inventory_controller
local rs = com.redstone
local invSize = robot.inventorySize()
-- local techSlots = {}
local previousPos = 0

local function robotTurnAround()
  while not robot.turn(true) do end
  while not robot.turn(true) do end
end

local function robotStep(dir)
  while not robot.move(dir) do
    if dir == 3 then
      robot.swing(3)
    else
      robotTurnAround()
      robot.swing(3)
      robotTurnAround()
    end
  end
end

local function moveToPreviousPosition()
  if previousPos > 0 then
    robotTurnAround()
    for s = 1, previousPos do
      robotStep(3)
    end
    robotTurnAround()
    previousPos = 0
  end
end

-- local function searchSlot(lbl)
--   for tSlot in pairs(techSlots) do
--     local infStack = inv.getStackInInternalSlot(tSlot)
--     if infStack.label and infStack.label == lbl then
--       return tSlot
--     end
--   end
-- end

local function freeSlotSearch()
  for s = 3, invSize do
    if robot.count(s) == 0 then
      return s
    end
  end
end

local function slotClearing()
  while robot.count() > 0 do
    local freeSlot = freeSlotSearch()
    if freeSlot then
      robot.transferTo(freeSlot)
    else
      robot.drop(64, 0)
    end
  end
end

local function robotPlace(slot)
  robot.select(slot)
  while not robot.place(3) do
    local _, detectResult = robot.detect(3)
    if detectResult == "air" then
      robotStep(3)
      previousPos = previousPos + 1
    else
      robot.swing(3)
    end
  end
end

local function robotSwing(slot)
  robot.select(slot)
  slotClearing()
  robot.swing(3)
end

-- local function initTechSlots()
--   for slot = 1, invSize do
--     if robot.count(slot) > 0 then
--       techSlots[slot] = slot
--     end
--   end
-- end

local function lootUnload()
  for slot = 3, invSize do
    while robot.count(slot) > 0 do
      robot.select(slot)
      robot.drop(3)
    end
  end
end

local function lootSend()
  robotPlace(1)
  lootUnload()
  robotSwing(1)
  moveToPreviousPosition()
end

local function checkInventory()
  if robot.count(invSize - 1) > 0 then
    lootSend()
  end
end

local function main()
  lootSend()
end


main()
-- print(robot.detect(3))

-- local function test()
--   local x = 2
-- end

-- if test() then
--   print("bla")
-- end

-- for k, v in pairs(techSlots) do
--   print(k, v)
-- end
