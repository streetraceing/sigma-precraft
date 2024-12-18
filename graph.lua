local gpu = require("component").gpu
local unicode = require("unicode")
local graph = {}

local backgroundColor = 0x000000

function graph.reset() local w, h = graph.getResolution() graph.rectangle(0, 0, w/2, h, backgroundColor) graph.resetColor() end
function graph.setColor(color) gpu.setBackground(color); gpu.setForeground(0xffffff) end
function graph.resetColor() gpu.setBackground(backgroundColor) end
function graph.pixel(x, y, color) graph.setColor(color); gpu.fill(x + 1, y + 1, 1, 1, '　'); graph.resetColor() end
function graph.rectangle(x, y, width, height, color) graph.setColor(color); gpu.fill(x + 1, y + 1, width, height, '　'); graph.resetColor() end
function graph.getResolution() local w, h = gpu.getResolution(); return w, h end
function graph.setBackground(color) backgroundColor = color end
function graph.text(text, x, y, bgColor)
    local isColorCode = false
    local colorCode = ""
    local colorCodePosition = 0
    local cursor = 0

    for i = 1, unicode.len(text) do
        local char = unicode.sub(text, i, i)

        if (char == "#") then
            isColorCode = true
        else
            if isColorCode and colorCodePosition < 6 then
                colorCode = string.format("%s%s", colorCode, char)
                colorCodePosition = colorCodePosition + 1
            else
                if isColorCode and colorCodePosition == 6 then
                    gpu.setForeground(tonumber(string.format("0x%s", colorCode)))
                    isColorCode = false
                    colorCodePosition = 0
                    colorCode = ""
                    
                    cursor = cursor + 1
                    gpu.setBackground(bgColor)
                    gpu.set(x + cursor + 1, y + 1, char)
                else
                    cursor = cursor + 1
                    gpu.setBackground(bgColor)
                    gpu.set(x + cursor + 1, y + 1, char)
                end
            end
        end
    end
    gpu.setForeground(0xffffff)
    graph.resetColor()
end
local Button = {}
function Button:new(text, width, height)
    assert(width > 0, "Minimal width is 1"); assert(height > 0, "Minimal height is 1")
    local public = {}; public.text = text;   public.backgroundColor = "#ffffff"; public.textColor = "#000000"; public.x = 0;         public.y = 0;                       public.activeColor = "#adadad"; public.width = width; public.height = height;             public.callback = nil;
    function public:setPosition(x, y) public.x = x; public.y = y end; function public:setWidth(value) public.width = value end; function public:setHeight(value) public.height = value end; function public:setText(value) public.text = value end; function public:setBackgroundColor(value) public.backgroundColor = value end; function public:setTextColor(value) public.textColor = value end; function public:setActiveColor(value) public.activeColor = value end; function public:setCallback(func) if(type(func) == "function") then public.callback = func end end
    function public:render()
        local bgc = tonumber(string.format("0x%s", public.backgroundColor:sub(2)))
        graph.setColor(bgc); gpu.fill(public.x + 1, public.y + 1, public.width, public.height, ' '); graph.text(string.format("#%s%s", public.textColor, text), public.x - 1 + public.width/2 - unicode.len(text)/2, public.y + public.height / 2, bgc); graph.resetColor()
    end
    setmetatable(public, self); self.__index = self; return public
end
graph.Button = Button;
function rgb2hex(r, g, b) return string.format("#%02x%02x%02x", math.floor(r), math.floor(g), math.floor(b)) end
function hsl2rgb_helper(p, q, a)
    if a < 0 then a = a + 6 end; if a >= 6 then a = a - 6 end; if a < 1 then return (q - p) * a + p
    elseif a < 3 then return q; elseif a < 4 then return (q - p) * (4 - a) + p; else return p end
end
function hsl2rgb(h, s, l)
    local t1, t2, r, g, b
    h = h / 60
    if l <= 0.5 then t2 = l * (s + 1)
    else t2 = l + s - (l * s) end
    t1 = l * 2 - t2
    r = hsl2rgb_helper(t1, t2, h + 2) * 255; g = hsl2rgb_helper(t1, t2, h) * 255; b = hsl2rgb_helper(t1, t2, h - 2) * 255
    return r, g, b
end
function hsl2hex(h, s, l) local r, g, b = hsl2rgb(h, s, l); return rgb2hex(r, g, b) end
function rgb2hsl(r, g, b)
    local min, max, l, s, maxcolor, h
    r, g, b = r / 255, g / 255, b / 255
    min = math.min(r, g, b); max = math.max(r, g, b)
    maxcolor = 1 + (max == b and 2 or (max == g and 1 or 0))
    if maxcolor == 1 then h = (g - b) / (max - min)
    elseif maxcolor == 2 then h = 2 + (b - r) / (max - min)
    elseif maxcolor == 3 then h = 4 + (r - g) / (max - min) end
    if not rawequal(type(h), "number") then h = 0 end
    h = h * 60
    if h < 0 then h = h + 360 end
    l = (min + max) / 2
    if min == max then s = 0 else if l < 0.5 then s = (max - min) / (max + min) else s = (max - min) / (2 - max - min) end end
    return h, s, l
end
function hex2rgb(hex)
    local hash = string.sub(hex, 1, 1) == "#"
    if string.len(hex) ~= (7 - (hash and 0 or 1)) then return nil end
    local r = tonumber(hex:sub(2 - (hash and 0 or 1), 3 - (hash and 0 or 1)), 16)
    local g = tonumber(hex:sub(4 - (hash and 0 or 1), 5 - (hash and 0 or 1)), 16)
    local b = tonumber(hex:sub(6 - (hash and 0 or 1), 7 - (hash and 0 or 1)), 16)
    return r, g, b
end
function hex2hsl(hex) local r, g, b = hex2rgb(hex); return rgb2hsl(r, g, b) end
function graph.linearGradient(hex1, hex2, steps)
    local h1, s1, l1 = hex2hsl(hex1); local h2, s2, l2 = hex2hsl(hex2); local h, s, l
    local h_step = (h2 - h1) / (steps - 1); local s_step = (s2 - s1) / (steps - 1); local l_step = (l2 - l1) / (steps - 1)
    local gradient = {}
    for i = 0, steps - 1 do h = h1 + (h_step * i); s = s1 + (s_step * i); l = l1 + (l_step * i); gradient[i + 1] = hsl2hex(h, s, l) end
    return gradient
end
function graph.linearGradientText(text, hex1, hex2)
    local length = unicode.len(text); local gradient = graph.linearGradient(hex1, hex2, length); local response = ""
    for i = 1, length do local char = unicode.sub(text, i, i); response = string.format("%s%s%s", response, gradient[i], char) end
    return response
end

return graph