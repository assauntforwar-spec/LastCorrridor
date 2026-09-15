local Hotbar = {}
Hotbar.__index = Hotbar

function Hotbar.new()
    local self = setmetatable({}, Hotbar)

    self.slots = {
        {key = "space", name = "Blaster", selected = false},
        {key = "e", name = "Zone", selected = false},
    }

    return self
end

-- Возвращает true если тап попал в хотбар
function Hotbar:checkTap(x, y)
    local slotSize = 60
    local padding = 10
    local totalWidth = #self.slots * slotSize + (#self.slots - 1) * padding
    local startX = (love.graphics.getWidth() - totalWidth) / 2
    local yPos = love.graphics.getHeight() - slotSize - 20

    for i, slot in ipairs(self.slots) do
        local sx = startX + (i - 1) * (slotSize + padding)
        if x >= sx and x <= sx + slotSize and y >= yPos and y <= yPos + slotSize then
            -- Тап по слоту
            if slot.selected then
                slot.selected = false  -- снимаем выбор
            else
                -- Снимаем выбор у остальных
                for _, s in ipairs(self.slots) do
                    s.selected = false
                end
                slot.selected = true  -- выбираем этот
            end
            return true
        end
    end
    return false
end

-- Какую способность выбрали?
function Hotbar:getSelected()
    for _, slot in ipairs(self.slots) do
        if slot.selected then
            return slot.key
        end
    end
    return nil
end

function Hotbar:clearSelection()
    for _, slot in ipairs(self.slots) do
        slot.selected = false
    end
end

function Hotbar:draw()
    local slotSize = 60
    local padding = 10
    local totalWidth = #self.slots * slotSize + (#self.slots - 1) * padding
    local startX = (love.graphics.getWidth() - totalWidth) / 2
    local yPos = love.graphics.getHeight() - slotSize - 20

    for i, slot in ipairs(self.slots) do
        local x = startX + (i - 1) * (slotSize + padding)

        -- Фон
        if slot.selected then
            love.graphics.setColor(1, 1, 0.3, 0.9)  -- подсвечен
        else
            love.graphics.setColor(0.2, 0.2, 0.25, 0.8)
        end
        love.graphics.rectangle("fill", x, yPos, slotSize, slotSize, 6, 6)

        -- Обводка
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.rectangle("line", x, yPos, slotSize, slotSize, 6, 6)

        -- Название
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(slot.name, x + 5, yPos + 20)

        -- Клавиша
        love.graphics.print("[" .. slot.key .. "]", x + 5, yPos + 40)
    end
end

return Hotbar