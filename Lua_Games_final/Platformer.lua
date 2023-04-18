-- Import required modules
require("mathutils")
local button = require("Button")

--calculates the distance between
--two points (x1, y1) and (x2, y2) using the Pythagorean theorem.
local function distanceBetween(x1, y1, x2, y2)
	return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
end

function Platformer (screen_width, screen_height)
	return {
		-- load support island image
		platform_image = love.graphics.newImage('sprites/is3.png'),

		-- Screen parameters
		screen_width = screen_width,
		screen_height = screen_height,

		--game buttons
		game_buttons = {
			button("Exit", change_state, "MENU", 100, 40),
		},
		platform = {
			x = 0,
			y = screen_height
		},

		-- Player defaults
		player = {
			x = 30,
			y = (screen_height/2) - 32,
			img = love.graphics.newImage('sprites/5.png'),
			ground = screen_height / 2,
			y_velocity = 0,
			velocity = 5,
			speed = 200,
			jump_height = -300,
			gravity = 5,
			lives = 3,
			score = 0,
			jumpingTimer = 0,
			jumpingMax = 30,
			onGround = false,
			timeOnAir = 0,
			isJumping = false,
			won = false
		},
		-- Enemy defaults
		enemy = {
			x = 900,
			y = (screen_height/2),
			img = love.graphics.newImage('sprites/enemy.png'),
			ground = screen_height / 2,
			y_velocity = 0,
			velocity = 5,
			speed = 200,
			direction = 1,
			jump_height = -300,
			gravity = 5,
			score = 0,
			jumpingTimer = 0,
			jumpingMax = 30,
			onGround = false,
			timeOnAir = 0,
			isJumping = false
		},

		-- Objects defaults
		objs = {},

		-- Coins setup
		coins_mesh = love.graphics.newMesh({
			  {0, 0},     --middle
			  {-1, -1},   --top left
			  {1, -1},    --top right
			  {1, 1},     --bottom right
			  {-1, 1},    --bottom left
			  {-1, -1}    --top left
			},"fan"),

		-- Coins positions
		map_coins = {
			--x,   y,  alive
			{100, 280, true},
			{200, 250, true},
			{300, 280, true},
			{400, 280, true},
			{530, 190, true},
			{630, 190, true},
			{740, 290, true},
			{740, 190, true}, {740, 170, true},{740, 150, true},{740, 130, true}, -- these are stacked
			{900, 250, true},
			{1000, 280, true}, {1000, 260, true}, {1000, 240, true}, {1000, 220, true}, {1000, 200, true} -- stacked
		},

		-- Only the finish Flag, first+second position
		 map_checkpoints = {
		  --{x, y, Forground Colour, Background Colour}
			{1200, 340, {203, 100, 34},{203, 100, 17}},
			{3050,520, {153, 100, 34},{153, 100, 17}},
			{3700, 120, {213, 100, 34}, {213, 100, 17}},
			{4971,320, {290, 100, 34},{290, 100, 17}},
			{8500,320, {153, 100, 34},{153, 100, 17}}
		  },

		-- Support platform positions
		init = function(self)
			self.reset(self)
			-- support platforms
			table.insert(self.objs, {x=300,y=330,width=50,height=35})
			table.insert(self.objs, {x=500,y=300,width=60,height=35})
			table.insert(self.objs, {x=600,y=300,width=70,height=35})
			table.insert(self.objs, {x=800,y=300,width=70,height=35})
			table.insert(self.objs, {x=700,y=210,width=70,height=35})
			-- Ground position in the Window
			table.insert(self.objs, {x=0,y=self.screen_height/2+32,width=self.screen_width,height=self.screen_height/2})
			-- 2nd ground level
			table.insert(self.objs, {x=0,y=self.screen_height*0.8,width=self.screen_width,height=self.screen_height*0.2})

			-- Load the font for the instructions
			self.instructions_font = love.graphics.newFont(13)
		end,

		-- Reset everything
		reset = function(self)
			self.player.x = 30
			self.player.y = (screen_height/2) - 32
			self.player.ground = screen_height / 1.1
			self.player.y_velocity = 0
			self.player.velocity = 5
			self.player.speed = 200
			self.player.jump_height = -300
			self.player.gravity = 5
			self.player.lives = 3
			self.player.score = 0
			self.player.jumpingTimer = 0
			self.player.jumpingMax = 30
			self.player.onGround = false
			self.player.timeOnAir = 0
			self.player.isJumping = false
			self.player.won = false
			-- coins mapping
			for i = 1, #self.map_coins do
				self.map_coins[i][5] = true
			end

		end,

		-- Load obstacles
		drawObjs = function(self)
		  love.graphics.setColor(1, 1, 1)
		  for index, value in ipairs(self.objs) do
			if index >= 1 and index <= 5 then
			  love.graphics.draw(self.platform_image, value.x, value.y)
			else
			  love.graphics.rectangle('fill', value.x, value.y, value.width, value.height)
			end
		  end
		end,

		-- Reset Coins
		resetCoins = function(self)
			for i = 1, #self.map_coins do
				self.map_coins[i][3] = true
			end
		end,

		-- Check if player won
		gameover = function(self, won)
			self.player["velocity"] = 0
			self.player["won"] = won
			if won then
				local title = "Platformer"
				local message = "Bravooo! Restart?"
				local buttons = {"Yes!", "No"}
				local pressedbutton = love.window.showMessageBox(title, message, buttons)
				if pressedbutton >= 1 and pressedbutton <= 2 then
					self.reset(self)
					if pressedbutton == 2 then
						change_state("MENU")
					end
				end
			end
		end,

		-- draw checkpoint obstacle
		drawCheckpoints = function(self)
			for _, checkpoint in ipairs(self.map_checkpoints) do
				local x, y, image = checkpoint[1], checkpoint[2], checkpoint[3]
				if type(image) == "userdata" and image:typeOf("Drawable") then
				  love.graphics.draw(image, x, y)
				end
			end
		end,

		-- Updates
		update = function(self, dt)
			--check gameover
			if self.player["lives"] <= 0 then
				self.gameover(self, false)
			end

			-- Calculate the distance
			self.player["distance"] = math.floor(distanceBetween(self.player["x"], self.player["y"], 1200, 340)) - 20

			-- Dual Level Implementation:
			-- Check if the player reaches the end of the current ground
			if self.player.x >= self.screen_width - 64 and self.player.y < self.screen_height * 0.8 - 64 then
				-- Move the player to the bottom lane and set the ground level
				self.player.y = self.screen_height * 0.8 - 64
				self.player.ground = self.screen_height * 0.8 - 64
				self.player.x = 0
			elseif self.player.x >= self.screen_width - 64 and self.player.y >= self.screen_height * 0.8 - 64 then
				-- Move the player back to the upper lane
				self.player.y = (self.screen_height / 2) - 32
				self.player.ground = self.screen_height / 2
				self.player.x = 0
			end
			-- Check if the player reaches the left edge of the screen on the lower level
			if self.player.x <= 0 and self.player.y >= self.screen_height * 0.8 - 64 then
				-- Move the player to the upper lane and set the ground level
				self.player.y = (self.screen_height / 2) - 32
				self.player.ground = self.screen_height / 2
				self.player.x = self.screen_width - 64
			end

			-- Coins reseter
			if self.player["distance"] <= 15 then
				self.resetCoins(self) -- Reset coins
				self.player.x = 30 -- Move the player back to the start position
				self.player.y = (screen_height / 2) - 32
				self.player.ground = screen_height / 2
				self.player.y_velocity = 0
			end
			-- Walk left
			localx = self.player["x"]
			localy = self.player["y"]
			if love.keyboard.isDown("a") then
				localx = self.player["x"]-self.player["velocity"]
			end
			-- Walk right
			if love.keyboard.isDown("d") then
				localx = self.player["x"]+self.player["velocity"]
			end

			-- Jump Key
			if love.keyboard.isDown("space") and self.player["onGround"]==true then
				self.player["jumping"]=true
				self.player["jumpingTimer"]=0
				self.player["onGround"]=false
			end

			if self.player["jumping"]==false then
				localy = self.player["y"]+self.player["gravity"]+limitInt(self.player["timeOnAir"]/2,20)
				self.player["timeOnAir"]=self.player["timeOnAir"]+1
			else
				localy = self.player["y"]-self.player["velocity"]*2+self.player["jumpingTimer"]/2
				self.player["jumpingTimer"]=self.player["jumpingTimer"]+1
				if self.player["jumpingTimer"]>=self.player["jumpingMax"] then
					self.player["jumping"]=false
				end
			end

			    -- Check if the player reaches the end of the current ground
			if self.player.x >= self.screen_width - 64 then
				-- Move the player to the bottom lane and set the ground level
				self.player.y = self.screen_height * 0.8 - 64
				self.player.ground = self.screen_height * 0.8 - 64
				self.player.x = 0
			end

			--move enemy
			self.enemy["x"] = self.enemy["x"]+(self.enemy["velocity"]*self.enemy["direction"])

			if self.enemy["x"] > 1000 then
				self.enemy["direction"] = -1
			elseif self.enemy["x"] < 500 then
				self.enemy["direction"] = 1
			end

			--enemy collision
			if collision(self.enemy["x"], self.enemy["y"], 64, 64, self.player["x"], self.player["y"], 64, 64) then
				self.player["lives"] = self.player["lives"] - 1
				localx = 30

			end

			-- Objects/platforms collisions
			for index,value in ipairs(self.objs) do
				if collide(value,localx,self.player["y"]) then
					localx=self.player["x"]
				end
				if collide(value,self.player["x"],localy) then
					if self.player["jumping"]==false then
						localy=value.y-32
						self.player["timeOnAir"]=0
					else
						localy=self.player["y"]
					end
					if value.y==self.player["y"]+32 then
						self.player["onGround"]=true
					end
				end
			end

			-- Coins collision
			  for i=1, #self.map_coins do
				if distanceBetween(self.player["x"], self.player["y"], self.map_coins[i][1], self.map_coins[i][2]) < 30 then
					if self.map_coins[i][3] then
						self.player["score"] = self.player["score"] + 1
						self.map_coins[i][3] = false
					end
				end
			  end

			-- player pos carriers
			self.player["x"] = localx
			self.player["y"] = localy

			-- keep track of player distance from start or end of the track
			self.player["distance"] = math.floor(distanceBetween(self.player["x"], self.player["y"], 1200, 340)) - 20
			if self.player["distance"] <= 10 then
				self.gameover(self, true)
			end
		end,

		-- Add the Platformer table
		load = function(self)
			-- Load your image file
			self.bottom_half_image = love.graphics.newImage("intro.png") -- Replace "your_image_file.png" with your image file name
		end,

		-- Modify the drawBackground
		drawBackground = function(self)
			-- Set the background color for the top half of the window
			love.graphics.setBackgroundColor(0, 0, 0, 1)

			-- Set the color for the bottom half of the window
			local bottom_half_color = {r = 0.19, g = 0.19, b = 0.19} -- Change the color values (r, g, b) as desired
			love.graphics.setColor(bottom_half_color.r, bottom_half_color.g, bottom_half_color.b)

			-- Draw a rectangle to fill the bottom half of the window
			love.graphics.rectangle('fill', 0, self.screen_height / 2+32, self.screen_width, self.screen_height / 2+32)
		end,

		draw = function(self)
			-- To debug mode before implement:
			-- Set the color for the bottom half of the window
			--local bottom_half_color = {r = 0.5, g = 0.5, b = 0.5} -- Change the color values (r, g, b) as desired
			--love.graphics.setColor(bottom_half_color.r, bottom_half_color.g, bottom_half_color.b)
			-- Draw a rectangle to fill the bottom half of the window
			--love.graphics.rectangle('fill', 0, self.screen_height / 2, self.screen_width, self.screen_height / 2)

			-- Playing field colour
			love.graphics.setBackgroundColor( 0, 0, 0, 1)
			love.graphics.setColor(1, 1, 1)

			--draw platform
			love.graphics.rectangle('line', self.platform["x"], self.platform["y"], self.screen_width, self.screen_height)
			  for i=1, 4 do
				love.graphics.setColor(0.15, 0.15, 0.15) -- The checkpoint pole
				love.graphics.rectangle("fill", self.map_checkpoints[i][1], self.map_checkpoints[i][2], 5, 55)-- Sets the colour for the flag, red/green depending on if you have reached it
				love.graphics.setColor(58/255, 182/255, 76/255)
				love.graphics.rectangle("fill", self.map_checkpoints[i][1], self.map_checkpoints[i][2], 25, 20)
			  end

			-- Footer board
			love.graphics.print("Lives: " .. self.player["lives"], 400, 50)
			love.graphics.print("Score: " .. self.player["score"], 600, 50)
			love.graphics.print("Distance to Victory: " .. self.player["distance"], 800, 50)

			--draw coins
			love.graphics.setColor(1, 221/255, 0)	-- The actual coin
			for i = 1, #self.map_coins do
				if self.map_coins[i][3] then
					love.graphics.draw(self.coins_mesh, self.map_coins[i][1], self.map_coins[i][2], love.timer.getTime(), 8)
				end
			end

			--draw objtects
			self.drawObjs(self)
			--draw player
			love.graphics.setColor(1, 1, 1)
			if self.player["lives"] > 0 then
				love.graphics.draw(self.player["img"], self.player["x"], self.player["y"], 0, 1, 1, 0, 32)
			else
				love.graphics.setColor(1, 1, 1)
				love.graphics.print("Game Over!", 100, 100)
			end
			if self.player["won"] == true then
				love.graphics.setColor(1, 1, 1)
				love.graphics.print("Won!!", 100, 100)
			end

			--draw enemy
			love.graphics.draw(self.enemy["img"], self.enemy["x"], self.enemy["y"], 0, 1, 1, 0, 32)

			-- Call the drawBackground function to draw the background first
			self:drawBackground()
			--return button
			love.graphics.setColor(1, 1, 1)
			self.game_buttons[1]:draw(100, 600, 17, 10)

			-- draw island ostacle
			self:drawCheckpoints()

			-- Control Instructions text:
			-- Set the color for the instructions text to white
			love.graphics.setColor(1, 1, 1, 1)

			-- Set the font for the instructions
			love.graphics.setFont(self.instructions_font)
			-- Draw the instructions
			love.graphics.print(
				"                                                                                                       " ..
				"Control: D-key = Walk Right | A-key = Walk Left | Space-key = Jump",
				10, self.screen_height - 60
			)
		end,
		-- check exit button pressing
		checkPressed = function (self, x, y, button, istouch, presses)
			--exit button
			self.game_buttons[1]:checkPressed(x, y, 2)
		end,
	}
end

return Platformer
