# SBGameStateProject

As we continue to shift into an age with more data availability, analytics have become a key part in helping mitigate risk, whether it’s risk in the way teams play, or potential acquisitions that entail a large financial commitment from respective clubs. 

We can assess the idea of how a team plays with some basic principles. Possession-based teams tend to hold the ball for long spells of play, passing the ball to destabilize a defense. We’ve seen that kind of team throughout the times, whether it be Guardiola’s Barcelona or del Bosque’s Spain.

The recent evolution of soccer has shown the push towards a more direct play, showing shorter possessions in not only duration but also passing. Teams will march up the field in three to four passes, aiming to destabilize the defense with longer balls and more possessions. 

But how does that change throughout a match? When a team is losing, do they deviate from their style? When they are winning, do they tend to adopt a different philosophy to secure three points? 

This is where the idea of Game State comes in.

Game State not only impacts how a team plays. It can impact the amount of moments a team can produce as they throw numbers forward, or how the defense is set up. When evaluating players, it’s not only about their full match metrics. Were they being put onto moments where their team became more direct, looking to get an equalizing goal? Or was the player taking advantage of a lead, where the defense is pushing forward to force an issue?

I wanted to dig deeper into those deviations at a macro level and how teams shifted their play in those moments. How did players react and could we analyze players on the same team in the same way? Using the 2015-2016 StatsBomb Premier League Data, we were able to dig deeper into this.

We begin by analyzing the teams at baseline. Overall, how do teams in the Premier League in 2015-16?



We see on average, Man City, United, Arsenal, Chelsea, and Everton have longer spells of possession. On the flip side, West Brom, Leicester, and Sunderland tend to be more direct, having fewer passes per possession and fewer seconds in possession. This is inclusive of all game states… so how can we go further in this? Well, for one, we can look at the min and maximum values of passing and time to see if teams deviate significantly and look further.



Teams like Arsenal, Tottenham, and Everton didn’t deviate too much from their play in each game state. Aston Villa, West Ham, and Swansea were extremes, with Villa having significant changes due to Game State. Liverpool, for example, did not have more passes per possession. They had almost four more seconds in possession, showing while their passing didn’t alter too much, their time on the ball did. To get the individual breakdown, I dove into each team’s GameState.



Let’s look at one team. Stoke City, when losing specifically, has slightly more passes and is on the ball a bit longer than usual. When they’re drawing, their passes per possession and duration slightly drop, and while they’re winning they have less of the ball in terms of duration and passes. 

Now, let’s look at two forwards on Stoke City. Marko Arnautović and Mame Biram Diouf, both of whom have completely different situations. Arnatovic is a starter for the club, starting 33 of 34 matches played. Diouf comes off the bench, with 26 matches played but only 12 starts. 

On the surface, just from their metrics, you may think that hey, Diouf and Arnatovic are players that both produce. Their metrics are almost identical when it comes to xG.



However, let’s break down their respective xG by Game State.


Diouf rarely has xG in winning game states, while Arnatovic, the club’s main forward, produces xG in the winning game state. One key difference is the loss game states, where Diouf produces more of his xG relative to Arnatovic. In those game states, Stoke City has more of the ball and is allowed more possession and more time on the ball. On the other side, drawing game states see not much deviation from Stoke’s overall style of play. 

Now, there’s a more level playing ground when analyzing the two forwards. Arnatovic produces his xG regardless of game state, while Diouf takes on the characteristics of a super sub. The team does play a bit differently in those moments, especially losing, so it may be worth investigating further his minutes played per each game state and the differences match to match. How do his metrics during the drawing game state measure home and away and in minute intervals?

Is that a player worth investing in? 

Furthermore, this analysis has no bounds. It can be broken down even further. However, the change of style by teams should be noted when analyzing player acquisitions. There is a difference and that not only can influence chance creation, but adding Game State and style of play in those moments can add more context to mitigate the risks of signing a player.


