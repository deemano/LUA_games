-- Import required modules
require("drawutils")
local button = require "Button"
local love = require "love"

-- Define Grid
GRID_TOP = 45
GRID_LEFT = -174
GRID_CELL_SIZE = 32
GRID_GAP = 3

-- Construct function
function FastTiles ()
	return {
		tileSets = {
		"blue", "white", "red",
		"bad_duck", "good_duck", "hit_duck",
		"bad_cat", "good_cat", "hit_cat",
		"dog_normal", "dog_play", "dog_pet",
		"skele_back", "skele_snow", "skele_taco"
		},

		--game buttons
		game_buttons = {
			button("Exit", change_state, "MENU", 100, 40),
		},

		--index for tileSets table index (blue, bad_duck, bad_cat, dog_normal, skele_back)
		random_initials = {1, 4, 7, 10, 13},
		devmode = 0,
		score = 0,
		level = 1,
		timeLimit = 5.0,
		timeLeft = 5.0,

		--graphics
		sprite_scale = 2,

		--screen.setFont("Squarewave")
		--Setup the Grid
		timeSet = love.timer.getTime( ),
		grid = {},
		grid_length = 0,
		endTimerStarted = 0,
		targetsHit = 0,
		numTargets = 99,

		-- Add a new property for the instructions font
		instructions_font = love.graphics.newFont(13),

		-- control states
		init = function(self)
			self.score = 0
			self.level = 1
			for y = 0, 4 do
				for x = 1, 9 do
					self.grid[x+(y*9)] = {
						sprite =  "pipo" .. x+(y*9),
						sprite_name = "",
						screenX = 400 + GRID_LEFT + (GRID_CELL_SIZE/2) + x * (GRID_CELL_SIZE + GRID_GAP) * self.sprite_scale,
						screenY = 400 + GRID_TOP + (GRID_CELL_SIZE/2) - y * (GRID_CELL_SIZE + GRID_GAP)  * self.sprite_scale,
						sprite_starting_index = 0
					}
					self.grid_length = x+(y*9)
				end
			end
			self:resetBoard()
		end,

		return_main = function(self)
		end,

		-- Resets
		resetBoard = function(self)
			-- Set time limit
			self.timeLimit = 5
			self.timeLeft = 5
			self.timeSet = love.timer.getTime( )
			tileset_id = self.random_initials[love.math.random(5)]
			local tileSet = self.tileSets[tileset_id]
			-- Reset cells base values
			for y = 0, 4 do
				for x = 1, 9 do
					self.grid[x+(y*9)]["sprite"] =  love.graphics.newImage("sprites/fasttiles/" .. tileSet .. ".png")  --.sprite=tileSet[0]
					self.grid[x+(y*9)]["sprite_name"] = tileSet
					self.grid[x+(y*9)]["sprite_starting_index"] = tileset_id
				end
			end

			-- Select 'target' cells
			self.numTargets = 1 + math.min(self.level, 10)
			self.targetsHit = 0
			for i = 1, self.numTargets do
				idx = love.math.random(self.grid_length-1)

				--check if cell was already changed, if yes look for another
				while self.grid[idx]["sprite"] == tileSet[tileset_id+1] do
				  idx = love.math.random(self.grid_length)
				end

				--grid[idx].sprite = tileSet[tileset_id+1]
				self.grid[idx]["sprite_name"] = self.tileSets[tileset_id+1]
				self.grid[idx]["sprite"] = love.graphics.newImage('sprites/fasttiles/' .. self.tileSets[tileset_id+1] .. '.png')
			end
			self.endTimerStarted = 0
			won = false

		end,

		-- Called when a player wins
		win = function(self)
		  self.score = self.score + self.level
		  self.level = self.level + 1

		  self.endTimerStarted = love.timer.getTime( )
		  won = true
		end,

		-- Called when a player loses
		lose = function(self)
		  self.score = self.score - 1
		  self.level = self.level - 1
		  --audio.playSound("lose")
		  -- Don't let the player go lower than level 1
		  if self.level < 1 then
			self.level = 1
		  end
		  self.endTimerStarted = love.timer.getTime( )
		end,

		-- Handle what happens when a cell is hit
		processHitCell = function(self, i)
			-- Ignore cells that have already been hit
			if self.grid[i]["sprite_name"] == self.tileSets[self.grid[i]["sprite_starting_index"] + 2] then
				return
			end

			-- Check to see whether or not the cell is a target
			if self.grid[i]["sprite_name"] == self.tileSets[self.grid[i]["sprite_starting_index"] + 1] then
				self.targetsHit = self.targetsHit + 1

				-- If we've hit all the targets, then we win
				if self.targetsHit == self.numTargets then
					self.win(self)
				end

			elseif self.grid[i]["sprite_name"] == self.tileSets[self.grid[i]["sprite_starting_index"]] then
				-- If the player hits a cell that is NOT a target - then it's a loss.
				self.lose(self)
			end

		  --change
		  self.grid[i]["sprite_name"] = self.tileSets[self.grid[i]["sprite_starting_index"]+2]
		  self.grid[i]["sprite"] =  love.graphics.newImage("sprites/fasttiles/" .. self.grid[i]["sprite_name"]  .. ".png")  --.sprite=tileSet[0]
		end,

		-- Check whether or not a cell has been hit
		hitTest = function(self, i, x, y)
			--print(x .. " + " .. y)
		  return (self.grid[i]["screenX"] - GRID_CELL_SIZE/2*self.sprite_scale + GRID_CELL_SIZE) <= x and (self.grid[i]["screenX"] + GRID_CELL_SIZE/2*self.sprite_scale + GRID_CELL_SIZE) >= x and
				 (self.grid[i]["screenY"] + GRID_CELL_SIZE/2*self.sprite_scale + GRID_CELL_SIZE) >= y and (self.grid[i]["screenY"] - GRID_CELL_SIZE/2*self.sprite_scale + GRID_CELL_SIZE) <= y
		end,

		update = function(self)
			if self.endTimerStarted ~= 0 then
				--draw win/lose, wait and reset
				if love.timer.getTime() - self.endTimerStarted > 2 then
				  self.resetBoard(self)
				end
				return
			end

			  -- Update timer
			timeElapsed = (love.timer.getTime( ) - self.timeSet)
			self.timeLeft = math.max(0, self.timeLimit - timeElapsed)

			  -- Count a loss if time runs out
			if self.timeLeft <= 0 then
				self.lose(self)
			end

		end,

		draw = function(self)
			love.graphics.setColor(0.71, 0.68, 0.68)
			love.graphics.setBackgroundColor(0.75, 0.85, 1.0) -- Set background color to light blue (R, G, B)
			--return button
			self.game_buttons[1]:draw(100, 600, 17, 10)

			love.graphics.print("Pick Fast:", 300, 90)
			--screen.drawText("Pick Fast",-139,90,16, "#FFF")

			--screen.drawText("Level:",34,90,16, "#FFF")
			--screen.drawText(level,69,90,16, "#FFF")
			love.graphics.print("Level: " .. self.level, 600, 90)

			--screen.drawText("Score:",120,90,16, "#FFF")
			--screen.drawText(score,160,90,16, "#FFF")
			love.graphics.print("Score: " .. self.score, 800, 90)

			-- Timer
			--screen.fillRoundRect(-46, 90, 72, 10, 3, "white")
			timePercent = self.timeLeft / self.timeLimit
			love.graphics.setColor(0.0, 1.0, 0.0)
			roundrect("fill", 425, 100, 150*timePercent, 10, 15, 10, 10)
			love.graphics.setColor(1.0, 1.0, 1.0)

			--screen.fillRoundRect(-46, 90, timePercent * 70, 8, 3, "green")

			-- Draw grid cells
			for i = 1 , self.grid_length do
				love.graphics.draw(self.grid[i]["sprite"], self.grid[i]["screenX"], self.grid[i]["screenY"], 0, self.sprite_scale, self.sprite_scale)
				--print(self.grid[i]["sprite"])
				--screen.drawSprite(cell.sprite, cell["screenX"], cell["screenY"], GRID_CELL_SIZE, GRID_CELL_SIZE)
			end

			-- If the level has ended, then display the win/lose animation
			if self.endTimerStarted ~= 0 then
				elapsed = love.timer.getTime( ) - self.endTimerStarted
				offset = 20 * (elapsed / 700)

				if won then
				  --love.graphics.print("+1",0,+offset,46, "#0F0")
				else
				  love.graphics.setColor(1.0, 0.0, 0.0)
				  love.graphics.print("-1",930,90)
				  love.graphics.setColor(1.0, 1.0, 1.0)
				end
			end
			-- Control Instructions text:
			-- Set the color for the instructions text to white
			love.graphics.setColor(0, 0, 0, 1)
			-- Set the font for the instructions
			love.graphics.setFont(self.instructions_font)
			-- Draw the instructions
			love.graphics.print(
				"                                                                                            " ..
				"You are against time, so Think Fast, Click Fast! Pick the slightly different icons.",
				10, love.graphics.getHeight() - 60
			)
		end,

		-- Buttons pressing survey
		checkPressed = function (self, x, y, button, istouch, presses)
			--exit button
			self.game_buttons[1]:checkPressed(x, y, 2)

			--grid cells
			for i = 1 , self.grid_length do
				if self.hitTest(self, i, x, y) then
					self.processHitCell(self, i)
					return
				end
			end
		end,
	}
end

return FastTiles
