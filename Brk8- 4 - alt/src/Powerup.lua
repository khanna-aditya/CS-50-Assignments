--[[
    This creates a powerup and spawns it. It tracks whether the powerup is active, collected or falling.
  ]]
-- 16 x 16
Powerup = Class{}

function Powerup:init(x, y, n) -- x and y denote the starting position of the powerup, n denotes which powerup is spawned
    self.x = x
    self.y = y
    self.n = n
    self.falling = false            -- whether the powerup has been collected or is in the air
end

function Powerup:update(dt)
    if self.x > 0 and self.y > 0 then
        self.falling = true
    end

    if self.falling == true then
    self.y = self.y + 1
    end
end

function Powerup:render()  
    if self.falling == true then   
        love.graphics.draw(gTextures['main'], -- pick atlas
        gFrames['powerups'][self.n],      -- select powerup
        self.x + 8, self.y)    -- render at center of brick
                                              
    end

end

function Powerup:collide(target)
    if self.y + 16 < target.y 
    or self.y > target.y + target.height 
    or self.x + 16 < target.x or 
    self.x > target.x + target.width then
        return false
    else
        return true
    end
end

