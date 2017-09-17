/*
 Challenge: Create a an evolutionary AI simulator that can evolve to
 go from the left side of the screen to the right without colliding into
 any circular obstacles.
 
 UPDATE:
 Now I'll add a grid-based level, to see how it copes with a maze.
 */

View.Set ("offscreenonly")
View.Set ("graphics")
setscreen ("graphics:800;400")

const obRmin : int := 50        % Minimum radius of obstacle
const obRmax : int := 50        % Maximum radius of obstacle
const goalR : int := 50     % Radius of goal

var obNum : int := 10   % Number of obstacles
var botNum : int := 50 % Number of bots
var gen : int := 1      % Current generation
var goalScale : real    % Scales distance from start to goal
var finCount : int      % Counts number of finished bots
var successCount : int  % Number of successful bots

var ticks : int     % Ticks since beginning of generation

var goalX : int     % Position of final goal
var goalY : int

var obs : array 1 .. obNum, 0 .. 2 of int                 % Stores info on each obstacle [x,y,radius]
var botPaths : array 1 .. botNum, 0 .. 19, 0 .. 1 of int  % Stores info on botPaths [[x,y] ..]
var botInfo : array 1 .. botNum, 0 .. 4 of int            % Stores info on each bot's stats [x,y,progress,fitness,done]

proc generateTerrain
    for o : 1 .. obNum
	obs (o, 2) := Rand.Int (obRmin, obRmax)
	obs (o, 0) := Rand.Int (obs (o, 2) * 2, maxx - obs (o, 2) * 2)
	obs (o, 1) := Rand.Int (obs (o, 2) * 2, maxy - obs (o, 2) * 2)
    end for

    goalX := maxx
    goalY := Rand.Int (goalR * 2, maxy - goalR * 2)
    goalScale := 100 / Math.Distance (goalX, goalY, 0, maxy div 2)
end generateTerrain

proc spawnBots (first : boolean)
    if first then
	for b : 1 .. botNum
	    botInfo (b, 0) := 0
	    botInfo (b, 1) := maxy div 2
	    botInfo (b, 2) := 0
	    botInfo (b, 3) := 0
	    botInfo (b, 4) := 0

	    for w : 0 .. 19 % Paths start at spawn, then randomly change from each point afterwards
		if w = 0 then
		    botPaths (b, w, 0) := botInfo (b, 0) + Rand.Int (0, 50)
		    botPaths (b, w, 1) := botInfo (b, 1) + Rand.Int (-50, 50)
		else
		    botPaths (b, w, 0) := botPaths (b, w - 1, 0) + Rand.Int (-50, 50)
		    botPaths (b, w, 1) := botPaths (b, w - 1, 1) + Rand.Int (-50, 50)
		end if
	    end for
	end for
    else
	gen += 1
	% Find top bots by fitness, replicate them and mutate
	var a : array 1 .. botNum of int
	var chosen : array 1 .. botNum of boolean
	var top : array 1 .. 10 of int

	for x : 1 .. botNum
	    a (x) := botInfo (x, 3)
	    chosen (x) := false
	end for

	for iter : 1 .. 10
	    var m := 0
	    for i : 1 .. botNum
		if not chosen (i) and a (i) >= m then
		    m := a (i)
		end if
	    end for

	    for i : 1 .. botNum
		if not chosen (i) and a (i) = m then
		    chosen (i) := true
		    for w : 0 .. 19
			for g : 0 .. 4
			    botPaths (iter * 5 - g, w, 0) := botPaths (i, w, 0) + Rand.Int (-3 * g, 3 * g)  % Mutation amount scales up with each replication
			    botPaths (iter * 5 - g, w, 1) := botPaths (i, w, 1) + Rand.Int (-3 * g, 3 * g) 
			end for
		    end for
		    exit
		end if
	    end for
	end for

	for b : 1 .. botNum
	    botInfo (b, 0) := 0
	    botInfo (b, 1) := maxy div 2
	    botInfo (b, 2) := 0
	    botInfo (b, 3) := 0
	    botInfo (b, 4) := 0
	end for
    end if
