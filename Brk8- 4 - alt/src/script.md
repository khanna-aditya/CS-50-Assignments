Objective 1 - multiball powerup
-- powerup spawns through some logic. It spawns in the middle, falls at a constant speed. Collection via collision, remove from table. 
-- Spawn balls with slightly different values. This is done by making the ball into a table

Objective 2 - paddle size
-- The effect of the ball being hit is normalised, so is roughly same for all. When the player reaches 7000, the paddle size increases, and for every successive 7000, paddle size increases. When a life is lost, the paddle size decreases.

Objective 3 - Locked Brick
-- The sprite was taken and put. The update logic for brick hit is activated only when the brick is not locked. A new parameter called keys is introduced which keeps a count of the number of keys. Every hit on the locked brick uses up a key, and the bricks can't be broken if the player has zero keys. Powerups fall on hit. You get one key every level


1. Hey, this is a video for assignment 2 of Harvard's CS50 game development course. This time we will be looking at breakout, or as it is commonly known, brickbreaker.
2. The game made in the lecture goes something like this. Start game, select paddle, launch ball, hit bricks, hit some more bricks, hit even more, pause. sometimes, you will need to hit a lot. 
3. Sometimes you will drop. But that's okay. You got more hearts. That's mostly it.
4. The assignment has three main objectives and we will look at them, one by one.
5. Here we implement a general powerup item by making a new Powerup class. This class contains arguments for position, the type of powerup and if it is on the screen and not been collected yet.
6. Much like we did for the previous objects, we herein create a function to extract powerup icons from the sprite sheet provided.
7. We call the frames in main and render it in our class. The powerups are numbered 1 to 10, and we will only be using 4 and 10.
8. A powerup spawns randomly and the probablity of spawning increases each time a brick is hit. Once it spawns, it falls straight down, where it can be collected, and this collection is handled by standard collision detection.
9. There can be multiple powerups on the screen as they are recorded in a table. Once a powerup is collected, it is removed from the table after activation. Which brings us to ...
10. The ball, instead of being a variable, is now treated as a table. The activation of the powerup leads to 4 extra balls being spawned close to the original one but with slightly varying speeds.
11. It is only when all balls ae lost that the player loses a life. This was acheived by checking the size of the ball table.
12. Upon completion of the level, all extra balls disappear.
13. The next objective was to change the size of the paddle when certain conditions are met. 
14. The initial code already generated quads for the paddles and rendered them according to size. Though redundant, I changed the paddle consttuctor to take in size as an argument.
15. When the player loses a life, the paddle shrinks. On the other hand, upon scoring a multiple of 7000 points, the paddle size increases.
16. I made little changes in the interaction between the ball and the paddle, so that the size of the paddle doesn't determine the force exerted on the ball
17. As the locked brick sprite was already chopped up from the sheet. I just inserted it into the table of bricks as the 22nd entry. 
17.1 While constructing the leverl, The brick;s fate of being locked is controlled by a flag. This can be tuned, but in this release, the probability of the brick being locked is one-half.
18. A locked brick can only be broken if one has a key. We keep the count of number of keys the player has using a class variable and display them at the bottom. A key is basically a powerup and is twice as likely to spawn than the multiball powerup.
19. If the player has no keys, then the ball just bluntly reflects off of the locked brick.
20. If the player does have a non-zero number of keys, then the ball hits the locked brick and destroys it while using up one key. Th eplayer is rewarded with 200 points when a locked brick is destroyed.
21. One starts the game with 4 keys. A new one is provided after losing a life and at the beginning of every level. Keys obtained in a=one level are carried forward. Also, the key powerup only spawns when there are locked bricks left in the level.
22. That's it for assignment 2. Thanks for watching.