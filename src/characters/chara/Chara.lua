local Input = require("src.Input")
local Network = require("src.Network")

local Chara = {}
Chara.__index = Chara

function Chara.new(x, y)
    local self = setmetatable({}, Chara)

    self.x = x or 400
    self.y = y or 360
    self.speed = 200

    self.hp = 92
    self.maxHp = 92

    self.direction = "d"
    self.frameIndex = 1
    self.frameTimer = 0
    self.frameDuration = 0.15
    self.isMoving = false

    self.invulnerabilities = {}
    self.hitTimer = 0

    self.walkFrames = { d = {}, l = {}, r = {}, u = {} }
    self.idleFrame = nil

    self.attackFrames = {}
    self.attack = nil
    self.attackCooldown = 0

    self:loadSprites()

    return self
end

function Chara:loadSprites()
    local dirMap = {
        d = {0, 1, 2, 3},
        l = {4, 5, 6, 7},
        r = {8, 9, 10, 11},
        u = {12, 13, 14, 15},
    }

    for dir, indices in pairs(dirMap) do
        for i, idx in ipairs(indices) do
            self.walkFrames[dir][i] = love.graphics.newImage(
                "assets/sprites/chara/" .. idx .. ".png"
            )
        end
    end

    self.idleFrame = love.graphics.newImage(
        "assets/sprites/chara/1.png"
    )

    for i = 1, 6 do
        self.attackFrames[i] = love.graphics.newImage(
            "assets/sprites/chara/slice(attack)/slice" .. i .. ".png"
        )
    end
end

function Chara:update(dt, sans)
    if self.attackCooldown > 0 then
        self.attackCooldown = self.attackCooldown - dt
    end

    self:updateMovement(dt)
    self:updateTimers(dt)
    self:updateAttack(dt, sans)
end

function Chara:updateMovement(dt)
    if self.attack then
        self.isMoving = false
        return
    end

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

function Chara:updateTimers(dt)
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

function Chara:updateAttack(dt, sans)
    if not self.attack then return end

    self.attack.timer = self.attack.timer + dt

    local frameTime = 0.08
    local frame = math.floor(self.attack.timer / frameTime) + 1

    if frame > 6 then
        self.attack = nil
        return
    end

    self.attack.frame = frame

    if frame == 3 and not self.attack.hasHit then
        local targetX, targetY, targetAlive

        if sans then
            targetX = sans.x
            targetY = sans.y
            targetAlive = not sans:isDead()
        elseif Network.remoteReceived then
            targetX = Network.remoteX
            targetY = Network.remoteY
            targetAlive = true
        end

        if targetX and targetAlive then
            local ax = self.x + math.cos(self.attack.angle) * self.attack.distance
            local ay = self.y + math.sin(self.attack.angle) * self.attack.distance

            local dx = targetX - ax
            local dy = targetY - ay
            local dist = math.sqrt(dx * dx + dy * dy)

            if dist < 60 then
                self.attack.hasHit = true

                if sans and sans.takeDamage then
                    sans:takeDamage(5)
                end

                Network.send("hit|sans|5")
            end
        end
    end
end

function Chara:startAttack(angle)
    if self.attack then return end
    if self.attackCooldown > 0 then return end

    self.attack = {
        angle = angle,
        timer = 0,
        frame = 1,
        distance = 60,
        hasHit = false,
    }

    self.attackCooldown = 0.5

    print("=== SENDING CHARA ATTACK:", angle)
    Network.send("chara_attack|" .. angle)
end

function Chara:isInvulnerable(ability)
    return self.invulnerabilities[ability] ~= nil
end

function Chara:addInvulnerability(ability, duration)
    self.invulnerabilities[ability] = duration
end

function Chara:hit(damage, ability)
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

function Chara:getBounds()
    local w = self.idleFrame:getWidth()
    local h = self.idleFrame:getHeight()
    return {
        x = self.x - w / 2,
        y = self.y - h / 2,
        width = w,
        height = h,
    }
end

function Chara:draw()
    if self.hitTimer > 0 then
        love.graphics.setColor(1, 0.2, 0.2, 1)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end

    if self.attack then
        local frame = self.attack.frame
        local sprite = self.attackFrames[frame]

        if sprite then
            local ax = self.x + math.cos(self.attack.angle) * self.attack.distance
            local ay = self.y + math.sin(self.attack.angle) * self.attack.distance

            local sx = sprite:getWidth() / 2
            local sy = sprite:getHeight() / 2
            love.graphics.draw(sprite, ax, ay, self.attack.angle, 1, 1, sx, sy)
        end
    end

    local charaSprite
    if self.isMoving then
        charaSprite = self.walkFrames[self.direction][self.frameIndex]
    else
        charaSprite = self.idleFrame
    end

    if charaSprite then
        local sx = charaSprite:getWidth() / 2
        local sy = charaSprite:getHeight() / 2
        love.graphics.draw(charaSprite, self.x, self.y, 0, 1, 1, sx, sy)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function Chara:keypressed(key)
    if key == "space" then
        local mx, my = love.mouse.getPosition()
        local dx = mx - self.x
        local dy = my - self.y
        local angle = math.atan2(dy, dx)
        self:startAttack(angle)
    end
end

function Chara:attackTo(x, y)
    local dx = x - self.x
    local dy = y - self.y
    local angle = math.atan2(dy, dx)
    self:startAttack(angle)
end

function Chara:getX() return self.x end
function Chara:getY() return self.y end

return Chara