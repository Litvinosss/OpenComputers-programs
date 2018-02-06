--MinerService v2
local tr = component.proxy(component.list("transposer")())

local energyCrystalLable = "Energy Crystal"
local eStorageSide = 5
local chestSide = 0
local invSize = tr.getInventorySize(chestSide)

local function sleep(timeout)
  checkArg(1, timeout, "number", "nil")
  local deadline = computer.uptime() + (timeout or 0)
  repeat
    computer.pullSignal(deadline - computer.uptime())
  until computer.uptime() >= deadline
end

local function searchFreeSlot()
  for slot = 1, invSize do
    local stackSize = tr.getSlotStackSize(chestSide, slot)
    if stackSize == 0 then
      return slot
    end
  end
end

local function charge(slot)
  if tr.transferItem(chestSide, eStorageSide, 1, slot, 1) then
    while tr.getStackInSlot(eStorageSide, 1).charge < tr.getStackInSlot(eStorageSide, 1).maxCharge do
      sleep(1)
    end
    while not tr.transferItem(eStorageSide, chestSide, 1, 1, searchFreeSlot()) do end
  end
end

local function sortCrystal(cSlot)
  while tr.getSlotStackSize(chestSide, cSlot) > 1 do
    tr.transferItem(chestSide, chestSide, 1, cSlot, searchFreeSlot())
  end
end

while true do
  for slot = 1, invSize do
    local stackSize = tr.getSlotStackSize(chestSide, slot)
    if stackSize == 1 then
      local infStack = tr.getStackInSlot(chestSide, slot)
      if infStack and infStack.label == energyCrystalLable and infStack.charge < infStack.maxCharge then
        charge(slot)
      end
    elseif stackSize > 1 then
      sortCrystal(slot)
    end
  end
  sleep(8)
end
