local Blaster = require("src.characters.sans.abilities.Blaster")
local BoneZone = require("src.characters.sans.abilities.BoneZone")
local Input = require("src.Input")
local Network = require("src.Network")

local Sans = {}
Sans.__index = Sans

function Sans.new()
    local self = setmetatable({}, Sans)
    self.dead = false
    self.x = 400
    self.y = 360
    self.speed = 200

    self.direction = "d"
    self.frameIndex = 1
    self.frameTimer = 0
    self.frameDuration = 0.15
    self.isMoving = false

    self.stamina = 150
    self.maxStamina = 150
    self.staminaRegenTimer = 0
    self.staminaMoveTimer = 0   -- НОВОЕ

    self.walkFrames = {}
    self.idleFrame = nil

    self.blasters = {}
    self.zones = {}
    self.zoneCooldown = 0
    self.blasterCooldown = 0

    self:loadSprites()

    return self
end

function Sans:loadSprites()
    self.walkFrames = { l = {}, r = {}, u = {}, d = {} }
    for _, dir in ipairs({"l", "r", "u", "d"}) do
        for i = 0, 3 do
            self.walkFrames[dir][i + 1] = love.graphics.newImage(
                "assets/sprites/sans/spr_sans_" .. dir .. "_" .. i .. ".png"
            )
        end
    end

    self.idleFrame = love.graphics.newImage(
        "assets/sprites/sans/spr_sans_dt_0.png"
    )
end

function Sans:update(dt, dummy)
    self:updateMovement(dt)
    self:updateStamina(dt)
    self:updateBlasters(dt, dummy)
    self:updateZones(dt, dummy)
    if self.dead then return end

    if Network.pendingSansDamage and Network.pendingSansDamage > 0 then
        self:takeDamage(Network.pendingSansDamage)
        Network.pendingSansDamage = 0
    end

    if self.blasterCooldown > 0 then
        self.blasterCooldown = self.blasterCooldown - dt
    end
    if self.zoneCooldown > 0 then
        self.zoneCooldown = self.zoneCooldown - dt
    end
end

function Sans:updateZones(dt, dummy)
    for i = #self.zones, 1, -1 do
        local z = self.zones[i]
        local remove = z:update(dt, dummy)
        if remove then
            table.remove(self.zones, i)
        end
    end
end

function Sans:spawnZone(x, y)
    if self.stamina < 15 then return end
    if self.zoneCooldown > 0 then return end

    self.stamina = self.stamina - 15
    self.zoneCooldown = 3

    table.insert(self.zones, BoneZone.new(x, y))

    -- Отправляем по сети
    Network.send("zone|" .. math.floor(x) .. "," .. math.floor(y))
end

function Sans:updateMovement(dt)
    self.isMoving = false
    local dx, dy = Input.getMove()

    if dx ~= 0 or dy ~= 0 then
        self.isMoving = true
        if math.abs(dx) > math.abs(dy) then
            self.direction = dx > 0 and "r" or "l"
        else
            self.direction = dy > 0 and "d" or "u"
        end
    end

    self.x = self.x + dx * self.speed * dt
    self.y = self.y + dy * self.speed * dt

    if self.x < 32 then self.x = 32 end
    if self.x > 868 then self.x = 868 end
    if self.y < 32 then self.y = 32 end
    if self.y > 668 then self.y = 668 end

    if self.isMoving then
        self.frameTimer = self.frameTimer + dt
        if self.frameTimer >= self.frameDuration then
            self.frameTimer = 0
            self.frameIndex = self.frameIndex + 1
            if self.frameIndex > 4 then self.frameIndex = 1 end
        end
    else
        self.frameIndex = 1
        self.frameTimer = 0
    end
end

function Sans:updateStamina(dt)
    local regenRate

    if self.isMoving then
        -- При ходьбе — плавное замедление
        self.staminaMoveTimer = self.staminaMoveTimer + dt
        self.staminaRegenTimer = 0

        -- От 3/сек > 0.42/сек за 2 секунды
        local t = math.min(1, self.staminaMoveTimer / 2)
        regenRate = 3 - (3 - 0.42) * t

    else
        -- При стоянии — плавный разгон
        self.staminaRegenTimer = self.staminaRegenTimer + dt
        self.staminaMoveTimer = 0

        -- От 0/сек > 3/сек за 2 секунды
        local t = math.min(1, self.staminaRegenTimer / 4)
        regenRate = 0 + 3 * t
    end

    if regenRate < 0.42 then
        regenRate = 0.42
    end

    self.stamina = math.min(self.maxStamina, self.stamina + regenRate * dt)
end

function Sans:updateBlasters(dt, dummy)
    for i = #self.blasters, 1, -1 do
        local b = self.blasters[i]
        local remove = b:update(dt)

        if dummy and b:checkHit(dummy) then
            if not b.hasHit then
                local hit = dummy:hit(15, "blaster")
                if hit then
                    b.hasHit = true
                end
            end
        end

        if remove then
            table.remove(self.blasters, i)
        end
    end
end

function Sans:spawnBlaster(targetX, targetY)
    if self.stamina < 30 then return end
    if self.blasterCooldown > 0 then return end

    self.stamina = self.stamina - 30
    self.blasterCooldown = 6

    table.insert(self.blasters, Blaster.new(
        self.x, self.y,
        targetX, targetY
    ))

    -- Отправляем по сети
    Network.send("blaster|" .. math.floor(targetX) .. "," .. math.floor(targetY))
end

function Sans:drawZones()
    for _, z in ipairs(self.zones) do
        z:draw()
    end
end

function Sans:draw()
    local sprite
    if self.isMoving then
        sprite = self.walkFrames[self.direction][self.frameIndex]
    else
        sprite = self.idleFrame
    end

    if sprite then
        local sx = sprite:getWidth() / 2
        local sy = sprite:getHeight() / 2
        love.graphics.draw(sprite, self.x, self.y, 0, 2, 2, sx, sy)
    end

    for _, b in ipairs(self.blasters) do
        b:draw()
    end

    local barWidth = 200
    local barHeight = 20
    local barX = 20
    local barY = 20

    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", barX - 2, barY - 2, barWidth + 4, barHeight + 4)

    local fillWidth = barWidth * (self.stamina / self.maxStamina)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", barX, barY, fillWidth, barHeight)

    love.graphics.setColor(0, 0, 0, 1)
    local text = math.floor(self.stamina) .. "/" .. self.maxStamina
    love.graphics.print(text, barX + 8, barY + 4)

    love.graphics.setColor(1, 1, 1, 1)
end

function Sans:keypressed(key)
    if key == "space" then
        local mx, my = love.mouse.getPosition()
        self:spawnBlaster(mx, my)
    elseif key == "e" then
        local mx, my = love.mouse.getPosition()
        self:spawnZone(mx, my)
    end
end

function Sans:takeDamage(amount)
    if self.dead then return end

    self.stamina = self.stamina - amount

    if self.stamina <= 0 then
        self.stamina = 0
        self.dead = true
        print("=== САНС УМЕР ===")
    else
        print("Санс получил урон! Стамина:", self.stamina)
    end
end

function Sans:isDead()
    return self.dead == true
end

function Sans:getX() return self.x end
function Sans:getY() return self.y end

return Sans