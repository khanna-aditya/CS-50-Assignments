--[[
    GD50 2018
    Pong Remake

    -- Main Program --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Originally programmed by Atari in 1972. Features two
    paddles, controlled by players, with the goal of getting
    the ball past your opponent's edge. First to 10 points wins.

    This version is built to more closely resemble the NES than
    the original Pong machines or the Atari 2600 in terms of
    resolution, though in widescreen (16:9) so it looks nicer on 
    modern systems.
]]

-- push is a library that will allow us to draw our game at a virtual
-- resolution, instead of however large our window is; used to provide
-- a more retro aesthetic
--
-- https://github.com/Ulydev/push
push = require 'push'


-- the "Class" library we're using will allow us to represent anything in
-- our game as code, rather than keeping track of many disparate variables and
-- methods
--
-- https://github.com/vrld/hump/blob/master/class.lua
Class = require 'class'

-- our Paddle class, which stores position and dimensions for each Paddle
-- and the logic for rendering them
require 'Paddle'

-- our Ball class, which isn't much different than a Paddle structure-wise
-- but which will mechanically function very differently
require 'Ball'

-- size of our actual window
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

-- size we're trying to emulate with push
VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

-- paddle movement speed
PADDLE_SPEED = 200

--[[
    Called just once at the beginning of the game; used to set up
    game objects, variables, etc. and prepare the game world.
]]
function love.load()
    -- set love's default filter to "nearest-neighbor", which essentially
    -- means there will be no filtering of pixels (blurriness), which is
    -- important for a nice crisp, 2D look
    love.graphics.setDefaultFilter('nearest', 'nearest')

    -- set the title of our application window
    love.window.setTitle('Pong')

    -- seed the RNG so that calls to random are always random
    math.randomseed(os.time())

    -- initialize our nice-looking retro text fonts
    smallFont = love.graphics.newFont('font.ttf', 8)
    largeFont = love.graphics.newFont('font.ttf', 16)
    scoreFont = love.graphics.newFont('font.ttf', 32)
    love.graphics.setFont(smallFont)

    -- set up our sound effects; later, we can just index this table and
    -- call each entry's `play` method
    sounds = {
        ['paddle_hit'] = love.audio.newSource('sounds/paddle_hit.wav', 'static'),
        ['score'] = love.audio.newSource('sounds/score.wav', 'static'),
        ['wall_hit'] = love.audio.newSource('sounds/wall_hit.wav', 'static'),
        ['menu_select'] = love.audio.newSource('sounds/menu_select.wav','static'),
        ['menu_error'] = love.audio.newSource('sounds/menu_no.wav','static'),
        ['bgm'] = love.audio.newSource('sounds/pong_bgm.wav','stream')
    }
    
    -- initialize our virtual resolution, which will be rendered within our
    -- actual window no matter its dimensions
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = true,
        vsync = true
    })

    -- initialize our player paddles; make them global so that they can be
    -- detected by other functions and modules
    
    
    player1 = Paddle(10, 30, 5, 20)
    player2 = Paddle(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 30, 5, 20)
    

    -- place a ball in the middle of the screen
    ball = Ball(VIRTUAL_WIDTH / 2 - 2, VIRTUAL_HEIGHT / 2 - 2, 4, 4)
    -- initialize score variables
    player1Score = 0
    player2Score = 0

    -- the game modes can be any of the following:
    -- 1. Player vs Player: standard. Uses old code. 'pvp'
    -- 2. PLayer vs AI : uses new added code. Also asks for difficulty. 'pvc'
    -- 3. AI vs AI: uses new code with both players AI. 'cvc'
    gameMode = ''

    -- difficulty, side, controls
    difficulty = '' -- 'easy' or 'hard' or 'imp'
    side  = ''      -- 'left' or 'right'
    controls = ''     -- 'ws' for W-S or 'ud' for arrow keys

    -- either going to be 1 or 2; whomever is scored on gets to serve the
    -- following turn
    servingPlayer = 1

    -- player who won the game; not set to a proper value until we reach
    -- that state in the game
    winningPlayer = 0

    -- the state of our game; can be any of the following:
    -- 1. 'start' (the beginning of the game, before first serve)
    -- 2. 'serve' (waiting on a key press to serve the ball)
    -- 3. 'play' (the ball is in play, bouncing between paddles)
    -- 4. 'done' (the game is over, with a victor, ready for restart)
    -- 5. 'menu_mode' (before the game starts, choose mode)
    -- 6. 'menu_diff' (before the game starts, if the chosen mode is 'pvc', select difficulty)
    -- 7. 'menu_side' (before the game starts, if the chosen mode is 'pvc', select side)
    -- 8. 'menu_ctrl' (before the game starts, if the chosen mode is 'pvc', select controls)
    -- 9. 'pause' (pauses the game)
    gameState = 'menu_mode'

   

