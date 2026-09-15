local BoneZone = {}
BoneZone.__index = BoneZone

local boneSprite = nil

local function loadSprites()
    if boneSprite then return end
    boneSprite = love.graphics.newImage(
        "assets/sprites/protruding-bone.png"
    )
end

function BoneZone.new(x, y)
    loadSprites()

    local self = setmetatable({}, BoneZone)

    self.x = x
    self.y = y
    self.size = 160
    self.half = self.size / 2

    self.timer = 0
    self.duration = 4.0

    self.warningDuration = 2.0
    self.isWarning = true

    self.hasHit = false

    return self
end

function BoneZone:update(dt, dummy)
    self.timer = self.timer + dt

    if self.isWarning then
        if self.timer >= self.warningDuration then
            self.isWarning = false
            self.timer = 0
        end
        return false
    end

    if dummy and not self.hasHit then
        local inZone = self:isInside(dummy)
        if inZone then
            local hit = dummy:hit(6, "bone_zone")
            if hit then
                self.hasHit = true
            end
        end
    end

    if self.timer >= self.duration then
        return true
    end

    return false
end

function BoneZone:isInside(target)
    return target.x > self.x - self.half and
           target.x < self.x + self.half and
           target.y > self.y - self.half and
           target.y < self.y + self.half
end

function BoneZone:draw()
    if self.isWarning then
        local pulse = math.sin(self.timer * 10) * 0.3 + 0.7
        love.graphics.setColor(1, 0, 0, pulse)

        local cx = self.x
        local cy = self.y

        love.graphics.rectangle("fill", cx - 5, cy - 25, 10, 35)
        love.graphics.circle("fill", cx, cy + 20, 6)

        love.graphics.setColor(1, 0, 0, 0.3)
        love.graphics.rectangle("line", self.x - self.half, self.y - self.half, self.size, self.size)

        love.graphics.setColor(1, 1, 1, 1)
        return
    end

    local step = 16
    local alpha = 0.8

    local t = self.timer / self.duration
    if t > 0.7 then
        alpha = 0.8 * (1 - (t - 0.7) / 0.3)
    end

    love.graphics.setColor(1, 1, 1, alpha)

    for x = -self.half, self.half - step, step do
        for y = -self.half, self.half - step, step do
            love.graphics.draw(boneSprite, self.x + x, self.y + y)
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function BoneZone:getState()
    if self.isWarning then
        return "warning"
    else
        return "bones"
    end
end

return BoneZone