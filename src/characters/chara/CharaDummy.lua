local CharaDummy = {}
CharaDummy.__index = CharaDummy
local Network = require("src.Network")

function CharaDummy.new(x, y)
    local self = setmetatable({}, CharaDummy)

    self.x = x or 600
    self.y = y or 350
    self.hp = 92
    self.maxHp = 92

    self.sprite = love.graphics.newImage("assets/sprites/chara/1.png")
    self.hitTimer = 0
    self.invulnerabilities = {}

    return self
end

function CharaDummy:update(dt)
    if self.hitTimer > 0 then
        self.hitTimer = self.hitTimer - dt
    end

    for ability, timer in pairs(self.invulnerabilities) do
        self.invulnerabilities[ability] = timer - dt
        if self.invulnerabilities[ability] <= 0 then
            self.invulnerabilities[ability] = nil
        end
    end
end

function CharaDummy:hit(damage, ability)
    if ability and self:isInvulnerable(ability) then
        return false
    end

    self.hp = math.max(0, self.hp - damage)
    self.hitTimer = 0.3

    if ability then
        self:addInvulnerability(ability, 2.0)
    end

    return true
end

function CharaDummy:isInvulnerable(ability)
    return self.invulnerabilities[ability] ~= nil
end

function CharaDummy:addInvulnerability(ability, duration)
    self.invulnerabilities[ability] = duration
end

function CharaDummy:getBounds()
    local w = self.sprite:getWidth()
    local h = self.sprite:getHeight()
    return {
        x = self.x - w / 2,
        y = self.y - h / 2,
        width = w,
        height = h,
    }
end

function CharaDummy:draw()
    if self.hitTimer > 0 then
        love.graphics.setColor(1, 0.2, 0.2, 1)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end

    local sx = self.sprite:getWidth() / 2
    local sy = self.sprite:getHeight() / 2
    love.graphics.draw(self.sprite, self.x, self.y, 0, 1, 1, sx, sy)

    love.graphics.setColor(1, 1, 1, 1)
love.graphics.print("HP: " .. Network.remoteHP .. "/92", self.x - 40, self.y - 60)
end

function CharaDummy:getX() return self.x end
function CharaDummy:getY() return self.y end

return CharaDummy