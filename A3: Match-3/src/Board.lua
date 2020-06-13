--[[
    GD50
    Match-3 Remake

    -- Board Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    The Board is our arrangement of Tiles with which we must try to find matching
    sets of three horizontally or vertically.
]]

Board = Class{}

COLOR_TABLE = {1,2,5,6,9,10,13,14,17,18,3,4,7,8,11,12,15,16}
shinyChance = 10
COLOR_INIT = 6


function Board:init(x, y, level)
    self.x = x
    self.y = y
    self.matches = {}
    self.level = level 

    self.checking = false

    self.resetting = false

    particle = love.graphics.newImage('graphics/particle.png')
self.pSystem = love.graphics.newParticleSystem(particle, 200)
self.pSystem:setParticleLifetime(0.1, 0.5)
self.pSystem:setColors(255, 255, 0, 255, 255, 255, 255, 255)


    self:initializeTiles(self.level)

    
    
-- particle system, orientation denotes horizontal or vertical while number denotes nth row or column
self.orientation = 'h'
self.number = 1

self.ctr = 0
end



function Board:initializeTiles(level)
    self.tiles = {}

    for tileY = 1, 8 do
        
        -- empty table that will serve as a new row
        table.insert(self.tiles, {})

        for tileX = 1, 8 do
            
            -- create a new tile at X,Y with a random color and variety
            local var_variety = math.random(math.min(math.floor((self.level+1)/3), 6) )
            local var_color = COLOR_TABLE[math.random(math.min(math.floor(COLOR_INIT + self.level/2), 18))]
            local t = Tile(tileX, tileY, var_color, var_variety)
            if math.random(shinyChance) == 1 then
            t.shiny = true
            end
            table.insert(self.tiles[tileY], t)
        end
    end

    while self:calculateMatches() do
        
        -- recursively initialize if matches were returned so we always have
        -- a matchless board on start
        self:initializeTiles(self.level)
    end
end

--[[
    Goes left to right, top to bottom in the board, calculating matches by counting consecutive
    tiles of the same color. Doesn't need to check the last tile in every row or column if the 
    last two haven't been a match.
]]
function Board:calculateMatches()
    local matches = {}

    -- how many of the same color blocks in a row we've found
    local matchNum = 1

    -- horizontal matches first
    for y = 1, 8 do
        local colorToMatch = self.tiles[y][1].color

        matchNum = 1
        
        -- every horizontal tile
        for x = 2, 8 do
            
            -- if this is the same color as the one we're trying to match...
            if self.tiles[y][x].color == colorToMatch then
                matchNum = matchNum + 1
            else
                
                -- set this as the new color we want to watch for
                colorToMatch = self.tiles[y][x].color

                -- if we have a match of 3 or more up to now, add it to our matches table
                if matchNum >= 3 then
                    local match = {}

                    -- go backwards from here by matchNum
                    for x2 = x - 1, x - matchNum, -1 do
                        
                        -- add each tile to the match that's in that match
                        if self.tiles[y][x2].shiny == true then
                            self:shiny_blast('h', y)
                            for x_tile = 1,8 do 
                                table.insert(match, self.tiles[y][x_tile])
                            end
                            break
                        else
                            table.insert(match, self.tiles[y][x2])
                        end
                    end

                    -- add this match to our total matches table
                    table.insert(matches, match)
                end

                matchNum = 1

                -- don't need to check last two if they won't be in a match
                if x >= 7 then
                    break
                end
            end
        end

        -- account for the last row ending with a match
        if matchNum >= 3 then
            local match = {}
            
            -- go backwards from end of last row by matchNum
            for x = 8, 8 - matchNum + 1, -1 do
                if self.tiles[y][x].shiny == true then
                    self:shiny_blast('h', y)
                    for x_tile = 1,8 do 
                        table.insert(match, self.tiles[y][x_tile])
                    end
                    break
                else
                    table.insert(match, self.tiles[y][x])
                end
            end

            table.insert(matches, match)
        end
    end

    -- vertical matches
    for x = 1, 8 do
        local colorToMatch = self.tiles[1][x].color

        matchNum = 1

        -- every vertical tile
        for y = 2, 8 do
            if self.tiles[y][x].color == colorToMatch then
                matchNum = matchNum + 1
            else
                colorToMatch = self.tiles[y][x].color

                if matchNum >= 3 then
                    local match = {}

                    for y2 = y - 1, y - matchNum, -1 do
                        if self.tiles[y2][x].shiny == true then
                            self:shiny_blast('v', x)
                            for y_tile = 1,8 do 
                                table.insert(match, self.tiles[y_tile][x])
                            end
                            
                            break
                        else
                            table.insert(match, self.tiles[y2][x])
                        end
                    end

                    table.insert(matches, match)
                end

                matchNum = 1

                -- don't need to check last two if they won't be in a match
                if y >= 7 then
                    break
                end
            end
        end

        -- account for the last column ending with a match
        if matchNum >= 3 then
            local match = {}
            
            -- go backwards from end of last row by matchNum
            for y = 8, 8 - matchNum + 1, -1 do
                if self.tiles[y][x].shiny == true then
                    self:shiny_blast('v', x)
                    for y_tile = 1,8 do 
                        table.insert(match, self.tiles[y_tile][x])
                    end
                   
                    break
                else
                    table.insert(match, self.tiles[y][x])
                end
            end

            table.insert(matches, match)
        end
    end

    -- store matches for later reference
    self.matches = matches

    -- return matches table if > 0, else just return false
    return #self.matches > 0 and self.matches or false
