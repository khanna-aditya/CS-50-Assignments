--[[
    PlayState Class
    Author: Colton Ogden
    cogden@cs50.harvard.edu

    The PlayState class is the bulk of the game, where the player actually controls the bird and
    avoids pipes. When the player collides with a pipe, we should go to the GameOver state, where
    we then go back to the main menu.
]]

PauseState = Class{__includes = BaseState}

PIPE_SPEED = 60
PIPE_WIDTH = 70
PIPE_HEIGHT = 288

BIRD_WIDTH = 38
BIRD_HEIGHT = 24

extraTime = 0

pauseSign = love.graphics.newImage('pause.png')

function PauseState:enter(params)
    -- 
    scrolling = false
    sounds['music'] = love.audio.pause()
    self.bird = params.bird
    self.pipePairs = params.pipePairs
    self.score = params.score
    self.timer = params.timer
    sounds['pause']:play()

end

function PauseState:init(params)

    -- initialize our last recorded Y value for a gap placement to base other gaps off of
    self.lastY = -PIPE_HEIGHT + math.random(80) + 20
    self.lastX = 0
end

function PauseState:update(dt)
    -- pause switch
 if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then
    gStateMachine:change('play',{
                            bird = self.bird,
                            pipePairs = self.pipePairs,
                            score = self.score,
                            timer = self.timer
                            })
 end
           
    
end

previousX = 0
function PauseState:render()
    for k, pair in pairs(self.pipePairs) do
        pair:render()
        previousX = pair.x
    end

    love.graphics.setFont(flappyFont)
    love.graphics.print('Score: ' .. tostring(self.score), 8, 8)
    love.graphics.print('HP: '..tostring(self.bird.health), 8, 40) 

    love.graphics.draw(pauseSign,VIRTUAL_WIDTH/2 - 0.4*pauseSign:getWidth()/2,VIRTUAL_HEIGHT/2 - 0.4*pauseSign:getHeight()/2,0,0.4,0.4)

    self.bird:render()
end

--[[
    Called when this state is transitioned to from another state.
]]

--[[
    Called when this state changes to another state.
]]
function PlayState:exit()
    -- stop scrolling for the death/score screen
    scrolling = true
end
