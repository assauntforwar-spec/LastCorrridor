local Menu = {}

function Menu.load()
    Menu.charaSprite = love.graphics.newImage("assets/sprites/chara/v1.png")
    Menu.sansSprite = love.graphics.newImage("assets/sprites/sans/spr_sans_dt_0.png")
    Menu.mode = "menu"  -- "menu" èëè "role"

    -- Ïğîâåğêà íà ÎÑ
    local os = love.system.getOS()
    Menu.isMobile = (os == "Android" or os == "iOS")
end

function Menu.draw()
    love.graphics.setBackgroundColor(0.1, 0.1, 0.15)
    love.graphics.setColor(1, 1, 1)

    if Menu.mode == "menu" then
        love.graphics.print("Last Corridor", 380, 100)

        -- Êíîïêè
        love.graphics.setColor(0.3, 0.3, 0.4)
        love.graphics.rectangle("fill", 300, 230, 300, 50, 8, 8)
        love.graphics.rectangle("fill", 300, 300, 300, 50, 8, 8)
        love.graphics.rectangle("fill", 300, 370, 300, 50, 8, 8)

        love.graphics.setColor(1, 1, 1)
        love.graphics.print("1 - Single player", 360, 245)
        love.graphics.print("2 - Create server (Sans)", 340, 315)
        love.graphics.print("3 - Connect (Chara)", 350, 385)

    elseif Menu.mode == "role" then
        love.graphics.print("Choose character", 380, 100)

        -- ×àğà
        love.graphics.draw(Menu.charaSprite, 300, 250, 0, 0.15, 0.15)
        love.graphics.print("Chara - 1", 330, 330)

        -- Ñàíñ
        love.graphics.draw(Menu.sansSprite, 550, 250, 0, 2, 2)
        love.graphics.print("Sans - 2", 580, 330)
    end
end

-- Êëàâèøè (äëÿ ÏÊ)
function Menu.keypressed(key)
    if Menu.mode == "menu" then
        if key == "1" then return "single"
        elseif key == "2" then return "server"
        elseif key == "3" then return "client" end
    elseif Menu.mode == "role" then
        if key == "1" then return "chara"
        elseif key == "2" then return "sans" end
    end
    return nil
end

-- Òàïû (äëÿ òåëåôîíà)
function Menu.touchpressed(x, y)
    if Menu.mode == "menu" then
        -- Êíîïêà 1: Single player
        if x >= 300 and x <= 600 and y >= 230 and y <= 280 then
            return "single"
        -- Êíîïêà 2: Create server
        elseif x >= 300 and x <= 600 and y >= 300 and y <= 350 then
            return "server"
        -- Êíîïêà 3: Connect
        elseif x >= 300 and x <= 600 and y >= 370 and y <= 420 then
            return "client"
        end

    elseif Menu.mode == "role" then
        -- ×àğà (ëåâàÿ ïîëîâèíà)
        if x < love.graphics.getWidth() / 2 then
            return "chara"
        -- Ñàíñ (ïğàâàÿ ïîëîâèíà)
        else
            return "sans"
        end
    end
    return nil
end

return Menu