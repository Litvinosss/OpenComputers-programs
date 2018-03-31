local computer = require('computer')
local event = require('event')
local com = require('component')
local telegram = require('Telegram')

local ae = com.me_controller

local token = '' --Токен бота ServerHiTech
local chat_id = chatId --chat id username:
local max_string_length = 4000 --Максимальная длина строки для отправки в одном сообщении в телеграмм

local old_items_list = {}

local function send_msg(arg)
  if type(arg) == 'table' then
    for k, v in pairs(arg) do
      telegram.sendMessage(token, chat_id, v)
    end
  elseif type(arg) == 'string' then
    telegram.sendMessage(token, chat_id, arg)
  end
end

local function get_all_items_list()
  local stored_items = ae.getItemsInNetwork()
  local cur_stored_items = {}
  for i = 1, stored_items.n do --Цикл по таблице со всеми предметами
    if stored_items[i].label ~= 'Air' and stored_items[i].size > 0 then --Исключаем несуществующие предметы
      table.insert(cur_stored_items, stored_items[i])
    end
  end
  return cur_stored_items
end

local function get_info_items(all)
  local stored_items = ae.getItemsInNetwork() --Получаем все предметы из МЭ сети
  local info_items = {}
  local strs_tbl = {''}

  local function table_concat(tbl, str)
    if #tbl[#tbl] + #str > max_string_length then --Если длина последнего значения в таблице плюс длина строки которую нужно добавить, превышает значение max_string_length, то добавляем строку в новое поле таблицы
      tbl[#tbl + 1] = str
    else --Если нет, то
      tbl[#tbl] = tbl[#tbl]..str --Присоединяем к последнему значению в таблице указанную строку
    end
  end

  local function get_all_items()
    table_concat(strs_tbl, 'Info about all items: \n')
    for i = 1, stored_items.n do --Цикл по таблице со всеми предметами
      if stored_items[i].label ~= 'Air' and stored_items[i].size > 0 then --Исключаем несуществующие предметы
        table.insert(info_items, {stored_items[i].label, stored_items[i].size})
      end
    end
    table.sort(info_items, function(lhs, rhs) return lhs[2] > rhs[2] end) --Сортируем таблицу в порядке убывания
    for k, v in pairs(info_items) do
      table_concat(strs_tbl, k..') '..v[1]..' = '..v[2]..'\n')
    end
  end

  local function get_item(item_name)
    for i = 1, stored_items.n do
      local lbl = stored_items[i].label:lower()
      local name = stored_items[i].name:lower()
      if item_name == lbl or item_name == name then
        table_concat(strs_tbl, 'Info about '..stored_items[i].label..':\n')
        table_concat(strs_tbl, 'Name = '..stored_items[i].name..'\n')
        table_concat(strs_tbl, 'Quantity = '..stored_items[i].size..'\n')
        if stored_items[i].maxSize ~= 64 then
          table_concat(strs_tbl, 'Max num in stack = '..stored_items[i].maxSize..'\n')
        end
        if stored_items[i].maxDamage ~= 0 then
          table_concat(strs_tbl, 'Damage = '..stored_items[i].damage..'\n')
          table_concat(strs_tbl, 'Max damage = '..stored_items[i].maxDamage..'\n')
        end
      end
    end
    if strs_tbl[1] == '' then --Если указанный предмет не совпал ни с одним из существующих, таблица содержит пустую строку
      table_concat(strs_tbl, 'Info about this item is missing')
    end
  end

  if all then
    all = all:lower()
    if all == 'all' then
      get_all_items()
    else
      get_item(all)
    end
    return strs_tbl
  end
end

local function compare_items(item)
  for k, v in pairs(old_items_list) do -- Цикл по старом списке предметов
    if item.label == v.label and item.name == v.name then -- Если label и name текущего предмета равны старому предмету
      table.remove(old_items_list, k)
      -- old_items_list[k] = nil
      if item.size ~= v.size then -- Если количество текущего и старого предмета НЕ равно, то возвращаем разницу
        return {['label'] = item.label, ['name'] = item.name, ['old_size'] = v.size, ['cur_size'] = item.size, ['value_changed'] = item.size - v.size}
      else -- Если количество равно
        return false
      end
    end
  end
  return {['label'] = item.label, ['name'] = item.name, ['old_size'] = 0, ['cur_size'] = item.size, ['value_changed'] = item.size} -- Если весь цикл завершился и не было найдено совпадения, значит это новый предмет в текущем списке. Возвращаем его количество
end

local function check_num_items()
  local changed_items = {} -- Сюда будем записывать предметы количество которых было изменено

  for k, v in pairs(get_all_items_list()) do -- Цикл по текущему списку предметов
    local chen_item = compare_items(v)
    if chen_item then -- Если количество предмета изменилось
      table.insert(changed_items, chen_item)
    end
  end

  for k, v in pairs(old_items_list) do -- Добавляем всё то что осталось в старом списке(в новом списке таких предметов вообще нет) в список предметов количество которых изменилось
    table.insert(changed_items, {['label'] = v.label, ['name'] = v.name, ['old_size'] = v.size, ['cur_size'] = 0, ['value_changed'] = -v.size})
  end

  old_items_list = get_all_items_list() -- Обновляем старый лист предметов на текущий лист предметов

  if #changed_items > 0 then -- Если есть предметы количество которых изменилось
    local str_to_send = "Items whose quantity has been changed:\nList format: [item label] = [old quantity], [current quantity], [difference]"
    for k, v in pairs(changed_items) do
      str_to_send = str_to_send..'\n'..k..') '..v.label..' = '..v.old_size..', '..v.cur_size..', '..v.value_changed
    end
    return str_to_send
  else
    return 'The quantity of items has not changed'
  end
end

local functions = {
  ['get_info'] = function(arg)
    send_msg(get_info_items(arg))
  end,

  ['get_difference'] = function()
    send_msg(check_num_items())
  end,

  ['send_me'] = function(arg)
    if arg then
      send_msg(arg)
    else
      send_msg('Missing argument')
    end
  end,

  ['computer'] = function(arg)
    if arg == 'reboot' then
      send_msg('Restarting the computer...')
      computer.shutdown(true)
    end
  end,
}

local function go(msg)
  local func = msg:match('%S+'):lower()
  if functions[func] then
    local arg = msg:match('%s+.+')
    if arg then
      arg = arg:match('%S+.*'):lower()
    end
    functions[func](arg)
  else
    send_msg('Inexact command')
  end
end

telegram.getUpdates(token)
send_msg('The computer is running')
old_items_list = get_all_items_list()

while true do
  local received_msg = telegram.receiveMessages(token)
  if received_msg[1] then
    go(received_msg[1].text)
    print(received_msg[1].text)
  end
  os.sleep(3)
end

-- event.timer(1, check_num_items)
-- os.sleep(5)
