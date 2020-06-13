--[[
    GD50
    Match-3 Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    State in which we can actually play, moving around a grid cursor that
    can swap two tiles; when two tiles make a legal swap (a swap that results
    in a valid match), perform the swap and destroy all matched tiles, adding
    their values to the player's point score. The player can continue playing
    until they exceed the number of points needed to get to the next level
    or until the time runs out, at which point they are brought back to the
    main menu or the score entry menu if they made the top 10.
]]

PlayState = Class{__includes = BaseState}

function PlayState:init()
    
    -- start our transition alpha at full, so we fade in
    self.transitionAlpha = 255

    -- position in the grid which we're highlighting
    self.boardHighlightX = 0
    self.boardHighlightY = 0

    -- timer used to switch the highlight rect's color
    self.rectHighlighted = false

    -- flag to show whether we're able to process input (not swapping or clearing)
    self.canInput = true

    -- tile we're currently highlighting (preparing to swap)
    self.highlightedTile = nil

    

    self.score = 0
    self.timer = 60

    -- set our Timer class to turn cursor highlight on and off
    Timer.every(0.5, function()
        self.rectHighlighted = not self.rectHighlighted
    end)

    -- subtract 1 from timer every second
    Timer.every(1, function()
        self.timer = self.timer - 1

        -- play warning sound on timer if we get low
        if self.timer <= 5 then
            gSounds['clock']:play()
        end
    end)
end

function PlayState:enter(params)
    
    -- grab level # from the params we're passed
    self.level = params.level

    -- spawn a board and place it toward the right
    self.board = params.board or Board(VIRTUAL_WIDTH - 272, 16, self.level)

    -- grab score from params if it was passed
    self.score = params.score or 0

    -- score we have to reach to get to the next level
    self.scoreGoal = self.level * 1.25 * 1000

end

function PlayState:update(dt)
    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end

    -- go back to start if time runs out
    if self.timer <= 0 then
        
        -- clear timers from prior PlayStates
        Timer.clear()
        
        gSounds['game-over']:play()

        gStateMachine:change('game-over', {
            score = self.score
        })
    end

    -- go to next level if we surpass score goal
    if self.score >= self.scoreGoal then
        
        -- clear timers from prior PlayStates
        -- always clear before you change state, else next state's timers
        -- will also clear!
        Timer.clear()

        gSounds['next-level']:play()

        -- change to begin game state with new level (incremented)
        gStateMachine:change('begin-game', {
            level = self.level + 1,
            score = self.score
        })
    end

    if self.canInput then
        -- move cursor around based on bounds of grid, playing sounds
        if love.keyboard.wasPressed('up') then
            self.boardHighlightY = math.max(0, self.boardHighlightY - 1)
            gSounds['select']:play()
        elseif love.keyboard.wasPressed('down') then
            self.boardHighlightY = math.min(7, self.boardHighlightY + 1)
            gSounds['select']:play()
        elseif love.keyboard.wasPressed('left') then
            self.boardHighlightX = math.max(0, self.boardHighlightX - 1)
            gSounds['select']:play()
        elseif love.keyboard.wasPressed('right') then
            self.boardHighlightX = math.min(7, self.boardHighlightX + 1)
            gSounds['select']:play()
        end

        if self.highlightedTile then
            self:mouseSelect()
        else
            self:mouseHighlight()
        end



        -- if we've pressed enter, to select or deselect a tile...
        if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then
            
            -- if same tile as currently highlighted, deselect
            local x = self.boardHighlightX + 1
            local y = self.boardHighlightY + 1
            
            -- if nothing is highlighted, highlight current tile
            if not self.highlightedTile then
                self.highlightedTile = self.board.tiles[y][x]

            -- if we select the position already highlighted, remove highlight
            elseif self.highlightedTile == self.board.tiles[y][x] then
                self.highlightedTile = nil

            -- if the difference between X and Y combined of this highlighted tile
            -- vs the previous is not equal to 1, also remove highlight
            elseif math.abs(self.highlightedTile.gridX - x) + math.abs(self.highlightedTile.gridY - y) > 1 then
                gSounds['error']:play()
                self.highlightedTile = nil
            else
                
                -- swap grid positions of tiles
                local newTile = self.board.tiles[y][x]
                
               self.board:swap(self.highlightedTile.gridX, self.highlightedTile.gridY, newTile.gridX, newTile.gridY)
                
                -- swap tiles in the tiles table
                -- tween coordinates between the two so they swap
                Timer.tween(0.1, {
                    [self.highlightedTile] = {x = newTile.x, y = newTile.y},
                    [newTile] = {x = self.highlightedTile.x, y = self.highlightedTile.y}
                })
                
                -- once the swap is finished, we can tween falling blocks as needed
                :finish(function()
                    self:calculateMatches(self.highlightedTile.gridX, self.highlightedTile.gridY, newTile.gridX, newTile.gridY)
                    
                end)
            end
        end

        if love.keyboard.wasPressed("r") then
            self.board:resetR()
        end
    end

    Timer.update(dt)
    self.board:update(dt)
    if self.board:boardCheck() == false then

        self.board:reset()
    end