end

--[[
    Remove the matches from the Board by just setting the Tile slots within
    them to nil, then setting self.matches to nil.
]]
function Board:removeMatches()
    for k, match in pairs(self.matches) do
        for k, tile in pairs(match) do
            self.tiles[tile.gridY][tile.gridX] = nil
        end
    end



    self.matches = nil
end

--[[
    Shifts down all of the tiles that now have spaces below them, then returns a table that
    contains tweening information for these new tiles.
]]
function Board:getFallingTiles()
    -- tween table, with tiles as keys and their x and y as the to values
    local tweens = {}

    -- for each column, go up tile by tile till we hit a space
    for x = 1, 8 do
        local space = false
        local spaceY = 0

        local y = 8
        while y >= 1 do
            
            -- if our last tile was a space...
            local tile = self.tiles[y][x]
            
            if space then
                
                -- if the current tile is *not* a space, bring this down to the lowest space
                if tile then
                    
                    -- put the tile in the correct spot in the board and fix its grid positions
                    self.tiles[spaceY][x] = tile
                    tile.gridY = spaceY

                    -- set its prior position to nil
                    self.tiles[y][x] = nil

                    -- tween the Y position to 32 x its grid position
                    tweens[tile] = {
                        y = (tile.gridY - 1) * 32
                    }

                    -- set Y to spaceY so we start back from here again
                    space = false
                    y = spaceY

                    -- set this back to 0 so we know we don't have an active space
                    spaceY = 0
                end
            elseif tile == nil then
                space = true
                
                -- if we haven't assigned a space yet, set this to it
                if spaceY == 0 then
                    spaceY = y
                end
            end

            y = y - 1
        end
    end

    -- create replacement tiles at the top of the screen
    for x = 1, 8 do
        for y = 8, 1, -1 do
            local tile = self.tiles[y][x]

            -- if the tile is nil, we need to add a new one
            if not tile then

                -- new tile with random color and variety
                local var_variety = math.random(math.min(math.floor((self.level+1)/3), 6))
                local var_color = COLOR_TABLE[math.random(math.min(math.floor(COLOR_INIT + self.level/2), 18))]
                local tile = Tile(x, y, var_color, var_variety)
                tile.y = -32
                if math.random(shinyChance) == 1 then
                    tile.shiny = true
                end

                self.tiles[y][x] = tile

                -- create a new tween to return for this tile to fall down
                tweens[tile] = {
                    y = (tile.gridY - 1) * 32
                }
            end
        end
    end

    return tweens
end

