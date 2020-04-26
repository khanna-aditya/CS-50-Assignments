--[[
    ScoreState Class
    Author: Colton Ogden
    cogden@cs50.harvard.edu

    A simple state used to display the player's score before they
    transition back into the play state. Transitioned to from the
    PlayState when they collide with a Pipe.
]]

ScoreState = Class{__includes = BaseState}

--[[
    When we enter the score state, we expect to receive the score
    from the play state so we know what to render to the State.
]]
function ScoreState:enter(params)
    self.score = params.score
    birds = {
        ['bronze'] = love.graphics.newImage('bronze_birb.png'),
        ['silver'] = love.graphics.newImage('silver_birb.png'),
        ['gold'] = love.graphics.newImage('gold_birb.png')
    }
end

function ScoreState:update(dt)
    -- go back to play if enter is pressed
    if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then
        gStateMachine:change('countdown')
    end
end

function ScoreState:render()
    -- simply render the score to the middle of the screen
    love.graphics.setFont(flappyFont)
    love.graphics.printf('Oof! You lost!', 0, 64, VIRTUAL_WIDTH, 'center')

    love.graphics.setFont(mediumFont)
    love.graphics.printf('Score: ' .. tostring(self.score), 0, 100, VIRTUAL_WIDTH, 'center')
    -- minimum score needed to get trophy
    local bronzeScore = 10
    local silverScore = 25
    local goldScore = 50
    if self.score < silverScore and self.score >= bronzeScore  then
        love.graphics.printf('You obtained the Bronze Bird!', 0, 120, VIRTUAL_WIDTH, 'center')
        love.graphics.draw(birds['bronze'], VIRTUAL_WIDTH/2 + 40, VIRTUAL_HEIGHT/2 - 50)
    elseif self.score < goldScore and self.score >= silverScore  then
        love.graphics.printf('You obtained the Silver Bird!', 0, 120, VIRTUAL_WIDTH, 'center')
        love.graphics.draw(birds['silver'], VIRTUAL_WIDTH/2 + 40, VIRTUAL_HEIGHT/2 - 50)
    elseif self.score >= goldScore then
        love.graphics.printf('You obtained the Golden Bird!', 0, 120, VIRTUAL_WIDTH, 'center')
        love.graphics.draw(birds['gold'], VIRTUAL_WIDTH/2 + 40, VIRTUAL_HEIGHT/2 - 50)

    end

    love.graphics.printf('Press Enter to Play Again!', 0, 160, VIRTUAL_WIDTH, 'center')
end