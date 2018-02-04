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
local minToolChargeLevel = 0.15 --В процентах от максимального уровня заряда
local energyStorageLable = "MFE"
local powerConverterLable = "Power Converter"
local chargerLable = "Charger"
local wrenchLable = "Electric Wrench"
local energyCrystalLable = "Energy Crystal"
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

local function searchSlotInChest(lbl)
  while true do
    for slot = 1, inv.getInventorySize(3) do
      local infStack = inv.getStackInSlot(3, slot)
      if infStack and infStack.label and infStack.label == lbl then
        return slot
      end
    end
  end
end

local function freeSlotSearch()
  for s = 3, invSize do
    if robot.count(s) == 0 then
      return s
    end
  end
end

local function slotClearing(slot)
  robot.select(slot)
  while robot.count() > 0 do
    local freeSlot = freeSlotSearch()
    if freeSlot then
      robot.transferTo(freeSlot)
    else
      robot.drop(64, 0)
    end
  end
end

local function suckFromChest(itemLabel)
  local slotNumInChest = searchSlotInChest(itemLabel)
  local freeSlot = freeSlotSearch()
  robot.select(freeSlot)
  while not inv.suckFromSlot(3, slotNumInChest) do end
  return freeSlot
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
  slotClearing(slot)
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

local function chargingInStorage()
  inv.equip()
  inv.dropIntoSlot(3, 1)
  while inv.getStackInSlot(3, 1).charge < inv.getStackInSlot(3, 1).maxCharge do
    os.sleep(1)
  end
  inv.suckFromSlot(3, 1)
  inv.equip()
end

local function toolCharging()
  lootSend() --Отправка лута на базу что бы не мешал
  robotPlace(2) --Установка сундука с прибамбасами
  local eStorageSlot = suckFromChest(energyStorageLable) --Высасывание МФЭ из сундука в свободный слот инвентаря
  local wrenchSlot = suckFromChest(wrenchLable) --Высасывание электро ключа из сундука в свободный слот инвентаря
  local crystalSlot = suckFromChest(energyCrystalLable) --Высасывание кристала из сундука в свободный слот инвентаря
  robotStep(2) --Перемещения робота на один блок назад
  robot.select(eStorageSlot) --Выбор слота с МФЭ
  while not robot.place(3) do --Установка МФЭ
    robot.swing()
  end
  robot.select(crystalSlot) --Выбор слота с кристалом
  inv.dropIntoSlot(3, 2) --Засунуть кристал во второй слот МФЭ
  chargingInStorage() --Зарядка экипированного инструмента (бура)
  inv.suckFromSlot(3, 2) --Высасивания кристала из МФЭ
  robot.select(wrenchSlot) --Выбор слота с ключем
  inv.equip() --Экипировка
  robot.select(eStorageSlot) --Выбор слота МФЭ
  robot.use(3) --Откручивание МФЭ
  robot.select(wrenchSlot) --Выбор слота с ключем
  inv.equip() --Экипировка
  robotStep(3) --Перемещение робота на один блок вперед
  lootUnload() --Выгрузка всех предметов в сундук
  robotSwing(2) --Ломания сундука с прибамбасами
  moveToPreviousPosition() --Возвращение на предыдущую позицию после установки сундука
end

local function checkToolCharge()
  inv.equip()
  local infStack = inv.getStackInInternalSlot()
  inv.equip()
  if infStack.charge < infStack.maxCharge * minToolChargeLevel then
    toolCharging()
  end
end

local function robotCharging()
  lootSend() --Отправка лута на базу что бы не мешал
  robotPlace(2) --Установка сундука с прибамбасами
  local eStorageSlot = suckFromChest(energyStorageLable) --Высасывание МФЭ из сундука в свободный слот инвентаря
  local wrenchSlot = suckFromChest(wrenchLable) --Высасывание электро ключа из сундука в свободный слот инвентаря
  local crystalSlot = suckFromChest(energyCrystalLable) --Высасывание кристала из сундука в свободный слот инвентаря
  local converterSlot = suckFromChest(powerConverterLable) --Высасывание преобразователя из сундука в свободный слот инвентаря
  local chargerSlot = suckFromChest(chargerLable) --Высасывание зарядника из сундука в свободный слот инвентаря
  robotStep(2) --Перемещения робота на один блок назад
  robot.select(eStorageSlot) --Выбор слота с МФЭ
  while not robot.place(3) do --Установка МФЭ
    robot.swing()
  end
  robot.select(crystalSlot) --Выбор слота с кристалом
  inv.dropIntoSlot(3, 2) --Засунуть кристал во второй слот МФЭ
  robotStep(2) --Перемещения робота на один блок назад
  robot.select(converterSlot) --Выбор слота с преобразователем
  while not robot.place(3) do --Установка преобразователя
    robot.swing()
  end
  robotStep(2) --Перемещения робота на один блок назад
  robot.select(chargerSlot) --Выбор слота с зарядником
  while not robot.place(3) do --Установка зарядника
    robot.swing()
  end
  rs.setOutput(3, 15) --Подача редстоун сигнала на зарядник
  while computer.energy() < computer.maxEnergy() * 0.95 do --Ожидание пока робот зарядится до 95%
    os.sleep(1)
  end
  rs.setOutput(3, 0) --Отключения редстоун сигнала
  robotSwing(chargerSlot) --Ломание зарядника
  robotStep(3) --Перемещения на один блок вперед
  robotSwing(converterSlot) --Ломания преобразователя
  robotStep(3) --Перемещения на один блок вперед
  slotClearing(crystalSlot)
  inv.suckFromSlot(3, 2) --Высасивания кристала из МФЭ
  robot.select(wrenchSlot)
  inv.equip()
  slotClearing(eStorageSlot)
  robot.use(3)
  robot.select(wrenchSlot)
  inv.equip()
  robotStep(3)
  lootUnload() --Выгрузка всех предметов в сундук
  robotSwing(2) --Ломания сундука с прибамбасами
  moveToPreviousPosition() --Возвращение на предыдущую позицию после установки сундука
end

local function checkRobotCharge()
  if computer.energy() < computer.maxEnergy() * 0.15 then
    robotCharging()
  end
end

local function main()
end

main()