end

--[[
    Called whenever we change the dimensions of our window, as by dragging
    out its bottom corner, for example. In this case, we only need to worry
    about calling out to `push` to handle the resizing. Takes in a `w` and
    `h` variable representing width and height, respectively.
]]
function love.resize(w, h)
    push:resize(w, h)
end

--[[
    Called every frame, passing in `dt` since the last frame. `dt`
    is short for `deltaTime` and is measured in seconds. Multiplying
    this by any changes we wish to make in our game will allow our
    game to perform consistently across all hardware; otherwise, any
    changes we make will be applied as fast as possible and will vary
    across system hardware.
]]
function love.update(dt)
    if (gameState ~= 'menu_mode' and gameState ~= 'menu_diff' and gameState ~= 'menu_side' and gameState ~= 'menu_ctrl') == false then
        sounds['bgm']:setLooping(true)
        sounds['bgm']:play()
    end

    if (gameState ~= 'menu_mode' and gameState ~= 'menu_diff' and gameState ~= 'menu_side' and gameState ~= 'menu_ctrl') == true then
        sounds['bgm']:setLooping(true)
        love.audio.stop(sounds['bgm'])
    end

    if gameState == 'serve' then
        -- before switching to play, initialize ball's velocity based
        -- on player who last scored
        
        if gameMode == 'pvp' then                   ---pvp rules
            if servingPlayer == 1 then
                ball.dx = math.random(140, 200)
                ball.dy = math.random(-50, 50)
             elseif servingPlayer == 2 then  --changes
                ball.dx = -math.random(140, 200)
                ball.dy = math.random(-50, 50)
            end 
        end 

        if gameMode == 'cvc' then                   ---cvc rules
            if servingPlayer == 1 then
                ball.dx = math.random(140, 200)
                ball.dy = math.random(-50, 50)
                gameState = 'play'
             elseif servingPlayer == 2 then  --changes
                ball.dx = -math.random(140, 200)
                ball.dy = math.random(-50, 50)
                gameState = 'play'
            end 
        end 


        if servingPlayer == 1 and side == 'left' and gameMode == 'pvc' then
            ball.dx = math.random(140, 200)
            ball.dy = math.random(-50, 50)
         elseif servingPlayer == 2 and side == 'left' and gameMode == 'pvc' then  --changes
            ball.dx = -math.random(140, 200)
            ball.dy = math.random(-50, 50)
            gameState = 'play'
         elseif servingPlayer == 1 and side == 'right' and gameMode == 'pvc'  then
                ball.dx = math.random(140, 200)
                ball.dy = math.random(-50, 50)
                gameState = 'play'
             elseif servingPlayer == 2 and side == 'right' and gameMode == 'pvc' then  --changes
                ball.dx = -math.random(140, 200)
                ball.dy = math.random(-50, 50)
        end
     elseif gameState == 'play' then
        -- detect ball collision with paddles, reversing dx if true and
        -- slightly increasing it, then altering the dy based on the position
        -- at which it collided, then playing a sound effect
        if ball:collides(player1) then
            ball.dx = -ball.dx * 1.03
            ball.x = player1.x + 5

            -- keep velocity going in the same direction, but randomize it
            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end

            sounds['paddle_hit']:play()
        end
        if ball:collides(player2) then
            ball.dx = -ball.dx * 1.03
            ball.x = player2.x - 4

            -- keep velocity going in the same direction, but randomize it
            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end 

            sounds['paddle_hit']:play()
        end

        -- detect upper and lower screen boundary collision, playing a sound
        -- effect and reversing dy if true
        if ball.y <= 0 then
            ball.y = 0
            ball.dy = -ball.dy
            sounds['wall_hit']:play()
        end

        -- -4 to account for the ball's size
        if ball.y >= VIRTUAL_HEIGHT - 4 then
            ball.y = VIRTUAL_HEIGHT - 4
            ball.dy = -ball.dy
            sounds['wall_hit']:play()
        end

        -- if we reach the left edge of the screen, go back to serve
        -- and update the score and serving player
        if ball.x < 0 then
            servingPlayer = 1
            player2Score = player2Score + 1
            sounds['score']:play()

            -- if we've reached a score of 10, the game is over; set the
            -- state to done so we can show the victory message
            if player2Score == 10 then
                winningPlayer = 2
                gameState = 'done'
            else
                gameState = 'serve'
                -- places the ball in the middle of the screen, no velocity
                ball:reset()
            end
        end

        -- if we reach the right edge of the screen, go back to serve
        -- and update the score and serving player
        if ball.x > VIRTUAL_WIDTH then
            servingPlayer = 2
            player1Score = player1Score + 1
            sounds['score']:play()

            -- if we've reached a score of 10, the game is over; set the
            -- state to done so we can show the victory message
            if player1Score == 10 then
                winningPlayer = 1
                gameState = 'done'
            else
                gameState = 'serve'
                -- places the ball in the middle of the screen, no velocity
                ball:reset()
            end
        end
    end

    --
    -- paddles can move no matter what state we're in
    --
    -- player 1          ------------------------------------------- pvp                 
    if gameMode == 'pvp' then
     if love.keyboard.isDown('w') then
        player1.dy = -PADDLE_SPEED
     elseif love.keyboard.isDown('s') then
        player1.dy = PADDLE_SPEED
     else
        player1.dy = 0
     end
     

     -- player 2
     if love.keyboard.isDown('up') then
        player2.dy = -PADDLE_SPEED
     elseif love.keyboard.isDown('down') then
        player2.dy = PADDLE_SPEED
     else
        player2.dy = 0
     end
    end
