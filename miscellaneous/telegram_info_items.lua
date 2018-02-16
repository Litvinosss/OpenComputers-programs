local com = require("component")
local telegram = require("Telegram")

local ae = com.me_controller

local token = "token" --Токен бота ServerHiTech
local chat_id = chat_id --chat id username: "Litvinosss"
local max_string_length = 4000 --Максимальная длина строки для отправки в одном сообщении в телеграмм

local function send_msg_to_telegram(tbl_with_str)
  for k, v in pairs(tbl_with_str) do
    telegram.sendMessage(token, chat_id, v)
  end
end

local function getMEItems(itemName)
  local store_items = ae.getItemsInNetwork() --Получаем все предметы из МЭ сети
  local tbl_length = store_items.n --Записываем длину таблицы с элементами в переменную
  local tbl_strings = {[1] = ""} --Создаем таблицу для выходной строки(строк)

  local function add_str_to_tbl(str, tbl) --Функция добавления заданой строки в заданую таблицу
    if #tbl[#tbl] + #str > max_string_length then --Если длина последнего значения в таблице плюс длина строки которую нужно добавить, превышает значение max_string_length, то добавляем строку в новое поле таблицы
      tbl[#tbl + 1] = str
    else --Если нет, то
      tbl[#tbl] = tbl[#tbl]..str --Присоединяем к последнему значению в таблице указанную строку
    end
  end

  if itemName then --Если указано название предмета, то вернуть информацию только об этом предмете
    for i = 1, tbl_length do
      if itemName == store_items[i].name or itemName == store_items[i].label then
        add_str_to_tbl("Info about "..itemName..":\n", tbl_strings)
        if itemName == store_items[i].name then
          add_str_to_tbl("Label = "..store_items[i].label.."\n", tbl_strings)
        elseif itemName == store_items[i].label then
          add_str_to_tbl("Name = "..store_items[i].name.."\n", tbl_strings)
        end
        add_str_to_tbl("Number = "..store_items[i].size.."\n", tbl_strings)
        if store_items[i].maxSize ~= 64 then
          add_str_to_tbl("Max num in stack = "..store_items[i].maxSize.."\n", tbl_strings)
        end
        if store_items[i].maxDamage ~= 0 then
          add_str_to_tbl("Damage = "..store_items[i].damage.."\n", tbl_strings)
          add_str_to_tbl("Max damage = "..store_items[i].maxDamage.."\n", tbl_strings)
        end
      end
    end
    if tbl_strings[#tbl_strings] == "" then --Если указанный предмет не совпал ни с одним из существующих, таблица содержит пустую строку
      add_str_to_tbl("Info about this item is missing", tbl_strings)
    end
  else --Название предмета не указано, вернуть информацию о всех предметах
    add_str_to_tbl("Info about all items: ".."\n", tbl_strings) --Добавляем начальную строку в таблицу
    local num_item = 0 --Подсчет реального количества предметов без учета Air
    for i = 1, tbl_length do --Цикл по таблице со всеми предметами
      if store_items[i].label ~= "Air" then --Исключаем Air
        num_item = num_item + 1 --Повышаем количество реальных предметов на 1
        --Соединяем в одну строку название предмета и его количество, в конце добавляем перенос строки
        local str_items = num_item..") "..store_items[i].label.." = "..store_items[i].size.."\n"
        add_str_to_tbl(str_items, tbl_strings) --Добавляем сформированную строку в таблицу
      end
    end
  end
  return tbl_strings
end

while true do
  local received_msg_from_telegram = telegram.receiveMessages(token)
  if received_msg_from_telegram[1] then
    local received_msg_text = received_msg_from_telegram[1].text
    print("Receive messages: "..received_msg_text)
    if received_msg_text == "Test" or received_msg_text == "test" or received_msg_text == "Тест" or received_msg_text == "тест" then
      telegram.sendMessage(token, chat_id, "Заебал своими тестами")
    else
      if received_msg_text == "getMEItems" then
        send_msg_to_telegram(getMEItems())
      else
        send_msg_to_telegram(getMEItems(received_msg_text))
      end
    end
  end
  os.sleep(1)
end
