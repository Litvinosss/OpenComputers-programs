-- Miner v1 by Litvinov
local computer = require("computer")
local robot = require("robot")
local com = require("component")
local ser = require("serialization")
local fs = require("filesystem")

local rs = com.redstone
local invSize = robot.inventorySize()
local techSlots = {}

local function initTechSlots()
  for slot = 1, invSize do
    if robot.count(slot) > 0 then
      techSlots[slot] = slot
    end
  end
end

local function unloadLoot(side)
  for slot = 1, invSize do
    while not techSlots[slot] and robot.count(slot) > 0 do
      robot.select(slot)
      robot.drop(64, side)
    end
  end
end

local function main()
  initTechSlots()
  io.read()
  unloadLoot(3)
end

main()
