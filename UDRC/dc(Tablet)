--Universal drone remote control(tablet) version: 1.0 by Litvinov
local com = require('component')
local event = require('event')
local keyboard = require('keyboard')
local term = require('term')

local gpu = com.gpu
local nav
local m

local receivePort = 1011
local sendPort = 1010
local wRes, hRes = gpu.maxResolution()
local step = 1
local acceleration
local sideInt = 0
local navigationSides = false

local colors = {
  white = 0xFFFFFF,
  black = 0x000000,
  gray = 0x2D2D2D,
  green = 0x00FF00,
  yellow = 0xFFFF00
}

local navSides = {
  ['forward'] = {
    [2] = {['z'] = '-'},
    [3] = {['z'] = ''},
    [4] = {['x'] = '-'},
    [5] = {['x'] = ''}
  },
  ['back'] = {
    [2] = {['z'] = ''},
    [3] = {['z'] = '-'},
    [4] = {['x'] = ''},
    [5] = {['x'] = '-'}
  },
  ['right'] = {
    [2] = {['x'] = ''},
    [3] = {['x'] = '-'},
    [4] = {['z'] = '-'},
    [5] = {['z'] = ''}
  },
  ['left'] = {
    [2] = {['x'] = '-'},
    [3] = {['x'] = ''},
    [4] = {['z'] = ''},
    [5] = {['z'] = '-'}
  }
}

local answers = {
  ['ping'] = function(_, _, _, _, distance)
    gpu.fill(1, 12, wRes, 1, ' ')
    gpu.set(1, 12, 'Расстояние к дрону: '..math.floor(distance))
  end,
  ['cAcceleration'] = function(_, _, _, _, _, _, cAcceleration)
    gpu.setForeground(colors.green)
    gpu.fill(13, 5, 4, 1, ' ')
    gpu.set(13, 5, ''..cAcceleration)
    gpu.setForeground(colors.white)
    acceleration = cAcceleration
  end,
  ['cSelectSlot'] = function(_, _, _, _, _, _, cSelectSlot, selectCount)
    gpu.setForeground(colors.green)
    gpu.set(23, 7, ''..cSelectSlot)
    gpu.fill(41, 8, 2, 1, ' ')
    gpu.set(41, 8, ''..selectCount)
    gpu.setForeground(colors.white)
  end,
}

local function droneMsg(...)
  local msg = {...}
  for answer in pairs(answers) do
    if answer == msg[6] then
      answers[msg[6]](...)
      break
    end
  end
end

local function send(...)
  m.broadcast(sendPort, ...)
end

local function programExit()
  gpu.setResolution(wRes, hRes)
  term.clear()
  m.close(receivePort)
  event.ignore('modem_message', droneMsg)
  os.exit()
end

local function infoInit()
  gpu.fill(1, 2, wRes, hRes - 2, ' ')
  gpu.setForeground(colors.gray)
  gpu.fill(1, 3, wRes, 1, '-')
  gpu.fill(1, 10, wRes, 1, '-')
  gpu.setForeground(colors.white)
  gpu.set(1, 4, 'Шаг - ')
  gpu.set(1, 5, 'Ускорение - ')
  gpu.set(1, 6, 'Сторона взаимодействия - ')
  gpu.set(1, 7, 'Активный слот дрона - ')
  gpu.set(1, 8, 'Количество предметов в активном слоте - ')
  gpu.set(1, 9, 'Управления с учётом направления взгляда - ')
  gpu.setForeground(colors.green)
  gpu.set(7, 4, ''..step)
  send('getAcceleration')
  gpu.set(26, 6, ''..sideInt)
  send('select', 1)
  gpu.set(43, 9, ''..tostring(navigationSides))
  gpu.setForeground(colors.white)
end

local function initInterface()
  gpu.setResolution(wRes, hRes)
  gpu.setBackground(colors.black)
  term.clear()
  gpu.setBackground(colors.gray)
  gpu.fill(1, 1, wRes, 1, ' ')
  gpu.fill(1, hRes, wRes, 1, ' ')
  gpu.setForeground(colors.yellow)
  gpu.set((wRes - 30) / 2, 1, 'Universal drone remote control')
  gpu.setForeground(colors.green)
  gpu.set(1, hRes, 'Q')
  gpu.set(24, hRes, 'M')
  gpu.setForeground(colors.white)
  gpu.set(3, hRes, '- закрыть программу;')
  gpu.set(26, hRes, '- показать инструкцию;')
  gpu.setBackground(colors.black)
  infoInit()
