1. Hi, this video is for the Assignment 1 for Harvard's Game Development course.
2. I will begin by showing the original game made in the lecture and then move on to showing the features I have added.

3. The game starts with a Title Screen and background music. The user can press space or use the left mouse button to make the bird jump.
4. If the bird collides with a pipe, the game ends and the score gets displayed.

5. The assignment has four main objectives, which I will walk you through one by one. I have also fixed a glitch that was present in the original build. I also added a new feature that I guess the title gave away.

6. I randomised the gap between the pipes by adding this line of code that randomises the gap length, and by adding that as a parameter to the pipe constructor.  So, previously the gap that was 90 pixels now ranges from 70 to 95

7. The gap between two pipe pairs was randomised by adding a variable called extraTime. When a pair is created, the time delay for the next one is decided randomly, thus effectively changing the distance between them.

8. The player upon scoring a certain number of points is rewarded with a message and a trophy. I set the minimum threshold as 10 points for a Bronze trophy, 25 for a silver and 50 for a golden one.

9. The last objective was to implement a pause feature, which pauses music and all the action on the screen.
10. I did this by adding a state to the state machine called "Pause State". Upon pressing enter, the game goes from the play state to the pause state and vice versa. 
11. The variables are introduced from the previous state as parameters into the new state \, so that all of the information like the position of the bird and the pipes can be retained even after when the game is unpaused.

12. In the original build, the player can jump really high and pass over the pipes, which theoretically  means they can't lose. This was fixed by limiting the movement of the player vertically.

13. I added the feature of health to the game. This takes away the punishing charm of the original but gives the player more chances to make a mistake.
14. The player incurs damage as long as they are touching the pipes. Thus the extent of their mistimed jump is penalised accordingly.


15. That's it for assignment 1. The link to the code is in the description below. This time I have also uploaded the .exe file if you want to try the game out.
16. See you next time, bye!




----
Description

infinitely, over flow error jump
link to code
how i thought of changing pipe to soemtihng
coursewebsite