end

--[[
    Calculates whether any matches were found on the board and tweens the needed
    tiles to their new destinations if so. Also removes tiles from the board that
    have matched and replaces them with new randomized tiles, deferring most of this
    to the Board class.
]]
function PlayState:calculateMatches(x1, y1, x2, y2)
    self.highlightedTile = nil

    -- if we have any matches, remove them and tween the falling blocks that result
    local matches = self.board:calculateMatches()

    if matches == false and x1 > 0 then
            self.board:swap(x1, y1, x2, y2)
            local tile1 = self.board.tiles[y1][x1]
            local tile2 = self.board.tiles[y2][x2]
            Timer.tween(0.1, {
                [tile1] = {x = tile2.x, y = tile2.y},
                [tile2] = {x = tile1.x, y = tile1.y}
            })
    end
    
    if matches then
        gSounds['match']:stop()
        gSounds['match']:play()

        -- add score for each match
        for k, match in pairs(matches) do
            for l, tile in pairs(match) do
                self.score = self.score + tile.variety * 10
            end
            self.score = self.score + #match * 50
            self.timer = self.timer + 1
        end

        -- remove any tiles that matched from the board, making empty spaces
        self.board:removeMatches()

        -- gets a table with tween values for tiles that should now fall
        local tilesToFall = self.board:getFallingTiles()

        -- tween new tiles that spawn from the ceiling over 0.25s to fill in
        -- the new upper gaps that exist
        Timer.tween(0.25, tilesToFall):finish(function()
            
            -- recursively call function in case new matches have been created
            -- as a result of falling blocks once new blocks have finished falling
            self:calculateMatches(0, 0, 0, 0)
        end)
    
    -- if no matches, we can continue playing
    else
        self.canInput = true
    end
  

end

 
function PlayState:mouseHighlight()
    local mouseX, mouseY = push:toGame(love.mouse.getPosition())

    -- converting to grid coords
    local mouseGridX = math.floor((mouseX - self.board.x )/32) + 1
    local mouseGridY = math.floor((mouseY - self.board.y)/32) + 1

      -- do this only if mouse is inside the board
     if mouseGridX > 0 and mouseGridY > 0 and mouseGridX < 9  and mouseGridY < 9  then
        self.boardHighlightX = mouseGridX - 1
        self.boardHighlightY = mouseGridY - 1

        -- if there is no highlighted tile on the screen, turn selection off

        -- set selection or unhighlight on the board
        if love.mouse.wasPressed(1) then
            if self.highlightedTile == nil then
                self.highlightedTile = self.board.tiles[mouseGridY][mouseGridX]
            end
        end
     end

end

