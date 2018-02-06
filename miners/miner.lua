-- Miner v2 by Litvinov
local computer = require("computer")
local com = require("component")
-- local ser = require("serialization")
-- local fs = require("filesystem")

local robot = com.robot
local inv = com.inventory_controller
local rs = com.redstone
local invSize = robot.inventorySize()

local energyCrystalLable = "Energy Crystal" --Название энергетического кристалла
local chestLootSlot = 1 --Слот с сундуком в который выгружается лут
local chestChargeSlot = 2 --Слот с сундуком в котором находятся энергетические кристаллы
local MFESlot = 3 --Слот с МФЭ
local powerConverterSlot = 4 --Слот с преобразователем энергии ОС
local chargerSlot = 5 --Слот с зарядником ОС
local wrenchSlot = 6 --Слот с электро ключем IC2
local firstLootSlot = 7 --Первый слот для лута
local minToolChargeLevel = 0.2 --Уровень заряда при котором требуется зарядка инструмента в процентах от максимального заряда
local minRobotChargeLevel = 0.2 --Уровень заряда при котором требуется зарядка робота в процентах от максимального заряда
local numBetChecks = 64 --Через сколько сломанных блоков будет проводится проверка на потребность обслуживания

local circle = 1
local countSwing = 0
local previousPos = 0
local energyCrystalSlot

local function rTurnL()
  while not robot.turn(false) do end
end

local function rTurnR()
  while not robot.turn(true) do end
end

local function rTurnAround()
  rTurnR()
  rTurnR()
end

local function rSwing()
  if robot.swing(3) then
    countSwing = countSwing + 1
  end
end

local function rMoveBack()
  while not robot.move(2) do
    rTurnAround()
    rSwing()
    rTurnAround()
  end
end

local function rMoveForward()
  rSwing()
  while not robot.move(3) do
    rSwing()
  end
end

local function rPlace(slot)
  robot.select(slot)
  while not robot.place(3) do
    local _, detectResult = robot.detect(3)
    if detectResult == "air" then
      rMoveForward()
      previousPos = previousPos + 1
    else
      rSwing()
    end
  end
end

local function moveToPreviousPosition()
  if previousPos > 0 then
    rTurnAround()
    for pCount = 1, previousPos do
      rMoveForward()
    end
    rTurnAround()
    previousPos = 0
  end
end

local function freeSlotSearch()
  for s = firstLootSlot, invSize do
    if robot.count(s) == 0 then
      return s
    end
  end
  if robot.count(firstLootSlot) > 0 then
    robot.select(firstLootSlot)
    rTurnAround()
    while robot.count(firstLootSlot) > 0 do
      robot.drop(3)
    end
    rTurnAround()
  end
  return firstLootSlot
end

local function slotClearing(slot)
  slot = slot or robot.select()
  if robot.count(slot) > 0 then
    robot.select(slot)
    rTurnAround()
    while robot.count(slot) > 0 do
      robot.drop(3)
    end
    rTurnAround()
  end
  return slot
end

local function swingTechBlock(tSlot)
  robot.select(slotClearing(tSlot))
  rSwing()
end

local function searchCrystalInChest()
  while true do
    for slot = 1, inv.getInventorySize(3) do
      local infStack = inv.getStackInSlot(3, slot)
      if infStack and infStack.label == energyCrystalLable and infStack.charge == infStack.maxCharge then
        return slot
      end
    end
  end
end

local function suckCrystalFromChest()
  local freeSlot = freeSlotSearch()
  local cSlotInChest = searchCrystalInChest()
  robot.select(freeSlot)
  if inv.suckFromSlot(3, cSlotInChest, 1) then
    local infStack = inv.getStackInInternalSlot(freeSlot)
    if infStack and infStack.label == energyCrystalLable and infStack.charge == infStack.maxCharge then
      return freeSlot
    else
      for slot = 1, invSize do
        if robot.count(slot) > 0 then
          local infStack = inv.getStackInInternalSlot(slot)
          if infStack and infStack.label == energyCrystalLable then
            if robot.count(slot) > 1 then
              robot.select(slot)
              rTurnAround()
              while robot.count(slot) > 1 do
                robot.drop(3, 1)
              end
              rTurnAround()
              return slot
            else
              return slot
            end
          end
        end
      end
    end
  end
end

local function lootUnload()
  for slot = firstLootSlot, invSize do
    while robot.count(slot) > 0 do
      robot.select(slot)
      robot.drop(3)
    end
  end
end

local function lootSend()
  rPlace(chestLootSlot)
  lootUnload()
  swingTechBlock(chestLootSlot)
  moveToPreviousPosition()
end

