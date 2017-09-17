% Block Game

% Set up screen and input
View.Set ("offscreenonly")
setscreen ("graphics:600;600")
Mouse.ButtonChoose ("multibutton")

var mx, my, mb : int        % Prep for mouse input
var x, y : int              % The grid coordinates that mouse clicks correspond to
var font : int              % The font used

var click : int     % Last clicked
click := 0
var stack : int     % Number of blocks cleared in one click
stack := 0
var moves : boolean
moves := true

var score, level, reach : int       % Player's score and level
var lives : int                     % How many lives the player has
var cmin, cmax : int                % Minimum colour and maximum colour
var w : int                         % Width of block
var gx, gy : int                    % Width and height of grid

var col : int                       % Colour of current selected block

var cx : int    % num of colours
cx := 10
var cols : array 0 .. cx of int     % Array of colours
for v : 0 .. cx by 2
    cols (v) := 32 + (cx - v)
end for
for v : 1 .. cx - 1 by 2
    cols (v) := 31 + v
end for

font := Font.New ("Courier:15")
w := 50
gx := (maxx - w * 2) div w
gy := (maxy - w * 2) div w

% Sets all values of visited (matrix of bool) to false
var visited : array 0 .. gy, 0 .. gx of boolean

% Prepare grid of blocks
var grid : array 0 .. gy, 0 .. gx of int

procedure generateGrid
    if score >= reach then
	reach += 175
	level += 1
	% Level up the player, increase colours
	cmax += 1
    end if
    
    for x : 0 .. gx
	for y : 0 .. gy
	    grid (y, x) := cols (Rand.Int (cmin, cmax))
	end for
    end for
end generateGrid

procedure drawGrid
    for x : 0 .. gx
	for y : 0 .. gy
	    drawfillbox (x * w + w, y * w + w, x * w + w * 2, y * w + w * 2, grid (y, x))
	end for
    end for
end drawGrid

procedure draw
    drawfillbox (0, 0, maxx, maxy, 27)
    drawGrid
    % Grid border
    drawbox (w, w, gx * w + w * 2, gy * w + w * 2, 7)
    %Font.Draw("chillo",5+w*gx,10+w*gy+w*2,font,32)
    Font.Draw ("Score: " + intstr (score), w, 12, font, 7)
    if lives > 0 then
	Font.Draw ("Lives: " + intstr (lives), w, 32, font, 7)
    else 
	Font.Draw ("Click to play again!", w, 32, font, 12)
    end if
    Font.Draw ("Level: " + intstr (level), w, w * gy + 7 + 2 * w, font, 7)
end draw

proc gravity
    % Moves bottom-up on each column of grid,
    % Pulls down each block with empty space below
    var done : boolean

    for c : 0 .. gx % loops through columns
	var cso : int   % find coloured blocks in column
	cso := 0
	for row : 0 .. gy
	    if grid (row, c) = 0 then
		done := false
	    else
		cso += 1
	    end if
	end for

	loop
	    % Scans bottom cso blocks, if they're all coloured then finish
	    done := true
	    for row : 0 .. cso - 1
		% If one of the bottom cso blocks is empty, flag done
		if grid (row, c) = 0 then
		    done := false
		end if
	    end for

	    if done then
		exit
	    else
		% Scan upwards for empty block, pull block above downwards
		for row : 0 .. gy
		    if grid (row, c) = 0 and row < gy then
			grid (row, c) := grid (row + 1, c)
			grid (row + 1, c) := 0
		    end if
		end for
	    end if
	end loop
    end for

    % If any of the bases are empty, drag columns towards the left
    var bc : int
    bc := 0
    % Find occupied columns
    for col : 0 .. gx
	if grid (0, col) not= 0 then
	    bc += 1
	end if
    end for

    loop
	done := true
	for col : 0 .. bc - 1
	    if grid (0, col) = 0 then
		done := false
	    end if
	end for

	if done then
	    exit
	else
	    for col : 0 .. gx
		if grid (0, col) = 0 and col < gx then
		    for row : 0 .. gy
			grid (row, col) := grid (row, col + 1)
			grid (row, col + 1) := 0
		    end for
		end if
	    end for
	end if
    end loop
end gravity

function clear (ax, ay, src, tar : int) : int       % DFS flood fill

    if ax < 0 or ax > gx or ay < 0 or ay > gy then
	result 0
    end if

    if visited (ay, ax) then
	result 0
    end if

    visited (ay, ax) := true

    if grid (ay, ax) not= src then
	result 0
    end if

    grid (ay, ax) := tar
    stack += 1
    var sum : int
    sum := 0
    sum += clear (ax + 1, ay, src, tar)
    sum += clear (ax - 1, ay, src, tar)
    sum += clear (ax, ay + 1, src, tar)
    sum += clear (ax, ay - 1, src, tar)
    result sum
end clear

proc prepClear
    for x1 : 0 .. gx
	for y1 : 0 .. gy
	    visited (y1, x1) := false
	end for
    end for
    stack := 0
end prepClear

function checkMoves () : boolean
    % returns a boolen of if there are any availible moves
    var c : int

    % Loops through grid, checking for neighbouring blocks of same colour
    for ay : 0 .. gy
	for ax : 0 .. gx
	    c := grid (ay, ax)
	    if not c = 0 then
		% Checks neighbouring blocks to see if any are the same colour
		if 0 < ax then
		    if grid (ay, ax - 1) = c then
			result true
		    end if
		end if
		if ax < gx then
		    if grid (ay, ax + 1) = c then
			result true
		    end if
		end if
		if 0 < ay then
		    if grid (ay - 1, ax) = c then
			result true
		    end if
		end if
		if ay < gy then
		    if grid (ay + 1, ax) = c then
			result true
		    end if
		end if
	    end if
	end for
    end for

    result false
end checkMoves

function countColBlocks () : int
    var c : int
    c := 0
    for ay : 0 .. gy
	for ax : 0 .. gx
	    if grid (ay, ax) not= 0 then
		c += 1
	    end if
	end for
    end for
    result c
end countColBlocks

proc setup
    score := 0
    level := 1
    reach := 175
    lives := 10
    
    x := 0
    y := 0

    cmin := 0
    cmax := 2

    col := 0
    
    prepClear
    generateGrid
    drawGrid
end setup

procedure input
    Mouse.Where (mx, my, mb)
    % Maps click to grid coordinate
    if mb = 1 and click >= 30 then  % in-game
	if 0 < lives then
	    click := 0
	    x := mx div w - 1
	    y := my div w - 1

	    if x < 0 then
		x := 0
	    elsif x > gx then
		x := gx
	    end if

	    if y < 0 then
		y := 0
	    elsif y > gy then
		y := gy
	    end if

	    % Find clicked colour
	    col := grid (y, x)
	    if col not= 0 then % No points for clearing empty blocks!
		% Flood clear blocks
		prepClear
		var r : int
		r := clear (x, y, col, 0)

		if stack > 1 then
		    score += stack + (stack div 3)
		    gravity
		else
		    % If only one block was clicked, don't clear it
		    grid (y, x) := col
		end if
	    end if  
	else    % Reset game
	    click := 0
	    setup   
	    delay(750)
	end if
    end if
end input

setup

loop
    loop
	moves := checkMoves ()
	if moves then
	    exit
	else
	    % Deduct lives for all coloured blocks left
	    if countColBlocks() > 0 then
		lives -= 1
	    end if
	    if lives < 0 then
		lives := 0
	    end if
	    generateGrid
	end if
    end loop

    input
    draw
    View.Update ()
    delay (10)
    click += 1
end loop