end

local function initialization()
  if com.isAvailable('modem') then
    m = com.modem
    m.open(receivePort)
    event.listen('modem_message', droneMsg)
    if com.isAvailable('navigation') then
      nav = com.navigation
    end
    initInterface()
  else
    io.stderr:write('Плата беспроводной сети не обнаружена!')
    os.exit()
  end
end

local function manual()
  if gpu.getResolution() == gpu.maxResolution() then
    gpu.fill(1, 2, wRes, hRes - 2, ' ')
    gpu.setForeground(colors.green)
    gpu.set(1, 3, 'WASD')
    gpu.set(1, 4, 'LShift/LCtrl')
    gpu.set(1, 5, 'R/F')
    gpu.set(1, 6, 'T/G')
    gpu.set(1, 7, 'Y/H')
    gpu.set(1, 8, 'C/X')
    gpu.set(1, 9, 'U/J')
    gpu.set(1, 10, 'I/K')
    gpu.set(1, 11, 'O/L')
    gpu.set(1, 12, '1-8')
    gpu.set(1, 13, 'B')
    gpu.set(1, 14, 'N')
    gpu.set(1, 15, 'P')
    gpu.set(1, 16, 'V')
    gpu.set(1, 17, 'Z')
    gpu.set(1, 18, 'E')
    gpu.setForeground(colors.white)
    gpu.set(6, 3, '- горизонтальное перемещение')
    gpu.set(14, 4, '- вверх/вниз')
    gpu.set(5, 5, '- сломать/установить блок')
    gpu.set(5, 6, '- захватить/выбросить предмет')
    gpu.set(5, 7, '- захватить все возможные предметы/выбросить все возможные предметы')
    gpu.set(5, 8, '- попытаться захватить со всех сторон существо поводком/сбросить')
    gpu.set(5, 9, '- увеличть/уменишить шаг')
    gpu.set(5, 10, '- увеличть/уменишить ускорение')
    gpu.set(5, 11, '- изменить сторону взаимодействия')
    gpu.set(5, 12, '- сделать активным слот')
    gpu.set(3, 13, '- перемещение на координаты')
    gpu.set(3, 14, '- вкл/выкл управление с учётом направления взгляда')
    gpu.set(3, 15, '- показать расстояние к дрону')
    gpu.set(3, 16, '- установить случайный цвет дрона')
    gpu.set(3, 17, '- выкл/вкл дрон')
    gpu.set(3, 18, '- уменьшить/увеличить экран')
    gpu.set(1, 20, 'Нажмите любую клавишу что бы скрыть инструкцию...')
    event.pull('key_down')
    infoInit()
  end
end

local function changeResolution()
  if gpu.getResolution() == gpu.maxResolution() then
    gpu.setResolution(2, 2)
  else
    initInterface()
  end
end

local function changeStep(plus)
  if plus then
    if step < 1 then
      step = step + 0.1
    elseif step >= 1 and step < 10 then
      step = step + 1
    elseif step >= 10 and step < 100 then
      step = step + 10
    elseif step >= 100 and step < 1000 then
      step = step + 100
    end
  else
    if step > 0.3 and step <= 1 then
      step = step - 0.1
    elseif step > 1 and step <= 10 then
      step = step - 1
    elseif step > 10 and step <= 100 then
      step = step - 10
    elseif step > 100 and step <= 1000 then
      step = step - 100
    end
  end
  gpu.fill(7, 4, 4, 1, ' ')
  gpu.setForeground(colors.green)
  gpu.set(7, 4, ''..step)
  gpu.setForeground(colors.white)
end

local function changeAcceleration(plus)
  if plus then
    if acceleration < 2 then
      acceleration = acceleration + 0.5
      send('setAcceleration', acceleration)
    end
  else
    if acceleration > 0.5 then
      acceleration = acceleration - 0.5
      send('setAcceleration', acceleration)
    end
  end
end

local function changeSideInt(plus)
  if plus then
    if sideInt < 5 then
      sideInt = sideInt + 1
    end
  else
    if sideInt > 0 then
      sideInt = sideInt - 1
    end
  end
  gpu.setForeground(colors.green)
  gpu.set(26, 6, ''..sideInt)
  gpu.setForeground(colors.white)
