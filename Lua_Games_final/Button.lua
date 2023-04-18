local love = require "love"

function Button (text, func, func_param, width, height)
	return {
		width = width or 100,
		height = height or 100,
		func = func or function() print("No function attached to this button") end,
		func_param = func_param,
		text = text or "No Text",
		button_x = 0,
		button_y = 0,
		text_x = 0,
		text_y = 0,

		setFunc = function (self, newf, newp)
			self.func = newf
			self.func_param = newp
		end,


		checkPressed = function (self, mouse_x, mouse_y, cursor_radius)
			if (mouse_x + cursor_radius >= self.button_x) and (mouse_x - cursor_radius <= self.button_x + self.width) then
				if (mouse_y + cursor_radius >= self.button_y) and (mouse_y - cursor_radius <= self.button_y + self.height) then
					if self.func_param then
						self.func(self.func_param)
					else
						self.func()
					end
				end
			end
		end,

		draw = function(self, button_x, button_y, text_x, text_y)
			self.button_x = button_x or self.button_x
			self.button_y = button_y or self.button_y

			if text_x then
				self.text_x = text_x + self.button_x
			else
				self.text_x = self.button_x
			end

			if text_y then
				self.text_y = text_y + self.button_y
			else
				self.text_y = self.button_y
			end

			-- Set the color to white with 70% transparency
			love.graphics.setColor(130,36,36, 0.7)
			-- Draw a rounded rectangle with 10px corner radius
			love.graphics.roundrectangle("fill", self.button_x, self.button_y, self.width, self.height, 10, 10)
			-- Reset the color to white with no transparency
			love.graphics.setColor(0, 0, 0)
			love.graphics.setFont(love.graphics.newFont(20))
			love.graphics.printf(self.text, self.button_x, self.button_y + (self.height / 2) - 10, self.width, "center")
		end
	}
end

-- Function to convert a hexadecimal color value to decimal RGB values
function hex2rgb(hex)
    hex = hex:gsub("#","")
    return tonumber("0x"..hex:sub(1,2)) / 255, tonumber("0x"..hex:sub(3,4)) / 255, tonumber("0x"..hex:sub(5,6)) / 255
end

-- Make buttons round corners
function love.graphics.roundrectangle(mode, x, y, width, height, rx, ry)
    if rx > width * 0.5 then rx = width * 0.5 end
    if ry > height * 0.5 then ry = height * 0.5 end
    love.graphics.rectangle(mode, x + rx, y, width - 2 * rx, height)
    love.graphics.rectangle(mode, x, y + ry, rx, height - 2 * ry)
    love.graphics.rectangle(mode, x + width - rx, y + ry, rx, height - 2 * ry)
    love.graphics.arc(mode, x + rx, y + ry, rx, math.pi, 3 * math.pi / 2)
    love.graphics.arc(mode, x + width - rx, y + ry, rx, 3 * math.pi / 2, 2 * math.pi)
    love.graphics.arc(mode, x + width - rx, y + height - ry, rx, 0, math.pi / 2)
    love.graphics.arc(mode, x + rx, y + height - ry, rx, math.pi / 2, math.pi)
end


return Button
