--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

HIT_MAX = 40              -- how many times the ball can hit before the powerup spawns with 100% prob.
lockedBrick = false       -- checks if the the screen contains any locked bricks

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.ball = params.ball
    self.level = params.level
    self.keys = params.keys + 1

   self.recoverPoints = params.recoverPoints
   self.paddlePoints = params.paddlePoints

    -- give ball random starting velocity
    --self.ball.dx = math.random(-200, 200)
    self.ball[1].dy = math.random(-70, -80)

    self.powerup = { [1] = Powerup(-5, -5, 4)}
       --tracks how many times the ball has had a collision. 100 - hitcount gives the number

       hitcount =  math.floor(self.health/3 * HIT_MAX) 
end


function PlayState:update(dt)
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end

    -- update positions based on velocity
    self.paddle:update(dt)

    for k, b in pairs(self.ball) do
    b:update(dt)
    end
    for k, pp in pairs(self.powerup) do
    pp:update(dt)
    end
    
   for k, bol in pairs(self.ball) do
    if bol:collides(self.paddle) then
        -- raise ball above paddle in case it goes below it, then reverse dy
        bol.y = self.paddle.y - 8
        bol.dy = -bol.dy

        --
        -- tweak angle of bounce based on where it hits the paddle
        --

        -- if we hit the paddle on its left side while moving left...
        if bol.x < self.paddle.x + (self.paddle.width / 2) 
        and self.paddle.dx < 0 then
            bol.dx = -50 + -(8 *(self.paddle.x + self.paddle.width/2 - bol.x) 
                                           * 2 / self.paddle.size)
        
        -- else if we hit the paddle on its right side while moving right...
        elseif bol.x > self.paddle.x + (self.paddle.width / 2) 
        and self.paddle.dx > 0 then
            bol.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width/2 - bol.x) 
                                            * 2 / self.paddle.size)
        end

        gSounds['paddle-hit']:play()
    end
    end
    
    -- detect if the powerup has been picked                    -- Powerup 4 is ball multiplier
     for k, pp in pairs(self.powerup) do                         -- Powerup 10 is key
        if pp:collide(self.paddle) then             -- reset powerup and remove it from the table
            pp.y = self.paddle.y - 16
            table.remove(self.powerup,k)
            gSounds['paddle-hit']:play()
            gSounds['select']:play()
            gSounds['pause']:play()
            if pp.n == 4 then
            for i = 1, 4 do
            b = Ball()                                      -- new balls are added
            b.skin = math.random(7)
            b.x = self.ball[1].x
            b.y = self.ball[1].y
            b.dy = self.ball[1].dy + math.random(-15,15)
            b.dx = self.ball[1].dx + math.random(-10,10)
            table.insert(self.ball,b)
            end
        elseif pp.n == 10 then
                self.keys = self.keys + 1
             end

        end
        if pp.y > VIRTUAL_HEIGHT then
            table.remove(self.powerup,k)
        end
    
    end


    -- detect collision across all bricks with the ball
    for i, bol in pairs(self.ball) do
    for k, brick in pairs(self.bricks) do
        if brick.isLocked == true then
            lockedBrick = true
        end

        -- only check collision if we're in play                --powerup spawning 
        
        if brick.inPlay and bol:collides(brick) then

            -- if a locked brick is hit, and the player has a key, then destroy brick
            if brick.isLocked == true and self.keys >= 1 then
                brick.inPlay = false
                self.keys = self.keys - 1
                gSounds['brick-hit-1']:play()
                self.score = self.score + 200
            end
            
         -- do different actions for locked bricks
            hitcount = hitcount - 1
            if math.random(hitcount) == hitcount then                      -- this increases the prob of spawning after every hit
                table.insert(self.powerup, Powerup(brick.x, brick.y, 4))
                hitcount =   math.floor(self.health/3 * HIT_MAX)                         -- reset hitcount
            elseif lockedBrick == true and math.random(math.floor(hitcount/2)) == math.floor(hitcount/2)  then
                table.insert(self.powerup, Powerup(brick.x, brick.y, 10))
                hitcount =   math.floor(self.health/3 * HIT_MAX) 
            end
            if brick.isLocked == false then
                
                -- add to score
            self.score = self.score + (brick.tier * 200 + brick.color * 25)
             -- trigger the brick's hit function, which removes it from play
            brick:hit()
            else
                hitcount = hitcount - 1
                gSounds['no-select']:play()
            end
            

            -- if we have enough points, recover a point of health
            if self.score > self.recoverPoints then
                -- can't go above 3 health
                self.health = math.min(3, self.health + 1)

                -- multiply recover points by 2
                self.recoverPoints = math.min(100000, self.recoverPoints * 2)

                -- play recover sound effect
                gSounds['recover']:play()
            end

            if self.score > self.paddlePoints then
                if self.paddle.size < 4 then
                self.paddle.size = self.paddle.size + 1
                self.paddle.width = self.paddle.size * 32
                end
                self.paddlePoints = math.min(120000, self.paddlePoints + 7000)
                -- paddle expansion sound is the same as recover
                gSounds['recover']:play()
            end

            
            
            -- go to our victory screen if there are no more bricks left
            if self:checkVictory() then
                gSounds['victory']:play()

                gStateMachine:change('victory', {
                    level = self.level,
                    paddle = self.paddle,
                    health = self.health,
                    score = self.score,
                    highScores = self.highScores,
                    ball = self.ball,
                    recoverPoints = self.recoverPoints,
                    paddlePoints = self.paddlePoints,
                    keys = self.keys
                })
            end

            --
            -- collision code for bricks
            --
            -- we check to see if the opposite side of our velocity is outside of the brick;
            -- if it is, we trigger a collision on that side. else we're within the X + width of
            -- the brick and should check to see if the top or bottom edge is outside of the brick,
            -- colliding on the top or bottom accordingly 
            --

            -- left edge; only check if we're moving right, and offset the check by a couple of pixels
            -- so that flush corner hits register as Y flips, not X flips
            if bol.x + 2 < brick.x and bol.dx > 0 then
                
                -- flip x velocity and reset position outside of brick
                bol.dx = -bol.dx
                bol.x = brick.x - 8
            
            -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
            -- so that flush corner hits register as Y flips, not X flips
            elseif bol.x + 6 > brick.x + brick.width and bol.dx < 0 then
                
                -- flip x velocity and reset position outside of brick
                bol.dx = -bol.dx
                bol.x = brick.x + 32
            
            -- top edge if no X collisions, always check
            elseif bol.y < brick.y then
                
                -- flip y velocity and reset position outside of brick
                bol.dy = -bol.dy
                bol.y = brick.y - 8
            
            -- bottom edge if no X collisions or top collision, last possibility
            else
                
                -- flip y velocity and reset position outside of brick
                bol.dy = -bol.dy
                bol.y = brick.y + 16
            end

            -- slightly scale the y velocity to speed up the game, capping at +- 150
            if math.abs(bol.dy) < 150 then
                bol.dy = bol.dy * 1.02
            end

            -- only allow colliding with one brick, for corners
            break
        end
    end
