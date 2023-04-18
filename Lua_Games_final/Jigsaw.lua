-- Required modules
require("fileutils")
local love = require "love"
local button = require "Button"
local picker = require "picker"


-- Constants
local TILE_SIZE = 80
local GRID_SIZE_X = 8
local GRID_SIZE_Y = 6
local WINDOW_WIDTH = 1280
local WINDOW_HEIGHT = 720
local GRID_WIDTH = GRID_SIZE_X * TILE_SIZE
local GRID_HEIGHT = GRID_SIZE_Y * TILE_SIZE
local GRID_START_X = (WINDOW_WIDTH - GRID_WIDTH) / 2
local GRID_START_Y = (WINDOW_HEIGHT - GRID_HEIGHT) / 2
local SNAP_THRESHOLD = TILE_SIZE * 0.25
local PADDING_RIGHT = 20
local HEADER_Y = 0

-- Additional UI Constants
local HEADER_HEIGHT = 60
local FOOTER_HEIGHT = 60
local HEADER_COLOR = {0, 0.6, 0.8}
local TIMER_COLOR = {1, 1, 1}
local BUTTON_COLOR = {0.2, 0.6, 0.8}
local BUTTON_HOVER_COLOR = {0.4, 0.8, 1}
local BUTTON_TEXT_COLOR = {1, 1, 1}
local FONT_SIZE = 20
local gameState = "waiting"
local elapsedTime = 0

-- Variables
local image
local tiles = {}
local grid = {}
local mouseX, mouseY
local draggedTile = nil
local gameState = "waiting"
local timer = 0
local pause = false
local currentImageIndex = 1
local maxImageIndex = 7 -- Assuming 7 images in the backend folder

-- UI Variables - Buttons
local exitButton = {x = 10, y = 10, width = 80, height = 40, text = "Exit", bgColor = {0.7, 0.1, 0.1}}
local pauseButton = {x = 100, y = 10, width = 80, height = 40, text = "Pause", bgColor = {0.1, 0.7, 0.1}}
local restartButton = {x = WINDOW_WIDTH / 2 - 150, y = WINDOW_HEIGHT - 50, width = 120, height = 40, text = "Restart", bgColor = {0.1, 0.1, 0.7}}
local reloadButton = {x = WINDOW_WIDTH / 2 + 30, y = WINDOW_HEIGHT - 50, width = 120, height = 40, text = "Reload", bgColor = {0.7, 0.7, 0.1}}