local function chargingInStorage()
  inv.equip()
  if inv.dropIntoSlot(3, 1) then --Помещение инструмента в первый слот МФЭ
    while inv.getStackInSlot(3, 1).charge < inv.getStackInSlot(3, 1).maxCharge do
      os.sleep(1)
    end
    slotClearing()
    inv.suckFromSlot(3, 1)
  end
  inv.equip()
end

local function checkWrench()
  local infStack = inv.getStackInInternalSlot(wrenchSlot)
  if infStack.charge < infStack.maxCharge then
    robot.select(wrenchSlot)
    inv.equip()
    chargingInStorage()
    inv.equip()
  end
end

local function swingMFE()
  robot.select(slotClearing(energyCrystalSlot)) --Очистка и выбор слота с кристаллом
  while not inv.suckFromSlot(3, 2) do end --Высасывания кристалла из МФЭ
  robot.select(wrenchSlot) --Выбор слота с ключем
  inv.equip() --Экипировка
  robot.select(slotClearing(MFESlot))
  robot.use(3) --Откручивание МФЭ
  robot.select(wrenchSlot) --Выбор слота с ключем
  inv.equip() --Экипировка
  rMoveForward() --Перемещение робота на один блок вперед
  robot.select(energyCrystalSlot) --Выбор слота с кристаллом
  while not robot.drop(3) do end --Помещение кристалла в сундук
  swingTechBlock(chestChargeSlot) --Ломания сундука с прибамбасами
  moveToPreviousPosition() --Возвращение на предыдущую позицию после установки сундука
  energyCrystalSlot = nil
end

local function placeMFE()
  rPlace(chestChargeSlot) --Установка сундука с кристаллами
  local cSlot
  while not cSlot do --Высасывания полностью заряженного кристалла из сундука в свободный слот инвентаря робота
    cSlot = suckCrystalFromChest()
  end
  rMoveBack() --Движение на один блок назад
  rPlace(MFESlot) --Установка МФЭ
  robot.select(cSlot) --Выбор слота с кристаллом
  inv.dropIntoSlot(3, 2) --Засунуть кристалл во второй слот МФЭ
  energyCrystalSlot = cSlot
  checkWrench() --Проверка потребности зарядить ключ, если нужно, то зарядить
end

local function robotCharging()
  placeMFE()
  rMoveBack() --Перемещения робота на один блок назад
  rPlace(powerConverterSlot) --Установка преобразователя
  rMoveBack() --Перемещения робота на один блок назад
  rPlace(chargerSlot) --Установка зарядника
  rs.setOutput(3, 15) --Подача редстоун сигнала на зарядник
  while computer.energy() < computer.maxEnergy() * 0.95 do --Ожидание пока робот зарядится до 95%
    os.sleep(1)
  end
  rs.setOutput(3, 0) --Отключения редстоун сигнала
  swingTechBlock(chargerSlot) --Ломание зарядника
  rMoveForward() --Перемещения на один блок вперед
  swingTechBlock(powerConverterSlot) --Ломания преобразователя
  rMoveForward() --Перемещения на один блок вперед
  swingMFE()
end

local function toolCharging()
  placeMFE() --Установка сундука с кристаллами, установка МФЭ, помещения кристалла в МФЭ
  chargingInStorage() --Зарядка экипированного инструмента (бура)
  swingMFE() --Высасывание кристалла с МФЭ, откручивание МФЭ ключем, помещение кристалла в сундук с кристаллами, ломания сундука с кристаллами и возвращение на начальную позицию
end

local function checkInventory()
  if robot.count(invSize - 1) > 0 then
    lootSend()
  end
end

local function checkRobotCharge()
  if computer.energy() < computer.maxEnergy() * minRobotChargeLevel then
    robotCharging()
  end
end

local function checkToolCharge()
  inv.equip()
  local infStack = inv.getStackInInternalSlot()
  inv.equip()
  if infStack.charge < infStack.maxCharge * minToolChargeLevel then
    toolCharging()
  end
end

local function checkService()
  if countSwing >= numBetChecks then
    countSwing = 0
    checkToolCharge()
    checkRobotCharge()
    checkInventory()
  end
end

local function goToNewCircle()
  print("Круг "..circle)
  rTurnL()
  rMoveForward()
  rTurnR()
  rMoveForward()
end

local function oneCircle()
  goToNewCircle()
  for side = 1, 4 do
    rTurnR()
    for len = 1, circle * 2 do
      rMoveForward()
      checkService()
    end
  end
  circle = circle + 1
end

local function getNumCircle()
  print("Ведите круг с которого следует начать или просто нажмите Enter если нужно начать с первого круга")
  local num = tonumber(io.read())
  if num then
    circle = num
  end
end

local function main()
  getNumCircle()
  while true do
    oneCircle()
  end
end

main()