---------------------------------------------------- pvc
    if gameMode == 'pvc' then   -- boing
        up_button = 'w'     -- because error
        down_button = 's'
     if controls == 'ws' then            -- set controls
        up_button = 'w'
        down_button = 's'
     elseif controls == 'ud' then
        up_button = 'up'
        down_button = 'down'
     end

     check_width = 0
     if difficulty == 'easy' then
        check_width = VIRTUAL_WIDTH/4
     elseif difficulty == 'hard' then
        check_width = VIRTUAL_WIDTH/2
     elseif difficulty == 'imp' then
        check_width = VIRTUAL_WIDTH
     end


     plr = player1          --because error  --side
     plr_n = player2
     if side == 'left' then
         plr = player1
        plr_n = player2
     elseif side == 'right' then
         plr = player2 
         plr_n = player1
     end
     if ((ball.x - plr_n.x)^2)^(0.5)  < check_width then 
        if (plr_n.y > (ball.y + ball.height/2))  then                    -- computer
            plr_n.dy = -PADDLE_SPEED
         elseif (plr_n.y + plr_n.height < (ball.y + ball.height/2))  then
            plr_n.dy = PADDLE_SPEED
         else
            plr_n.dy = 0
        end
     end

     if love.keyboard.isDown(up_button) then             -- player
        plr.dy = -PADDLE_SPEED
      elseif love.keyboard.isDown(down_button) then
        plr.dy = PADDLE_SPEED
       else
        plr.dy = 0
      end
   
    end

    if gameMode == 'cvc' then
        -- player 1                        -- we will make this AI - controlled --boing
     if ball.x < VIRTUAL_WIDTH/3 then 
       if (player1.y > (ball.y + ball.height/2))  then
          player1.dy = -PADDLE_SPEED
       elseif (player1.y + player1.height < (ball.y + ball.height/2))  then
          player1.dy = PADDLE_SPEED
       else
          player1.dy = 0
       end
     end
  
       -- player 2
     if ball.x > 2 * VIRTUAL_WIDTH/3 then
       if (player2.y > (ball.y + ball.height/2))  then
         player2.dy = -PADDLE_SPEED
         elseif (player2.y + player2.height < (ball.y + ball.height/2))  then
         player2.dy = PADDLE_SPEED
         else
        player2.dy = 0
        end
     end
    end

    -- update our ball based on its DX and DY only if we're in play state;
    -- scale the velocity by dt so movement is framerate-independent
    if gameState == 'play' then
        ball:update(dt)
    end

    player1:update(dt)
    player2:update(dt)
end

