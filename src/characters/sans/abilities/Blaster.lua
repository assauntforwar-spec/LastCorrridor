local Blaster = {}
Blaster.__index = Blaster

local frames = nil
local beamSprite = nil

local function loadSprites()
    if frames then return end

    frames = {}
    for i = 0, 5 do
        frames[i + 1] = love.graphics.newImage(
            "assets/sprites/blaster/spr_gasterblaster_" .. i .. ".png"
        )
    end

    beamSprite = love.graphics.newImage(
        "assets/sprites/blaster/beam.png"
    )
end

function Blaster.new(ownerX, ownerY, targetX, targetY)
    loadSprites()

    local self = setmetatable({}, Blaster)

    self.startX = ownerX
    self.startY = ownerY
    self.x = ownerX
    self.y = ownerY

    self.targetX = targetX
    self.targetY = targetY

    -- Сначала определяем, куда выезжать (сверху/снизу)
    local offsetDistance = 60
    if targetY < ownerY then
        self.endX = ownerX
        self.endY = ownerY - offsetDistance
    else
        self.endX = ownerX
        self.endY = ownerY + offsetDistance
    end

    -- Угол считаем ОТ БЛАСТЕРА к курсору
    local dx = targetX - self.endX
    local dy = targetY - self.endY

    self.angle = math.atan2(dy, dx)
    self.spriteAngle = math.atan2(dy, dx) - math.pi / 2

    self.phase = "spawning"
    self.timer = 0

    self.spawnDuration = 0.4
    self.idleDuration = 1.0
    self.chargeDuration = 0.5
    self.fireDuration = 3.0
    self.reverseDuration = 0.4

    self.beamLength = 800
    self.beamPulseTimer = 0
    self.beamPulseSpeed = 8
    self.beamWidthBase = 1.7
    self.beamWidthAmplitude = 0.25

    self.scale = 2
    self.alpha = 0

    self.beamOffsetX = 30
    self.beamOffsetY = 0

    self.hasHit = false

    return self
end

function Blaster:update(dt)
    self.timer = self.timer + dt

    if self.phase == "spawning" then
        local t = self.timer / self.spawnDuration
        self.alpha = math.min(1, t)
        self.x = self.startX + (self.endX - self.startX) * t
        self.y = self.startY + (self.endY - self.startY) * t

        if self.timer >= self.spawnDuration then
            self.phase = "idle"
            self.timer = 0
            self.alpha = 1
            self.x = self.endX
            self.y = self.endY
        end

    elseif self.phase == "idle" then
        if self.timer >= self.idleDuration then
            self.phase = "charging"
            self.timer = 0
        end

    elseif self.phase == "charging" then
        if self.timer >= self.chargeDuration then
            self.phase = "firing"
            self.timer = 0
        end

    elseif self.phase == "firing" then
        self.beamPulseTimer = self.beamPulseTimer + dt
        if self.timer >= self.fireDuration then
            self.phase = "reverse"
            self.timer = 0
        end

    elseif self.phase == "reverse" then
        if self.timer >= self.reverseDuration then
            return true
        end
    end

    return false
end

function Blaster:draw()
    local frameIndex = 1

    if self.phase == "spawning" then
        frameIndex = 1
    elseif self.phase == "idle" then
        frameIndex = 1
    elseif self.phase == "charging" then
        local t = self.timer / self.chargeDuration
        frameIndex = math.floor(t * 3) + 1
        if frameIndex > 3 then frameIndex = 3 end
elseif self.phase == "firing" then
    local loopTime = 0.15
    local cycle = math.floor(self.timer / loopTime) % 2
    frameIndex = 5 + cycle
    elseif self.phase == "reverse" then
        local t = self.timer / self.reverseDuration
        frameIndex = 4 - math.floor(t * 4)
        if frameIndex < 1 then frameIndex = 1 end
    end

    -- Beam (ПОД бластером)
    if self.phase == "firing" then
        local pulse = math.sin(self.beamPulseTimer * self.beamPulseSpeed)
        local widthScale = self.beamWidthBase + pulse * self.beamWidthAmplitude

        local scaleX = self.beamLength / beamSprite:getWidth()

        local bx = self.x + self.beamOffsetX * math.cos(self.angle)
                     - self.beamOffsetY * math.sin(self.angle)
        local by = self.y + self.beamOffsetX * math.sin(self.angle)
                     + self.beamOffsetY * math.cos(self.angle)

        love.graphics.setColor(1, 1, 1, self.alpha)
        love.graphics.draw(
            beamSprite,
            bx, by,
            self.angle,
            scaleX, widthScale,
            0, beamSprite:getHeight() / 2
        )
        love.graphics.setColor(1, 1, 1, 1)
    end

    -- Бластер (ПОВЕРХ beam)
    local sprite = frames[frameIndex]
    if sprite then
        local sx = sprite:getWidth() / 2
        local sy = sprite:getHeight() / 2

        love.graphics.setColor(1, 1, 1, self.alpha)
        love.graphics.draw(
            sprite,
            self.x, self.y,
            self.spriteAngle,
            self.scale, self.scale,
            sx, sy
        )
        love.graphics.setColor(1, 1, 1, 1)
    end
end

function Blaster:isFiring()
    return self.phase == "firing"
end

function Blaster:getBeamBounds()
    local bx = self.x + self.beamOffsetX * math.cos(self.angle)
                 - self.beamOffsetY * math.sin(self.angle)
    local by = self.y + self.beamOffsetX * math.sin(self.angle)
                 + self.beamOffsetY * math.cos(self.angle)

    -- Учитываем пульсацию
    local pulse = math.sin(self.beamPulseTimer * self.beamPulseSpeed)
    local widthScale = self.beamWidthBase + pulse * self.beamWidthAmplitude

    return {
        x = bx,
        y = by,
        angle = self.angle,
        length = self.beamLength,
        width = beamSprite:getHeight() * widthScale,
    }
end

function Blaster:checkHit(target)
    if self.phase ~= "firing" then return false end

    local beam = self:getBeamBounds()
    local bounds = target:getBounds()

    -- Углы луча (начало и конец)
    local x1 = beam.x
    local y1 = beam.y
    local x2 = beam.x + math.cos(beam.angle) * beam.length
    local y2 = beam.y + math.sin(beam.angle) * beam.length

    -- Полуширина луча
    local halfWidth = beam.width / 2

    -- Нормаль к лучу (перпендикуляр)
    local nx = -math.sin(beam.angle)
    local ny = math.cos(beam.angle)

    -- Проверяем 4 угла хитбокса цели
    local corners = {
        {bounds.x, bounds.y},
        {bounds.x + bounds.width, bounds.y},
        {bounds.x, bounds.y + bounds.height},
        {bounds.x + bounds.width, bounds.y + bounds.height},
    }

    for _, c in ipairs(corners) do
        local cx, cy = c[1], c[2]

        -- Расстояние вдоль луча
        local dx = cx - x1
        local dy = cy - y1
        local proj = dx * math.cos(beam.angle) + dy * math.sin(beam.angle)

        if proj >= 0 and proj <= beam.length then
            -- Расстояние перпендикулярно лучу
            local perp = dx * nx + dy * ny
            if math.abs(perp) <= halfWidth then
                return true
            end
        end
    end

    return false
end

return Blaster