function Board:render()
    for y = 1, #self.tiles do
        for x = 1, #self.tiles[1] do
            self.tiles[y][x]:render(self.x, self.y)
        end
    end
end

function Board:update(dt)
    self.pSystem:update(dt)
end

function Board:renderParticles()
    if self.orientation == 'h' then
        love.graphics.draw(self.pSystem,self.x + 128, self.y + self.number * 32 - 16) 
    elseif self.orientation == 'v' then
        love.graphics.draw(self.pSystem, self.x + self.number * 32 - 16, self.y + 128)
    end
end

function Board:renderReset()
    if self.resetting == true then
        love.graphics.setColor(255, 255, 255, 128)
        love.graphics.rectangle('fill', VIRTUAL_WIDTH - 272, 16, 256, 256)
        love.graphics.setColor(0,0,0,255)
        love.graphics.setFont(gFonts['large'])
        self.ctr = self.ctr + 1
        print(self.ctr)
        love.graphics.print("RESETTING", self.x + 64, self.y + 112)
        love.graphics.setColor(255, 255, 255, 255)
    end
end
function Board:shiny_blast(orientation, number)

    if self.checking == false then
    gSounds['line-clear']:play()
    self.orientation = orientation
    self.number = number
    if self.orientation == 'h' then
    self.pSystem:setEmissionArea('borderrectangle', 120, 10)
    self.pSystem:setLinearAcceleration(-100, -1, 100, 1)
    elseif self.orientation == 'v' then
    self.pSystem:setEmissionArea('borderrectangle', 10, 120)
    self.pSystem:setLinearAcceleration(-1, -100, 1, 100)
    end
    self.pSystem:emit(200)
    end
end

function Board:boardCheck()

    self.checking = true

    -- check for any possible horizontal swaps
        for i =  1,8 do 
            for j = 1, 7 do
                self:swap(i, j, i, j+1)
                if self:calculateMatches()  then
                    self:swap(i, j, i, j+1)
                    self.checking = false
                    return true
                else
                    self:swap(i, j, i, j+1)
                end
            end
        end
        -- check for vertical matches
        for j =  1,8 do 
            for i = 1, 7 do
                self:swap(i, j, i + 1, j)
                if self:calculateMatches() then
                    self:swap(i, j, i + 1, j)
                    self.checking = false
                    return true
                else
                self:swap(i, j, i + 1, j)
                end
            end
        end

    self.checking = false
    return false
end


function Board:swap(x1, y1, x2, y2)             -- we supply the gridX, gridY values of the tiles we want to swap

    local tile1 = self.tiles[y1][x1]
    local tile2 = self.tiles[y2][x2]

    local tempX = tile1.gridX
    local tempY = tile1.gridY

    -- swapping
    tile1.gridX = tile2.gridX
    tile1.gridY = tile2.gridY
    tile2.gridX = tempX
    tile2.gridY = tempY

    self.tiles[tile1.gridY][tile1.gridX] =
    tile1

    self.tiles[tile2.gridY][tile2.gridX] = tile2
end

function Board:resetAnimated()
  
        local x1, y1, x2, y2 = math.random(8), math.random(8), math.random(8), math.random(8)
        print("("..tostring(x1)..","..tostring(y1)..") ("..tostring(x2)..","..tostring(y2)..")")
        local tile1 = self.tiles[y1][x1]
        local tile2 = self.tiles[y2][x2]
        self:swap(x1, y1, x2, y2)
        Timer.tween(0.1,{
            [tile1] ={x = tile2.x, y = tile2.y},
            [tile2] = {x = tile1.x, y = tile1.y}
        })
        :finish(function()
            if self:boardCheck() == false then
                self:resetAnimated()
            end

        end

        ) 
     
end

function Board:reset()
   self.resetting = true

   while self:boardCheck() == false do
   self:init(self.x, self.y, self.level)
   end

   self.resetting = true

   Timer.after(1, 
   function()
    self.resetting = false
   end)
end


function Board:resetR()
    
    self.resetting = true
    
    self:init(self.x, self.y, self.level)

    self.resetting = true
 
    Timer.after(1, 
    function()
     self.resetting = false
    end)
 end