--[[
    A callback that processes key strokes as they happen, just the once.
    Does not account for keys that are held down, which is handled by a
    separate function (`love.keyboard.isDown`). Useful for when we want
    things to happen right away, just once, like when we want to quit.
]]
function love.keypressed(key)
    -- `key` will be whatever key this callback detected as pressed
    if key == 'escape' then
        if gameState ~= 'menu_mode' then
         gameState = 'menu_mode'
         ball:reset()
         player1Score = 0
         player2Score = 0
         player1:reset1()
         player2:reset2()
        else
            love.event.quit()
        end

    -- if we press enter during either the start or serve phase, it should
    -- transition to the next appropriate state
    elseif key == 'enter' or key == 'return' then
       
        
        if  (gameMode == 'cvc') or (gameMode == 'pvp') or (gameMode == 'pvc' and ((side == 'left' and servingPlayer == 1) or (side == 'right' and servingPlayer == 2))) then
            if gameState == 'start' then
              gameState = 'serve'
          elseif gameState == 'serve' then
             gameState = 'play'
         elseif gameState == 'done' then
            -- game is simply in a restart phase here, but will set the serving
            -- player to the opponent of whomever won for fairness!
            gameState = 'serve'
    
    
            ball:reset()

            -- reset scores to 0
            player1Score = 0
            player2Score = 0

            -- decide serving player as the opposite of who won
            if winningPlayer == 1 then
                servingPlayer = 2
            else
                servingPlayer = 1
            end

         end
         elseif  (gameMode == 'pvc') and ((side == 'left' and servingPlayer == 2) or (side == 'right' and servingPlayer == 1)) then
            if gameState == 'start' then
                gameState = 'serve'
            end
            
        end

    end
  
    
    -- the menu where one can choose to play standard PvP, against AI or watch
    if gameState == 'menu_mode' then
        if key == '1'  then
            gameMode = 'pvp'
            gameState = 'start'
            sounds['menu_select']:play()
        elseif key == '2' then
            gameMode = 'pvc'
            gameState = 'menu_diff'
            sounds['menu_select']:play()
        elseif key == '3' then
            gameMode = 'cvc'
            gameState = 'start'
            sounds['menu_select']:play()
        else 
            sounds['menu_error']:play()
        end
    
    
    -- choose difficulty of AI opponent
    elseif gameState == 'menu_diff' then 
                  -- the gamestate is mentioned twice to avoid mispresses
        if key == '1'  then
            difficulty = 'easy'
            gameState = 'menu_side'
            sounds['menu_select']:play()
        elseif key == '2' then
            difficulty = 'hard'
            gameState = 'menu_side'
            sounds['menu_select']:play()
        elseif key == '3' then
            difficulty = 'imp'
            gameState = 'menu_side'
            sounds['menu_select']:play()
        else 
            sounds['menu_error']:play()
        end
    
        -- to choose which side your player is on
    elseif gameState == 'menu_side' then
        
        if key == '1' then
            side = 'left'
            gameState = 'menu_ctrl'
            sounds['menu_select']:play()
        elseif key == '2' then
            side = 'right'
            gameState = 'menu_ctrl'
            sounds['menu_select']:play()
        else 
            sounds['menu_error']:play()
        end
        
    
            -- to choose controls
    elseif gameState == 'menu_ctrl' then
        
        if key == '1' then 
            controls = 'ws'
            gameState = 'start'
            sounds['menu_select']:play()
        elseif key == '2' then
            controls = 'ud'
            gameState = 'start'
            sounds['menu_select']:play()
        else 
            sounds['menu_error']:play()
        end        
        

    end
end

