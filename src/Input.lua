local Input = {}

Input.isMobile = false
Input.touchId = nil
Input.joystick = {x = 0, y = 0, active = false, baseX = 0, baseY = 0}

Input.pendingTouch = nil
Input.tapThreshold = 15

Input.joystickZone = {
    x = 120,
    y = 550,
    radius = 100,
}

function Input.load()
    local os = love.system.getOS()
    Input.isMobile = (os == "Android" or os == "iOS")
    Input.joystickZone.x = 120
    Input.joystickZone.y = love.graphics.getHeight() - 120
end

function Input.touchpressed(id, x, y)
    if Input.touchId == nil and Input.pendingTouch == nil then
        Input.pendingTouch = {id = id, x = x, y = y, moved = false}
    end
end

function Input.touchmoved(id, x, y)
    if Input.pendingTouch and Input.pendingTouch.id == id then
        local dx = x - Input.pendingTouch.x
        local dy = y - Input.pendingTouch.y
        local dist = math.sqrt(dx * dx + dy * dy)

        if not Input.pendingTouch.moved and dist > Input.tapThreshold then
            Input.pendingTouch.moved = true
            Input.touchId = id
            Input.joystick.active = true
            Input.joystick.baseX = Input.pendingTouch.x
            Input.joystick.baseY = Input.pendingTouch.y
            Input.joystick.x = 0
            Input.joystick.y = 0
        end

        if Input.joystick.active and Input.touchId == id then
            local jdx = x - Input.joystick.baseX
            local jdy = y - Input.joystick.baseY
            local jdist = math.sqrt(jdx * jdx + jdy * jdy)
            local maxDist = 60

            if jdist > maxDist then
                jdx = jdx / jdist * maxDist
                jdy = jdy / jdist * maxDist
            end

            Input.joystick.x = jdx / maxDist
            Input.joystick.y = jdy / maxDist
        end
    end
end

function Input.touchreleased(id, x, y)
    if Input.touchId == id then
        Input.touchId = nil
        Input.joystick.active = false
        Input.joystick.x = 0
        Input.joystick.y = 0
    end

    if Input.pendingTouch and Input.pendingTouch.id == id then
        local wasTap = not Input.pendingTouch.moved
        Input.pendingTouch = nil
        return wasTap
    end

    return false
end

function Input.getMove()
    if Input.isMobile then
        return Input.joystick.x, Input.joystick.y
    else
        local dx, dy = 0, 0
        if love.keyboard.isDown("a") then dx = dx - 1 end
        if love.keyboard.isDown("d") then dx = dx + 1 end
        if love.keyboard.isDown("w") then dy = dy - 1 end
        if love.keyboard.isDown("s") then dy = dy + 1 end
        return dx, dy
    end
end

function Input.drawJoystick()
    love.graphics.setColor(1, 1, 1, 0.1)
    love.graphics.circle("line", Input.joystickZone.x, Input.joystickZone.y, Input.joystickZone.radius)
    love.graphics.setColor(1, 1, 1, 0.05)
    love.graphics.circle("fill", Input.joystickZone.x, Input.joystickZone.y, Input.joystickZone.radius)

    if Input.joystick.active then
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.circle("line", Input.joystick.baseX, Input.joystick.baseY, 60)
        love.graphics.setColor(1, 1, 1, 0.6)
        love.graphics.circle("fill",
            Input.joystick.baseX + Input.joystick.x * 60,
            Input.joystick.baseY + Input.joystick.y * 60,
            25)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return Input