-- Jigsaw object definition and functions
function Jigsaw (screen_width, screen_height)
	return {
		screen_width = screen_width,
		screen_height = screen_height,

		--In development - top menu button
		-- these are to implment later
		top_buttons = {
			button("Exit", change_state, "MENU", 100, 40),
			button("Reload other \npuzzle", nil, nil, 150, 40),
			button("Choose n \nof Pieces", nil, nil, 150, 40),
			button("Pause", nil, nil, 100, 40),
			button("Timer", nil, nil, 100, 40),
			button("Show/hide Ghost\n Image", nil, nil, 150, 40),
			button("Restart this", nil, nil, 150, 40)
				},

		-- Board dimensions
		board_size_x = 640,
		board_size_y = 480,

		-- Board dimensions
		pieces_sizes = {12, 48, 192},
		levels = {160, 80, 40, 20},

		-- Puzzle settings
		image = nil,
		image_path = nil,
		i_width = 0,
		i_height = 0,
		current_level = 1,
		columns = 0,
		rows = 0,
		puzzles = {},

		-- Game variables
		selected = 0,
		selected_group = 0,
		hovered = 0,
		hovered_group = 0,
		snapped_slot_ids = {},

		-- View variables
		view_x = 0,
		view_y = 0,
		scale = 1,

		-- Pause state
		paused = false,

		-- Group offset variables
		group_offset_x = 0,
		group_offset_y = 0,

		-- Scene variables
		scene_left = 0,
		scene_top = 0,
		scene_right = 0,
		scene_bottom = 0,

		-- Timer variables
		startup_timer = 60,
		startup_tick = -1,
		timer = 0,

		-- State variable
		state = "",

		-- Initialization function
		init = function(self)
			self.loadRandomImage(self)
			self.loadTiles(self)
		end,

		-- Check if mouse is over button
		isMouseOverButton = function(self, mouseX, mouseY, button)
			return mouseX >= button.x and mouseX <= button.x + button.width and mouseY >= button.y and mouseY <= button.y + button.height
		end,

		-- Draw button function
		drawButton = function(self, button)
			love.graphics.setColor(button.bgColor)
			love.graphics.rectangle("fill", button.x, button.y, button.width, button.height)
			love.graphics.setColor(1, 1, 1)
			love.graphics.printf(button.text, button.x, button.y + (button.height - FONT_SIZE) / 2, button.width, "center")
		end,

		-- Load random image function
		loadRandomImage = function(self)
			currentImageIndex = math.random(1, maxImageIndex)
			image = love.graphics.newImage("sprites/puzzles/image" .. currentImageIndex .. ".png")
			image:setFilter("nearest", "nearest")
		end,

		-- Clear tiles function
		clearTiles = function(self)
			for _, tile in ipairs(tiles) do
				if tile.gridX and tile.gridY then
					grid[tile.gridY][tile.gridX] = nil
				end
			end
			tiles = {}
		end,

		-- Check if position is inside the gri
		isInsideGrid = function(self, x, y)
			return x >= GRID_START_X and x <= GRID_START_X + GRID_WIDTH and y >= GRID_START_Y and y <= GRID_START_Y + GRID_HEIGHT
		end,

		-- Check if puzzle is complet
		isPuzzleComplete = function(self)
			for _, tile in ipairs(tiles) do
				if tile.gridX ~= tile.originalGridX or tile.gridY ~= tile.originalGridY then
					return false
				end
			end
			return true
		end,

		-- Snapping pieces to grid
		snapToGrid = function(self, tile)
			local gridX = math.floor((tile.x - GRID_START_X + TILE_SIZE / 2) / TILE_SIZE) + 1
			local gridY = math.floor((tile.y - GRID_START_Y + TILE_SIZE / 2) / TILE_SIZE) + 1

			if grid[gridY] and not grid[gridY][gridX] then
				local snapDistance = math.sqrt(math.pow(GRID_START_X + (gridX - 1) * TILE_SIZE - tile.x, 2) + math.pow(GRID_START_Y + (gridY - 1) * TILE_SIZE - tile.y, 2))
				if snapDistance <= SNAP_THRESHOLD then
					tile.x = GRID_START_X + (gridX - 1) * TILE_SIZE
					tile.y = GRID_START_Y + (gridY - 1) * TILE_SIZE
					grid[tile.gridY][tile.gridX] = nil
					grid[gridY][gridX] = tile
					tile.gridX = gridX
					tile.gridY = gridY
					if self.isPuzzleComplete(self) then
						gameState = "won"
					end
				end
			end
		end,

		-- Generate outside target positions
		generateRandomPositionOutsideGrid = function(self)
			local x, y
			while true do
				x, y = math.random(0, WINDOW_WIDTH - TILE_SIZE), math.random(0, WINDOW_HEIGHT - TILE_SIZE)
				if not isInsideGrid(x, y) then
					break
				end
			end

			x = math.max(0, math.min(WINDOW_WIDTH - 1.5 * TILE_SIZE, x))
			y = math.max(0, math.min(WINDOW_HEIGHT - TILE_SIZE, y))

			return x, y
		end,
		-- Move pieces outside grid area
		movePiecesToSides = function(self)
			for _, tile in ipairs(tiles) do
				local targetX
				if math.random() > 0.5 then
					targetX = math.random(1.5 * TILE_SIZE, GRID_START_X - 2.5 * TILE_SIZE)
				else
					targetX = math.random(GRID_START_X + GRID_WIDTH + 0.5 * TILE_SIZE, WINDOW_WIDTH - 2.5 * TILE_SIZE)
				end

				tile.x = targetX
				tile.y = math.random(GRID_START_Y, GRID_START_Y + GRID_HEIGHT - TILE_SIZE)
			end
		end,
		loadTiles = function(self)
			for y = 1, GRID_SIZE_Y do
				grid[y] = {}
				for x = 1, GRID_SIZE_X do
					grid[y][x] = nil
				end
			end

			local imageWidth, imageHeight = image:getDimensions()

			for y = 1, GRID_SIZE_Y do
				for x = 1, GRID_SIZE_X do
					local tile = {
						image = love.graphics.newQuad((x - 1) * TILE_SIZE, (y - 1) * TILE_SIZE, TILE_SIZE, TILE_SIZE, imageWidth, imageHeight),
						x = GRID_START_X + (x - 1) * TILE_SIZE,
						y = GRID_START_Y + (y - 1) * TILE_SIZE,
						gridX = x,
						gridY = y
					}
					table.insert(tiles, tile)
				end
			end
		end,

		-- Track mouse postion
		update = function(self, dt)
			mouseX, mouseY = love.mouse.getPosition()

			if gameState == "playing" and not pause then
				elapsedTime = elapsedTime + dt
			end

			if draggedTile then
				draggedTile.x = mouseX - TILE_SIZE / 2
				draggedTile.y = mouseY - TILE_SIZE / 2
			end

		end,

		draw = function(self)
		-- Draw the header
			love.graphics.setColor(HEADER_COLOR)
			love.graphics.rectangle("fill", 0, 0, WINDOW_WIDTH, HEADER_HEIGHT)

			-- Draw the title
			love.graphics.setColor(1, 1, 1)
			love.graphics.printf("JigSaw Puzzle (Press s-key to start)", 0, (HEADER_HEIGHT - FONT_SIZE) / 2, WINDOW_WIDTH, "center")

		-- Draw the timer text
			love.graphics.setColor(1, 1, 1)
			love.graphics.printf(string.format("%.2f", elapsedTime), WINDOW_WIDTH - FONT_SIZE * 5 - PADDING_RIGHT, HEADER_Y + HEADER_HEIGHT / 2 - FONT_SIZE / 2, FONT_SIZE * 5, "right")

			-- Draw the exit and pause/continue buttons
			pauseButton.text = pause and "Continue" or "Pause"
			self.drawButton(self, exitButton)
			self.drawButton(self, pauseButton)

			-- Draw the grid
			for y = 0, GRID_SIZE_Y - 1 do
				for x = 0, GRID_SIZE_X - 1 do
					love.graphics.rectangle("line", GRID_START_X + x * TILE_SIZE, GRID_START_Y + y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
				end
			end

			-- Draw the tiles
			for _, tile in ipairs(tiles) do
				love.graphics.draw(image, tile.image, tile.x, tile.y)
			end

			-- Draw the footer
			love.graphics.setColor(HEADER_COLOR)
			love.graphics.rectangle("fill", 0, WINDOW_HEIGHT - FOOTER_HEIGHT, WINDOW_WIDTH, FOOTER_HEIGHT)

			-- Draw restart and reload buttons
			self.drawButton(self, restartButton)
			self.drawButton(self, reloadButton)

			-- Draw the "Press s-key to start the Game" text with a smaller font
			local smallerFontSize = 16
			local smallerFont = love.graphics.newFont(smallerFontSize)
			love.graphics.setFont(smallerFont)
			love.graphics.setColor(1, 1, 1)
			love.graphics.printf("Press s-key to START", WINDOW_WIDTH - smallerFontSize * 9 - PADDING_RIGHT, WINDOW_HEIGHT - FOOTER_HEIGHT / 2 - smallerFontSize / 2, smallerFontSize * 9, "right")

			-- Reset the font size
			love.graphics.setFont(love.graphics.newFont(FONT_SIZE))

			-- Winning message
			if gameState == "won" then
				love.graphics.setColor(1, 1, 1)
				love.graphics.printf("You won!", 0, WINDOW_HEIGHT / 2 - FONT_SIZE / 2, WINDOW_WIDTH, "center")
			end

		end,

		-- Check mouse pressing
		checkKeyPressed = function(self, key)
			    if key == "s" and gameState == "waiting" then
					self.movePiecesToSides(self)
					gameState = "playing"
				end
		end,
		checkPressed = function (self, x, y, button, istouch, presses)
			if button == 1 then
				if self.isMouseOverButton(self, mouseX, mouseY, exitButton) then
					change_state("MENU")
					elapsedTime = 0
					timer = 0
					gameState = "waiting"
					self.clearTiles(self)
					self.loadRandomImage(self)
					self.loadTiles(self)
				elseif self.isMouseOverButton(self, mouseX, mouseY, pauseButton) then
					pause = not pause
				elseif self.isMouseOverButton(self, mouseX, mouseY, restartButton) then
					elapsedTime = 0
					timer = 0
					gameState = "waiting"
					self.clearTiles(self)
					image = love.graphics.newImage("sprites/puzzles/image" .. currentImageIndex .. ".png")
					image:setFilter("nearest", "nearest")
					self.loadTiles(self)
				elseif self.isMouseOverButton(self, mouseX, mouseY, reloadButton) then
					elapsedTime = 0
					timer = 0
					gameState = "waiting"
					self.clearTiles(self)
					self.loadRandomImage(self)
					self.loadTiles(self)
				else
					for _, tile in ipairs(tiles) do
						if x >= tile.x and x <= tile.x + TILE_SIZE and y >= tile.y and y <= tile.y + TILE_SIZE then
							draggedTile = tile
							grid[tile.gridY][tile.gridX] = nil
							break
						end
					end
				end
			end
		end,
		checkReleased = function (self, x, y, button)
			if button == 1 then
				if draggedTile and self.isInsideGrid(self, mouseX, mouseY) then
					self.snapToGrid(self, draggedTile)
				end
			draggedTile = nil
			end
		end,
	}
end

return Jigsaw