--[[
    Called each frame after update; is responsible simply for
    drawing all of our game objects and more to the screen.
]]
function love.draw()
    -- begin drawing with push, in our virtual resolution
    push:apply('start')

    love.graphics.clear(40/255, 45/255, 52/255, 255/255)
    
    -- render different things depending on which part of the game we're in
    if gameState == 'start' then
        -- UI messages
        love.graphics.setFont(smallFont)
        love.graphics.printf('Welcome to Pong!', 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press Enter to begin!', 0, 20, VIRTUAL_WIDTH, 'center')
     elseif gameState == 'serve' then
        -- UI messages
        if gameMode == 'pvp' then
         love.graphics.setFont(smallFont)
         love.graphics.printf('Player ' .. tostring(servingPlayer) .. "'s serve!", 
            0, 10, VIRTUAL_WIDTH, 'center')
         love.graphics.printf('Press Enter to serve!', 0, 20, VIRTUAL_WIDTH, 'center')
         elseif gameMode == 'pvc' then
            if (side == 'left' and servingPlayer == 1) or (side == 'right' and servingPlayer == 2) then
                love.graphics.setFont(smallFont)
             love.graphics.printf("Player's serve!", 0, 10, VIRTUAL_WIDTH, 'center')
             love.graphics.printf('Press Enter to serve!', 0, 20, VIRTUAL_WIDTH, 'center')
             elseif (side == 'left' and servingPlayer == 2) or (side == 'right' and servingPlayer == 1) then
             love.graphics.setFont(smallFont)
             love.graphics.printf("Computer's serve",  0, 10, VIRTUAL_WIDTH, 'center')
             love.graphics.printf('Press Enter to serve!', 0, 20, VIRTUAL_WIDTH, 'center')
           end
        end
     elseif gameState == 'play' then
        love.graphics.setFont(smallFont)
        if gameMode == 'pvc' then
         love.graphics.printf('diff: '..difficulty..' side: '..side..' controls: '..controls, 0, 10, VIRTUAL_WIDTH, 'center')
        end
        -- no UI messages to display in play
     elseif gameState == 'done' then
        -- UI messages
        

       if gameMode == 'pvp' then
    love.graphics.setFont(largeFont)
        love.graphics.printf('Player ' .. tostring(winningPlayer) .. ' wins!',
            0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf('Press Enter to restart!', 0, 50, VIRTUAL_WIDTH, 'center')

       elseif gameMode == 'cvc' then
        love.graphics.setFont(largeFont)
        love.graphics.printf('Computer wins!',
            0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf('Press Enter to restart!', 0, 50, VIRTUAL_WIDTH, 'center')
       
         elseif gameMode == 'pvc' then
         if (side == 'left' and winningPlayer == 1) or (side == 'right' and winningPlayer == 2) then
           love.graphics.setFont(largeFont)
         love.graphics.printf("Player wins", 0, 10, VIRTUAL_WIDTH, 'center')
         love.graphics.setFont(smallFont)
         love.graphics.printf('Press Enter to restart', 0, 30, VIRTUAL_WIDTH, 'center')
         elseif (side == 'left' and winningPlayer == 2) or (side == 'right' and winningPlayer == 1) then
         love.graphics.setFont(largeFont)
         love.graphics.printf("Computer wins",  0, 10, VIRTUAL_WIDTH, 'center')
         love.graphics.setFont(smallFont)
         love.graphics.printf('Press Enter to restart!', 0, 30, VIRTUAL_WIDTH, 'center')
         end
       end 
       
     elseif gameState == 'menu_mode' then
        love.graphics.setFont(largeFont)
        love.graphics.printf('Choose a mode. Press the corresponding number on your keyboard.',0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf('1. Player vs Player \n 2. Player vs Computer \n 3. Computer vs Computer', 0, 50, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press escape to quit.', 0, VIRTUAL_HEIGHT - 20, VIRTUAL_WIDTH, 'right')
        
        
     elseif gameState == 'menu_diff' then
        love.graphics.setFont(largeFont)
        love.graphics.printf('Choose a difficulty. Press the corresponding number on your keyboard.',0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf('1. Easy \n \n \n 2. Hard \n \n \n 3. Impossible' , 0, 50, VIRTUAL_WIDTH, 'center')

    elseif gameState == 'menu_side' then
        love.graphics.setFont(largeFont)
        love.graphics.printf('Choose a side. Press the corresponding number on your keyboard.',0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(largeFont)
        love.graphics.printf('\t 1. Left \t\t\t\t\t\t\t 2. Right', 0, 125, VIRTUAL_WIDTH, 'left')
    
    elseif gameState == 'menu_ctrl' then
        love.graphics.setFont(largeFont)
        love.graphics.printf('Choose your controls. Press the corresponding number on your keyboard.',0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf('1. W-S keys \n \n 2. Arrow keys', 0, 50, VIRTUAL_WIDTH, 'center')
 end

    -- show the score before ball is rendered so it can move over the text
    displayScore()
    if gameState ~= 'menu_mode' and gameState ~= 'menu_diff' and gameState ~= 'menu_side' and gameState ~= 'menu_ctrl' then
     player1:render()
     player2:render()
     ball:render()
    end

    -- display FPS for debugging; simply comment out to remove
    displayFPS()

    -- end our drawing to push
    push:apply('end')
end

--[[
    Simple function for rendering the scores.
]]


function displayScore()
    -- score display
    if gameState ~= 'menu_mode' and gameState ~= 'menu_diff' and gameState ~= 'menu_side' and gameState ~= 'menu_ctrl' then
     love.graphics.setFont(scoreFont)
     love.graphics.print(tostring(player1Score), VIRTUAL_WIDTH / 2 - 50,VIRTUAL_HEIGHT / 3)
     love.graphics.print(tostring(player2Score), VIRTUAL_WIDTH / 2 + 30,VIRTUAL_HEIGHT / 3)
    end
end

--[[
    Renders the current FPS.
]]
function displayFPS()
    -- simple FPS display across all states
    love.graphics.setFont(smallFont)
    love.graphics.setColor(0, 255, 0, 255)
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 10, 10)
end