end

local function changeNavigation()
  if navigationSides then
    navigationSides = false
  else
    if nav then
      navigationSides = true
    else
      term.setCursor(1, 12)
      io.stderr:write('Улучшение "Навигация" отсуствует')
    end
  end
  gpu.fill(43, 9, 5, 1, ' ')
  gpu.setForeground(colors.green)
  gpu.set(43, 9, ''..tostring(navigationSides))
  gpu.setForeground(colors.white)
end

local function goTo()
  term.setCursor(1, 12)
  io.write('Введите координаты дрона:\n')
  io.write('Позиция X = ')
  local posX = tonumber(io.read()) or 0
  io.write('Позиция Z = ')
  local posZ = tonumber(io.read()) or 0
  io.write('Введите координаты точки назначения:\n')
  io.write('Позиция X = ')
  local goX = tonumber(io.read()) or 0
  io.write('Позиция Z = ')
  local goZ = tonumber(io.read()) or 0
  io.write('Введите высоту полёта на которой нет препятсвий для робота:\n')
  io.write('Высота Y = ')
  local goY = tonumber(io.read()) or 0
  io.write('\nПеремещение на высоту: Y = '..goY..';')
  send('move', 0, goY, 0)
  os.sleep(goY / 10)
  io.write('\nПеремещение на координаты: X = '..goX..'; Z = '..goZ..';')
  send('move', goX - posX, 0, goZ - posZ)
  os.sleep(5)
  gpu.fill(1, 12, wRes, 11, ' ')
end

local function droneMove(side)
  local playerDir = nav.getFacing()
  local x = tonumber(navSides[side][playerDir]['x'] and navSides[side][playerDir]['x']..step or 0)
  local z = tonumber(navSides[side][playerDir]['z'] and navSides[side][playerDir]['z']..step or 0)
  send('move', x, 0, z)
end

local commands = {
  ['w'] = function() if navigationSides then droneMove('forward') else send('move', step, 0, 0) end end,
  ['s'] = function() if navigationSides then droneMove('back') else send('move', -step, 0, 0) end end,
  ['a'] = function() if navigationSides then droneMove('left') else send('move', 0, 0, -step) end end,
  ['d'] = function() if navigationSides then droneMove('right') else send('move', 0, 0, step) end end,
  ['lshift'] = function() send('move', 0, step, 0) end,
  ['lcontrol'] = function() send('move', 0, -step, 0) end,
  ['r'] = function() send('swing', sideInt) end,
  ['f'] = function() send('place', sideInt) end,
  ['t'] = function() send('suck', sideInt) end,
  ['g'] = function() send('drop', sideInt) end,
  ['y'] = function() send('suckAll', sideInt) end,
  ['h'] = function() send('dropAll', sideInt) end,
  ['c'] = function() send('leash') end,
  ['x'] = function() send('unleash') end,
  ['u'] = function() changeStep(true) end,
  ['j'] = function() changeStep() end,
  ['o'] = function() changeSideInt(true) end,
  ['l'] = function() changeSideInt() end,
  ['i'] = function() changeAcceleration(true) end,
  ['k'] = function() changeAcceleration() end,
  ['1'] = function() send('select', 1) end,
  ['2'] = function() send('select', 2) end,
  ['3'] = function() send('select', 3) end,
  ['4'] = function() send('select', 4) end,
  ['5'] = function() send('select', 5) end,
  ['6'] = function() send('select', 6) end,
  ['7'] = function() send('select', 7) end,
  ['8'] = function() send('select', 8) end,
  ['b'] = function() goTo() end,
  ['n'] = function() changeNavigation() end,
  ['p'] = function() send('getPing') end,
  ['v'] = function() send('changeColor', math.random(0x0, 0xFFFFFF)) end,
  ['z'] = function() send('droneSwitch') end,
  ['e'] = function() changeResolution() end,
  ['m'] = function() manual() end,
  ['q'] = function() programExit() end
}

local function start()
  initialization()
  while true do
    local event, _, _, code = event.pull('key_down')
    local key = keyboard.keys[code]
    for command in pairs(commands) do
      if command == key then
          commands[key]()
        break
      end
    end
  end
end

start()
