function getImageScaleForNewDimensions( image, newWidth, newHeight )
    local currentWidth, currentHeight = image:getDimensions()
    return ( newWidth / currentWidth ), ( newHeight / currentHeight )
end

function collision(x1, y1, w1, h1,  x2, y2, w2, h2)
    return  x1 < x2+w2 and
            x2 < x1+w1 and
            y1 < y2+h2 and
            y2 < y1+h1
end

function collide(obj,localx,localy)
    if collision(obj.x,obj.y,obj.width,obj.height,localx,localy,32,32) then
        return true
    end
end

function limitInt(int, limit)
    if int>limit then
        return limit
    else
        return int
    end
end

function distanceBetween(x1, y1, x2, y2)
  return math.sqrt((y2-y1)^2 + (x2-x1)^2)
end