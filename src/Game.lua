local Menu = require("src.Menu")
local Player = require("src.Player")
local Chara = require("src.characters.chara.Chara")
local CharaDummy = require("src.characters.chara.CharaDummy")
local SansDummy = require("src.characters.sans.SansDummy")
local Hotbar = require("src.Hotbar")
local Input = require("src.Input")
local Network = require("src.Network")
local Blaster = require("src.characters.sans.abilities.Blaster")

local Game = {}
local state = "menu"
local role = nil
local mode = nil
local dummy = nil
local music = nil
local hotbar = nil
local isMobile = false

function Game.load()
    Menu.load()
    hotbar = Hotbar.new()
    music = love.audio.newSource("assets/music/jokinaside.mp3", "stream")
    music:setLooping(true)
    music:setVolume(0.5)

    -- Проверка на ОС
    local os = love.system.getOS()
    isMobile = (os == "Android" or os == "iOS")

    Game.boneSprite = love.graphics.newImage("assets/sprites/protruding-bone.png")

    Game.sansFrames = { l = {}, r = {}, u = {}, d = {} }
    for _, dir in ipairs({"l", "r", "u", "d"}) do
        for i = 0, 3 do
            Game.sansFrames[dir][i + 1] = love.graphics.newImage(
                "assets/sprites/sans/spr_sans_" .. dir .. "_" .. i .. ".png"
            )
        end
    end
    Game.sansIdle = love.graphics.newImage("assets/sprites/sans/spr_sans_dt_0.png")

    Game.charaAttackFrames = {}
    for i = 1, 6 do
        Game.charaAttackFrames[i] = love.graphics.newImage(
            "assets/sprites/chara/slice(attack)/slice" .. i .. ".png"
        )
    end

    Game.charaFrames = { d = {}, l = {}, r = {}, u = {} }
    local dirMap = {
        d = {0, 1, 2, 3},
        l = {4, 5, 6, 7},
        r = {8, 9, 10, 11},
        u = {12, 13, 14, 15},
    }
    for dir, indices in pairs(dirMap) do
        for i, idx in ipairs(indices) do
            Game.charaFrames[dir][i] = love.graphics.newImage(
                "assets/sprites/chara/" .. idx .. ".png"
            )
        end
    end
    Game.charaIdle = love.graphics.newImage("assets/sprites/chara/1.png")

    Game.SANS_SCALE = 2
    Game.CHARA_SCALE = 1
end

function Game.draw()
    if state == "menu" then
        Menu.draw()
    elseif state == "playing" then
        love.graphics.setColor(0.2, 0.2, 0.25)
        love.graphics.rectangle("fill", 0, 0, 900, 700)
        love.graphics.setColor(1, 1, 1)

        -- Удалённые зоны
        for _, z in ipairs(Network.remoteZones) do
            local half = 80
            local step = 16
            local alpha = 0.8

            if z.timer < 2 then
                local pulse = math.sin(z.timer * 10) * 0.3 + 0.7
                love.graphics.setColor(1, 0, 0, pulse)
                love.graphics.rectangle("fill", z.x - 5, z.y - 25, 10, 35)
                love.graphics.circle("fill", z.x, z.y + 20, 6)
                love.graphics.setColor(1, 0, 0, 0.3)
                love.graphics.rectangle("line", z.x - half, z.y - half, half * 2, half * 2)
            else
                if z.timer > 5 then
                    alpha = 0.8 * (1 - (z.timer - 5) / 1)
                end
                love.graphics.setColor(1, 1, 1, alpha)
                for x = -half, half - step, step do
                    for y = -half, half - step, step do
                        love.graphics.draw(Game.boneSprite, z.x + x, z.y + y)
                    end
                end
            end
            love.graphics.setColor(1, 1, 1, 1)
        end

        -- Удалённые бластеры
        for _, b in ipairs(Network.remoteBlasterObjects) do
            b:draw()
        end

        Player.drawZones()

        if dummy then
            dummy:draw()
        end

        -- Удалённая атака Чары
        if Network.remoteCharaAttack then
            local a = Network.remoteCharaAttack
            local sprite = Game.charaAttackFrames and Game.charaAttackFrames[a.frame]

            if sprite then
                local cx = Network.remoteX or 0
                local cy = Network.remoteY or 0

                local ax = cx + math.cos(a.angle) * 60
                local ay = cy + math.sin(a.angle) * 60

                local sx = sprite:getWidth() / 2
                local sy = sprite:getHeight() / 2
                love.graphics.draw(sprite, ax, ay, a.angle, 1, 1, sx, sy)
            end
        end

        Player.draw()

        -- Удалённый игрок
        if Network.remoteReceived then
            local remoteSprite
            local remoteScale

            if role == "sans" then
                if Network.remoteIsMoving then
                    local dir = Network.remoteDir or "d"
                    local frame = Network.remoteFrame or 1
                    remoteSprite = Game.charaFrames[dir][frame] or Game.charaIdle
                else
                    remoteSprite = Game.charaIdle
                end
                remoteScale = Game.CHARA_SCALE
            else
                if Network.remoteIsMoving then
                    local dir = Network.remoteDir or "d"
                    local frame = Network.remoteFrame or 1
                    remoteSprite = Game.sansFrames[dir][frame] or Game.sansIdle
                else
                    remoteSprite = Game.sansIdle
                end
                remoteScale = Game.SANS_SCALE
            end

            if remoteSprite then
                local sx = remoteSprite:getWidth() / 2
                local sy = remoteSprite:getHeight() / 2
                love.graphics.draw(remoteSprite, Network.remoteX, Network.remoteY, 0, remoteScale, remoteScale, sx, sy)
            end
        end

        -- HP Чары (для Санса)
        if role == "sans" then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(
                "HP: " .. Network.remoteHP .. "/92",
                Network.remoteX - 20,
                Network.remoteY - 80
            )
        end

        -- HP Чары (свой)
        if role == "chara" then
            local character = Player.getCharacter()
            if character and character.hp then
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.print("HP: " .. character.hp .. "/92", character:getX() - 20, character:getY() - 80)
            end
        end

        if role == "sans" then
            hotbar:draw()
        end
    end
