-- Import required modules
require("mathutils")
local button = require "Button"
local jigsaw = require "Jigsaw"
local platformer = require "Platformer"
local fasttiles = require "FastTiles"

-- Load function
function love.load()
	-- Window title
	love.window.setTitle("Game Night - LHU")

	-- Set favicon
	local iconImageData = love.image.newImageData("sprites/favicon3.png")
	love.window.setIcon(iconImageData)

    -- Initialize variables
    width = 1280
    height = 720
    love.window.setMode(width, height)
    states = {GAME1="GAME1", GAME2="GAME2", GAME3="GAME3", MENU="MENU", END="END"}
    state = states.MENU
    sprites = {"tiger.jpg", "panda.jpg", "elephant.jpg"}
    background_img = love.graphics.newImage("sprites/introBK.png")
    menu_slider_img = love.graphics.newImage("sprites/slide_arrow.png")
    img = nil
    level = 1
    --winSound = love.audio.newSource("sounds/tiger.wav", "static")
    --video = love.graphics.newVideo("videos/track.ogv")
    --backgroundMusic = love.audio.newSource("sounds/music.ogg", "stream")

    -- Initialize game buttons
    game_buttons = {
		button("JigSawPuzzle", play_jigsaw, nil, 200, 100),
		button("Adventure", play_adventure, nil, 200, 100),
		button("CognitiveFlex", play_fasttiles, nil, 200, 100),
		button("Game4", nil, nil, 200, 100),
		button("Game5", nil, nil, 200, 100)
	}
    menu_starting_index = 1

    -- Initialize Jigsaw game
    jigsaw = Jigsaw(width, height)
    jigsaw:init()

    -- Initialize Platformer game
    platformer = Platformer(width, height)
    platformer:init()

    -- Initialize FastTiles game
    fasttiles = FastTiles()
    fasttiles:init()

    -- Initialize random seed
    math.randomseed(os.time())

    -- Initialize puzzle-related variables
    levels = {160, 80, 40}
    size = levels[1]
    columns = 0
    rows = 0
end

-- Draw game buttons function
function draw_game_buttons(starting_index)
    x_offset = -420
    y_offset = -170

    for i = starting_index, starting_index + 2 do
        button_id = i % 6
        if button_id == 0 then
            button_id = button_id + 1
        end

        game_buttons[i]:draw(((width / 2) - 600) + (i * 250), (height / 2) - 40, 17, 10)
    end
end

-- Menu function
function menu()
    -- Draw background image
	local img_width, img_height = background_img:getDimensions()
	local scale_x = width / img_width
	local scale_y = height / img_height
	love.graphics.draw(background_img, 0, 0, 0, scale_x, scale_y)

	--draw logo
	lhu_logo = love.graphics.newImage("sprites/LHU.png")
	local scale = 0.15
	love.graphics.draw(lhu_logo, 20, 20, 0, scale, scale)

    -- Draw game buttons
    draw_game_buttons(menu_starting_index)

    -- Draw slider arrows
    love.graphics.draw(menu_slider_img, 1240, 320, math.rad(90), 0.025, 0.025)
    love.graphics.draw(menu_slider_img, 40, 420, math.rad(270), 0.025, 0.025)

    -- Print instructions
    love.graphics.setNewFont(24)
    love.graphics.setColor(255, 255, 255, 255)
    --love.graphics.printf("Click on a game to start!", 400, 600, width, "center")
end


-- Jigsaw game function
function play_jigsaw()
    state = states.GAME1
end

-- Adventure game function
function play_adventure()
    state = states.GAME2
    platformer:reset()
end

-- FastTiles game function
function play_fasttiles()
    fasttiles:init()
    fasttiles:resetBoard()
    state = states.GAME3
end

-- Change state function
function change_state(nstate)
    state = nstate
end

-- Update function
function love.update(dt)
    if state == states.GAME1 then
        jigsaw:update(dt)
    elseif state == states.GAME2 then
        platformer:update(dt)
    end
end

-- Draw function
function love.draw()
    if state == states.MENU then
        menu()
    elseif state == states.GAME1 then
        jigsaw:draw()
    elseif state == states.GAME2 then
        platformer:draw()
    elseif state == states.GAME3 then
        fasttiles:update()
        fasttiles:draw()
    elseif state == states.END then
        endGame()
    end
end

-- Mouse pressed function
function love.mousepressed(x, y, button, istouch, presses)
    if state == states.MENU then
        for i = menu_starting_index, menu_starting_index+2 do
            game_buttons[i]:checkPressed(x, y, 2)
        end
    elseif state == states.GAME1 then
        jigsaw:checkPressed(x, y, button, istouch, presses)
    elseif state == states.GAME2 then
        platformer:checkPressed(x, y, button, istouch, presses)
    elseif state == states.GAME3 then
        fasttiles:checkPressed(x, y, button, istouch, presses)
    end
end

-- Mouse released function
function love.mousereleased(x, y, button)
    if state == states.GAME1 then
        jigsaw:checkReleased(x, y, button)
    end
end

-- Key pressed function
function love.keypressed(key)
    if state == states.GAME1 then
        jigsaw:checkKeyPressed(key)
    end
end
