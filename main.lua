local graph = require("graph")
local unicode = require("unicode")
local gpu = require("component").gpu
local me = require("component").me_controller
local computer = require("computer")

local items = require("items.lua")
local precrafting = {}
local timers = {}
local intervals = {}
local messages = {}
local maxMessageCount = 33
local formatSymbols = { "", "K", "M", "G", "T" }

function getUptime() return computer.uptime() end
function setTimer(seconds, callback) table.insert(timers, { moment = getUptime(), length = seconds, callback = callback }) end
function updateTimers() for i = 1, #timers do local timer = timers[i]; if(timer ~= nil) then if(getUptime() - timer.moment >= timer.length) then timers[i] = nil; timer.callback(); end end end end
function setInterval(name, delay, callback) table.insert(intervals, { name = name, delay = delay, callback = callback, lastExecuted = getUptime() }) end
function removeInterval(name) for i = 1, #intervals do if(intervals[i].name == name) then table.remove(intervals, i); break; end end end
function updateIntervals() for i = 1, #intervals do local interval = intervals[i]; if (interval ~= nil) then local div = getUptime() - interval.lastExecuted; if (div >= interval.delay) then intervals[i].lastExecuted = getUptime(); interval.callback(); end end end end
function formatNumber(num) local formattedNum = num; local symbolIndex = 1 while formattedNum >= 1000 do formattedNum = formattedNum / 1000; symbolIndex = symbolIndex + 1 end formattedNum = string.format("%.1f", formattedNum) if formattedNum:sub(-2) == ".0" then formattedNum = formattedNum:sub(1, -3) end return formattedNum .. formatSymbols[symbolIndex] end
function message(text) if(#messages == maxMessageCount) then table.remove(messages, #messages) end table.insert(messages, 1, {text = text .. string.rep(" ", 160-string.len(text)), id = math.random()}) end
function renderChat() local w, h = gpu.getResolution(); for i = 1, #messages do graph.text(messages[i].text, 2, (h - i*1) - 2, 0x141414) end end
function renderStatus()
    graph.text("#7f95ffСтатус предметов", 2, 1, 0x141414); graph.text("#5e5e5e —————————", 5, 2, 0x141414)
    local i = 1; local maxLengthName = 0; local maxLengthStatus = 0
    for name, status in pairs(items) do
        local res = string.format("%s", getItemLabel(name))
        if(unicode.len(res) > maxLengthName) then maxLengthName = unicode.len(res) end
    end
    for name, status in pairs(items) do
        local count = string.format("%s/%s", formatNumber(getItemCount(name)), formatNumber(status.count))
        if(unicode.len(count) > maxLengthStatus) then maxLengthStatus = unicode.len(count) end
    end
    for name, status in pairs(items) do
        local label = getItemLabel(name)
        local count = string.format("%s/%s", formatNumber(getItemCount(name)), formatNumber(status.count))
        local res = string.format("%s%s#a3a3a3%s", label, string.rep(" ", 3 + maxLengthName - unicode.len(label)), count)
        local isCanCraft = items[name].status
        if (isCanCraft == nil) then isCanCraft = "" end
        graph.text(res .. "#ff3b3b" .. string.rep(" ", maxLengthStatus + 3 - unicode.len(isCanCraft)) ..  isCanCraft .. string.rep(" ", 40-string.len(res)), 2, 2 + i, 0x141414)
        i = i + 1
    end
end
function requestItem(name, count)
    assert(me.getCraftables({name = name})[1], "Крафт данного предмета невозможен из-за отсутствия рецепта")
    assert(type(count) == "number", "Параметр count может быть только числом")
    if(items[name].split ~= nil) then
        if(count > items[name].split) then count = items[name].split
        if count < items[name].split then assert(nil, "Параметр split не должен быть больше count") end
    end end
    local craftable = me.getCraftables({name = name})[1].request(count)
    local canceled, reason = craftable.isCanceled()
    if (reason == "request failed (missing resources?)") then items[name].status = "Недостаточно ресурсов для крафта"; return nil end
    if (reason == "computing") then items[name].status = "Нет доступных процессоров" end
    precrafting[name] = {count = count, craftable = craftable, active = true}
    message(string.format("#bbf2bb> #ffffffЗаказываю #a3a3a3x%s #ffffff%s", formatNumber(count), getItemLabel(name)))
    items[name].status = nil
    return craftable
end
function getItemCount(name)
    local item = me.getItemsInNetwork({name = name})[1]; assert(item, "Предмет не найден в сети")
    local size = math.floor(item.size); assert(size > 0, "Работа с числами больше чем 2^31 не поддерживается")
    return size
end
function getItemLabel(name)
    local item = me.getItemsInNetwork({name = name})[1]; assert(item, "Предмет не найден в сети")
    return item.label
end
function updatePrecrafts()
    for name, info in pairs(items) do
        local target = info.count; local count = getItemCount(name)
        if(precrafting[name] == nil) then if(getFreeCpus() > 0) then if (target > count) then local need = target - count; requestItem(name, need) end end end
    end
end
function updatePrecrating()
    for precraft, status in pairs(precrafting) do
        local canceled, reason = status.craftable.isCanceled()
        if(status.craftable.isDone() and status.active == true) then message(string.format("#2fff1c> #ffffffДоделано: %s", getItemLabel(precraft))); precrafting[precraft] = nil;
        end
        if(canceled and reason == "request failed (missing resources?)") then
            if(items[precraft].status == nil) then message(string.format("#ff3b3bПри выполнении заказа %s была поймана ошибка", getItemLabel(precraft))) end
            items[precraft].status = "Нет доступных процессоров";
        return end
        if(canceled and status.active == true) then
            precrafting[precraft].active = false
            message(string.format("#ff3b3bОтменено: %s, повторный заказ будет через 30 секунд", getItemLabel(precraft)))
            setTimer(30, function () precrafting[precraft] = nil; updatePrecrafts() end)
        end
    end
end
function getNeededItemsCount() i = 0; for k, v in pairs(items) do i = i + 1 end; return i end
function getPrecraftingItemsCount() i = 0; for k, v in pairs(precrafting) do i = i + 1 end; return i end
function split(text, char) local response = {}; for i in string.gmatch(text, string.format("([^%s]+)", char)) do table.insert(response, i) end; return response end
function join(list, char) return table.concat(list, char) end
function getMaxLength(list) local length = 0; for i=1, #list do if(unicode.len(list[i]) > length) then length = unicode.len(list[i]) end end return length end
function getCpusCount() return #me.getCpus() end
function getBusyCpus()
    local cpus = me.getCpus()
    local busy = {}
    for i=1, #cpus do
        local cpu = cpus[i]
        if(cpu.busy) then table.insert(busy, cpu) end
    end
    return busy
end
function getFreeCpus() return getCpusCount() - #getBusyCpus() end

local buttons = {} -- Хз как сделать норм работу кнопкам :(
function setScreen(screen, btn)
    gpu.setResolution(120, 37.5); graph.setBackground(0x141414); graph.reset()
    buttons = {}
    if(btn ~= nil) then for i=1, #btn do table.insert(buttons, btn[i]); btn[i]:render(); end end
    currentScreen = screen
end
function renderCurrentScreen() -- Дайте свитчкей!
    if(currentScreen == "main") then renderChat(); renderStatus()
end end
function renderWelcome()
    local w, h = gpu.getResolution();
    local welcome = {
        [[  ______    _                               _______                                         ___  _    ]],
        [[.' ____ \  (_)                             |_   __ \                                      .' ..]/ |_  ]],
        [[| (___ \_| __   .--./) _ .--..--.   ,--.     | |__) |_ .--.  .---.  .---.  _ .--.  ,--.  _| |_ `| |-' ]],
        [[ _.____`. [  | / /'`\;[ `.-. .-. | `'_\ :    |  ___/[ `/'`\]/ /__\\/ /'`\][ `/'`\]`'_\ :'-| |-' | |   ]],
        [[| \____) | | | \ \._// | | | | | | // | |,  _| |_    | |    | \__.,| \__.  | |    // | |, | |   | |,  ]],
        [[ \______.'[___].',__` [___||__||__]\'-;__/ |_____|  [___]    '.__.''.___.'[___]   \'-;__/[___]  \__/  ]],
        [[              ( ( __))                                                                                ]] }
    local max = getMaxLength(welcome)
    for i=1, #welcome do graph.text("#fffa73" .. welcome[i], w/2 - max/2, h/2+i-#welcome+1, 0x141414) end
end

assert(getNeededItemsCount() <= 20, "Максимальное число поддерживаемых предметов - 20"); assert(getCpusCount() > 0, "Не найдено ни одного процессора!")

maxMessageCount = maxMessageCount - getNeededItemsCount() - 1
message(graph.linearGradientText("Программа запущена.", "#ffa51f", "#ffe91f"))
if(getNeededItemsCount() == 0) then message("#cfcfcf(?) Для работы необходимо настроить предметы.") end
message(string.rep(" ", 160))

setScreen("start", {})
renderWelcome()
setTimer(3, function() setScreen("main", {}) end)

setInterval("main", 0.5, function() updatePrecrafts(); updatePrecrating(); renderCurrentScreen(); end)
while true do
    updateTimers()
    updateIntervals()
end