end

function Game.keypressed(key)
    if state == "menu" then
        local chosen = Menu.keypressed(key)
        if not chosen then return end

        if chosen == "single" then
            mode = "single"
            Menu.mode = "role"

        elseif chosen == "server" then
            mode = "server"
            role = "sans"
            Network.initServer(6789)
            Player.load("sans")
            state = "playing"
            dummy = nil
            if music and not music:isPlaying() then music:play() end

        elseif chosen == "client" then
            mode = "client"
            role = "chara"
            Network.initClient("127.0.0.1", 6789)
            Player.load("chara")
            state = "playing"
            dummy = nil
            if music and not music:isPlaying() then music:play() end

        elseif chosen == "chara" or chosen == "sans" then
            role = chosen
            state = "playing"
            Player.load(role)

            if role == "sans" then
                dummy = CharaDummy.new(600, 350)
            else
                dummy = SansDummy.new(600, 350)
            end

            if music and not music:isPlaying() then music:play() end
        end

    elseif state == "playing" then
        Player.keypressed(key)
    end
end

function Game.touchpressed(id, x, y)
    -- Меню (тап по кнопкам)
    if state == "menu" then
        local chosen = Menu.touchpressed(x, y)
        if not chosen then return end

        if chosen == "single" then
            mode = "single"
            Menu.mode = "role"

        elseif chosen == "server" then
            mode = "server"
            role = "sans"
            Network.initServer(6789)
            Player.load("sans")
            state = "playing"
            dummy = nil
            if music and not music:isPlaying() then music:play() end

        elseif chosen == "client" then
            mode = "client"
            role = "chara"
            Network.initClient("127.0.0.1", 6789)
            Player.load("chara")
            state = "playing"
            dummy = nil
            if music and not music:isPlaying() then music:play() end

        elseif chosen == "chara" or chosen == "sans" then
            role = chosen
            state = "playing"
            Player.load(role)

            if role == "sans" then
                dummy = CharaDummy.new(600, 350)
            else
                dummy = SansDummy.new(600, 350)
            end

            if music and not music:isPlaying() then music:play() end
        end

        return
    end

    -- Игра
    if state ~= "playing" then return end

    -- Хотбар только для Санса
    if role == "sans" then
        if hotbar:checkTap(x, y) then
            return
        end

        local jz = Input.joystickZone
        local dx = x - jz.x
        local dy = y - jz.y
        if math.sqrt(dx * dx + dy * dy) < jz.radius then
            return
        end

        local selected = hotbar:getSelected()
        if selected then
            local character = Player.getCharacter()
            if character then
                if selected == "space" then
                    character:spawnBlaster(x, y)
                elseif selected == "e" then
                    character:spawnZone(x, y)
                end
                hotbar:clearSelection()
            end
        end
    else
        -- Чара: тап по полю = атака
        local jz = Input.joystickZone
        local dx = x - jz.x
        local dy = y - jz.y
        if math.sqrt(dx * dx + dy * dy) < jz.radius then
            return
        end

        local character = Player.getCharacter()
        if character and character.attackTo then
            character:attackTo(x, y)
        end
    end
end

function Game.update(dt)
    if state == "playing" then
        Player.update(dt, dummy)
        if dummy then dummy:update(dt) end

        -- Создаём бластер, если пришёл по сети
        if Network.pendingBlaster and role == "chara" then
            local b = Network.pendingBlaster
            local sx = Network.remoteX or 0
            local sy = Network.remoteY or 0
            table.insert(Network.remoteBlasterObjects, Blaster.new(sx, sy, b.targetX, b.targetY))
            Network.pendingBlaster = nil
        end

        -- Обновляем удалённую атаку Чары
        if Network.remoteCharaAttack then
            local a = Network.remoteCharaAttack
            a.timer = a.timer + dt
            a.frame = math.floor(a.timer / 0.08) + 1
            if a.frame > 6 then
                Network.remoteCharaAttack = nil
            end
        end

        -- Обновляем удалённые бластеры
        for i = #Network.remoteBlasterObjects, 1, -1 do
            local b = Network.remoteBlasterObjects[i]
            local remove = b:update(dt)
            if remove then
                table.remove(Network.remoteBlasterObjects, i)
            end
        end

        -- Урон Чаре от удалённых зон и бластеров
        if role == "chara" then
            local character = Player.getCharacter()
            if character then
                for _, z in ipairs(Network.remoteZones) do
                    if z.timer > 2 and not z.hasHit then
                        local inZone = character.x > z.x - 80 and
                                       character.x < z.x + 80 and
                                       character.y > z.y - 80 and
                                       character.y < z.y + 80
                        if inZone then
                            if character:hit(6, "bone_zone") then
                                z.hasHit = true
                            end
                        end
                    end
                end

                for _, b in ipairs(Network.remoteBlasterObjects) do
                    if b:checkHit(character) then
                        if not b.hasHit then
                            if character:hit(15, "blaster") then
                                b.hasHit = true
                            end
                        end
                    end
                end
            end
        end
    end
end

return Game