function PlayState:mouseSelect()

    local highX = self.highlightedTile.gridX
    local highY = self.highlightedTile.gridY

    local mouseX, mouseY = push:toGame(love.mouse.getPosition())
    local mouseGridX, mouseGridY = math.floor((mouseX - self.board.x )/32) + 1, math.floor((mouseY - self.board.y)/32) + 1


    if love.mouse.wasPressed(1) and (highX > 0 and highY > 0 and highX < 9 and highY < 9)  then

        if math.abs(mouseGridX - highX) + math.abs(mouseGridY - highY) <= 1 then
            local highTile = self.board.tiles[highY][highX]
            local swapTile = self.board.tiles[mouseGridY][mouseGridX]

            self.board:swap(mouseGridX, mouseGridY, highX, highY)

            Timer.tween(0.1, {
                [highTile] = {x = swapTile.x, y = swapTile.y},
                [swapTile] = {x = highTile.x, y = highTile.y}
            })
            
            -- once the swap is finished, we can tween falling blocks as needed
            :finish(function()
                self:calculateMatches(mouseGridX, mouseGridY, highX, highY)
                
            end)


        else
            self.highlightedTile = nil
        end

    end

    -- draw

    local drawX = highX - 1
    local drawY = highY - 1
    
    love.graphics.setColor(64, 224, 208, 255)
    -- draw actual cursor rect
    love.graphics.setLineWidth(2)       -- draw the 4 highlights orthogonally

    if highX ~= 8 then
     love.graphics.rectangle('line', (drawX+1) * 32 + (VIRTUAL_WIDTH - 272),             --right box
        (drawY) * 32 + 16, 32, 32, 4)
    end
    
    if highX ~= 1 then
    love.graphics.rectangle('line', (drawX - 1) * 32 + (VIRTUAL_WIDTH - 272),           -- left box
    (drawY) * 32 + 16, 32, 32, 4)
    end

    if highY ~= 8 then
    love.graphics.rectangle('line', (drawX) * 32 + (VIRTUAL_WIDTH - 272),               -- bottom box
    (drawY + 1) * 32 + 16, 32, 32, 4)
    end

    if highY ~= 1 then
    love.graphics.rectangle('line', (drawX) * 32 + (VIRTUAL_WIDTH - 272),               -- top box
    (drawY - 1 ) * 32 + 16, 32, 32, 4)
    end

    -- reset color to avoid flash
    love.graphics.setColor(255, 255, 255, 255)
    
end

function PlayState:render()
    -- render board of tiles
    self.board:render()
    self.board:renderParticles()
    self.board:renderReset()

    -- render highlighted tile if it exists
    if self.highlightedTile then
        
        -- multiply so drawing white rect makes it brighter
        love.graphics.setBlendMode('add')

        love.graphics.setColor(255, 255, 255, 96)
        love.graphics.rectangle('fill', (self.highlightedTile.gridX - 1) * 32 + (VIRTUAL_WIDTH - 272),
            (self.highlightedTile.gridY - 1) * 32 + 16, 32, 32, 4)

        -- back to alpha
        love.graphics.setBlendMode('alpha')
    end

    if self.highlightedTile then
        self:mouseSelect()
        end


    -- render highlight rect color based on timer
    if self.rectHighlighted then
        love.graphics.setColor(217, 87, 99, 255)
    else
        love.graphics.setColor(172, 50, 50, 255)
    end

    
    -- draw actual cursor rect
    love.graphics.setLineWidth(4)
    love.graphics.rectangle('line', self.boardHighlightX * 32 + (VIRTUAL_WIDTH - 272),
        self.boardHighlightY * 32 + 16, 32, 32, 4)

    -- GUI text
    love.graphics.setColor(56, 56, 56, 234)
    love.graphics.rectangle('fill', 16, 16, 186, 116, 4)

    love.graphics.setColor(99, 155, 255, 255) 
    love.graphics.setFont(gFonts['medium'])
    love.graphics.printf('Level: ' .. tostring(self.level), 20, 24, 182, 'center')
    love.graphics.printf('Score: ' .. tostring(self.score), 20, 52, 182, 'center')
    love.graphics.printf('Goal : ' .. tostring(self.scoreGoal), 20, 80, 182, 'center')
    love.graphics.printf('Timer: ' .. tostring(self.timer), 20, 108, 182, 'center')

    
end