end spawnBots

proc update
    cls
    % Draw goal
    drawfilloval (goalX, goalY, goalR, goalR, 28)

    % Draw waypoints
    for b : 1 .. botNum
	for w : 0 .. 19
	    drawfilloval (botPaths (b, w, 0), botPaths (b, w, 1), 1, 1, 103)
	end for
    end for

    % Update and draw bots
    var u : real
    var oldX, oldY : int
    for b : 1 .. botNum
	if botInfo (b, 4) = 0 then
	    oldX := botInfo (b, 0)
	    oldY := botInfo (b, 1)

	    % Move towards current waypoint on path
	    u := Math.Distance (botPaths (b, botInfo (b, 2), 0), botPaths (b, botInfo (b, 2), 1), botInfo (b, 0), botInfo (b, 1))
	    if u > 0 then
		botInfo (b, 0) := round (botInfo (b, 0) + ((botPaths (b, botInfo (b, 2), 0) - botInfo (b, 0)) / u))
		botInfo (b, 1) := round (botInfo (b, 1) + ((botPaths (b, botInfo (b, 2), 1) - botInfo (b, 1)) / u))
	    end if

	    % Update bot's path
	    if botInfo (b, 0) = botPaths (b, botInfo (b, 2), 0) and botInfo (b, 1) = botPaths (b, botInfo (b, 2), 1) then
		botInfo (b, 2) += 1
	    end if

	    % Check collisions
	    if botInfo (b, 2) = 19 then
		% Bot finished path
		botInfo (b, 3) := 120 - round(Math.Distance (botInfo (b, 0), botInfo (b, 1), goalX, goalY) * goalScale)
		botInfo (b, 4) := 1
		finCount += 1
	    elsif not (0 < botInfo (b, 0) and botInfo (b, 0) < maxx and 0 < botInfo (b, 1) and botInfo (b, 1) < maxy) then
		% Bot is offscreen, set fitness depending on distance from goal
		botInfo (b, 3) := 100 - round(Math.Distance (botInfo (b, 0), botInfo (b, 1), goalX, goalY) * goalScale)
		botInfo (b, 4) := 1
		finCount += 1
	    elsif Math.Distance (botInfo (b, 0), botInfo (b, 1), goalX, goalY) < goalR then
		% Bot reached goal
		botInfo (b, 3) := 500 - (ticks div 150)
		botInfo (b, 4) := 1
		finCount += 1
		successCount += 1
	    else
		% Check collision with all obstacles
		for o : 1 .. obNum
		    if Math.Distance (botInfo (b, 0), botInfo (b, 1), obs (o, 0), obs (o, 1)) < obs (o, 2) then
			botInfo (b, 3) := 70 - round(Math.Distance (botInfo (b, 0), botInfo (b, 1), goalX, goalY) * goalScale)
			botInfo (b, 4) := 1
			finCount += 1
			exit
		    end if
		end for
	    end if

	    drawfilloval (botInfo (b, 0), botInfo (b, 1), 2, 2, 104)   % Draw dot
	end if
    end for

    % Draw obstacles
    for o : 1 .. obNum
	drawfilloval (obs (o, 0), obs (o, 1), obs (o, 2), obs (o, 2), 7)
    end for
    
    locate (1, 1)
    put "GEN: ", gen ..
    locate (2, 1)
    %put "SURVIVAL RATE: ", ((botNum - finCount) / botNum * 100):0:1, "%" ..
end update

generateTerrain
spawnBots (true)
loop
    finCount := 0
    successCount := 0
    ticks := 0
    loop
	% Move bots until all are finished
	ticks += 1
	update
	exit when finCount = botNum
	View.Update ()
    end loop
    % Spawn next generation
    spawnBots (false)
end loop