end

    -- if ball goes below bounds, revert to serve state and decrease health
    for j, bol in pairs(self.ball) do
        if bol.y > VIRTUAL_HEIGHT then
            table.remove(self.ball,j)
        end
    end
    if #self.ball == 0 then
        self.health = self.health - 1
        if self.paddle.size > 1 then
        self.paddle.size = self.paddle.size - 1
        self.paddle.width = self.paddle.size * 32
        self.keys = math.max(0, self.keys - 3)
        end
        gSounds['hurt']:play()
    
        if self.health == 0 then
            gStateMachine:change('game-over', {
                score = self.score,
                highScores = self.highScores
            })
        else
            gStateMachine:change('serve', {
                paddle = self.paddle,
                bricks = self.bricks,
                health = self.health,
                score = self.score,
                highScores = self.highScores,
                level = self.level,
                recoverPoints = self.recoverPoints,
                paddlePoints = self.paddlePoints,
                keys = self.keys
            })
        end
    end

    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function PlayState:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    self.paddle:render()

    for k, b in pairs(self.ball) do
    b:render()
    end
    
    for k, pp in pairs(self.powerup) do 
    pp:render()
    end

    renderScore(self.score)
    renderHealth(self.health)
    renderKeys(self.keys)

    --love.graphics.print(tostring(hitcount),5,20)
    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end 
    end

    return true
end