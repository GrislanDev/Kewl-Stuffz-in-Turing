% Game of War
/*
This is based off of Conway's Game of Life.
New Stuff:
    - The colour limit is now the maxcol of Turing :D
    - Colour population counts are updated during the simulation
    - Made basic rules more flexible (potential for player to edit in future)
    - Prompts for the Editor mode, and the keyboard shortcuts
    
*/

% Set up screen and input
View.Set ("offscreenonly")
setscreen ("graphics:1000;620")
Mouse.ButtonChoose ("multibutton")

var mx, my, mb : int        % Prep for mouse input
var x, y : int              % The grid coordinates that mouse clicks correspond to
var font, small_font : int  % The font used

var click : int                     % Ticks since mouse was last clicked
var pressed : int                   % Ticks since spacebar last pressed
var gridlines : boolean := true     % Draw the gridlines, or nah?

var w : int                         % Width of block
var gx, gy : int                    % Width and height of grid

font := Font.New ("Courier:10")
small_font := Font.New ("Courier:8")
w := 20

var mode_x := w  % Position of the mode text
var mode_y := maxy - 15

gx := (maxx - w * 2) div w
gy := (maxy - w * 2) div w

var mode : int  % Idle --> Simulate --> Repeat4
var n : int

var col : int := 8                          % Number of colours there can be (including dead)
var pen_col : int := 1                      % Colour to be drawn in editor
var ng : array 1 .. col of int              % Num of neighbours of each colour
var population : array 0 .. col of int      % Count of the population of each colour
var most_c, n_c : int                       % Way to find most common neighbour

var live_r : string := "23"         % Rules on how the game is run
var birth_r : string := "3"

var chars : array char of boolean

% Prepare grid of blocks
var grid : array 0 .. gy, 0 .. gx of int
var gp : array 0 .. gy, 0 .. gx of int

proc generateGrid
    for x : 0 .. gx
	for y : 0 .. gy
	    if Rand.Int (0, 5) = 0 then
		grid (y, x) := Rand.Int (1, col - 1)
	    else
		grid (y, x) := 0
	    end if
	    gp (y, x) := grid (y, x)
	end for
    end for
end generateGrid

proc drawGrid
    for x : 0 .. gx
	for y : 0 .. gy
	    drawfillbox (x * w + w, y * w + w, x * w + w * 2, y * w + w * 2, grid (y, x))
	    % Gridlines
	    if gridlines then
		drawline (w, w + w * y, maxx - w, w + w * y, 7)
	    end if
	end for
	% Gridlines
	if gridlines then
	    drawline (w + w * x, w, w + w * x, maxy - w, 7)
	end if
    end for
end drawGrid

proc draw
    if mode = 1 then
	drawfillbox (0, 0, maxx, maxy, 20)
	Font.Draw("GAME OF WAR: SIMULATION MODE (SPACE TO EDIT)",mode_x,mode_y,font,0)
    else
	drawfillbox (0, 0, maxx, maxy, 23)
	Font.Draw("GAME OF WAR: EDITOR MODE (SPACE TO SIMULATE, CLICK TO DRAW)",mode_x,mode_y,font,0)
	% Displays pen colour
	Font.Draw("CURRENT COLOUR: "+intstr(pen_col),maxx-w*2-Font.Width("CURRENT COLOUR: "+intstr(pen_col),font),5,font,0)
	drawfillbox(maxx-w*2+4,4,maxx-w-4,w-5,pen_col)
    end if
    Font.Draw("[1] SPAWN NEW GRID || [2] CLEAR GRID || [3] TOGGLE GRIDLINES || [4] CHANGE PEN",mode_x,5,font,0)
    
    drawGrid
    % Grid border
    drawbox (w, w, gx * w + w * 2, gy * w + w * 2, 7)
    
    % Draw population counts
    var ty := maxy - w - 8
    for c : 1 .. col
	if population(c) > 0 then
	    Font.Draw(intstr(c)+":"+intstr(population(c)),w+3,ty,small_font,c)
	    ty -= 8
	end if
    end for
end draw

proc setup
    mode := 0
    click := 0
    pressed := 0
    gridlines := false
    generateGrid
end setup

proc decide
    % Apply rules on all tiles
    for x : 0 .. gx
	for y : 0 .. gy
	    % Clear neighbour colour track
	    for i : 1 .. col
		ng (i) := 0
	    end for

	    % Count neighbours
	    n := 0

	    if not grid (y, (x - 1) mod gx) = 0 then
		n += 1
		ng (grid (y, (x - 1) mod gx)) += 1
	    end if

	    if not grid ((y - 1) mod gy, (x - 1) mod gx) = 0 then
		n += 1
		ng (grid ((y - 1) mod gy, (x - 1) mod gx)) += 1
	    end if

	    if not grid ((y + 1) mod gy, (x - 1) mod gx) = 0 then
		n += 1
		ng (grid ((y + 1) mod gy, (x - 1) mod gx)) += 1
	    end if

	    if not grid (y, (x + 1) mod gx) = 0 then
		n += 1
		ng (grid (y, (x + 1) mod gx)) += 1
	    end if

	    if not grid ((y - 1) mod gy, (x + 1) mod gx) = 0 then
		n += 1
		ng (grid ((y - 1) mod gy, (x + 1) mod gx)) += 1
	    end if

	    if not grid ((y + 1) mod gy, (x + 1) mod gx) = 0 then
		n += 1
		ng (grid ((y + 1) mod gy, (x + 1) mod gx)) += 1
	    end if

	    if not grid ((y - 1) mod gy, x) = 0 then
		n += 1
		ng (grid ((y - 1) mod gy, x)) += 1
	    end if

	    if not grid ((y + 1) mod gy, x) = 0 then
		n += 1
		ng (grid ((y + 1) mod gy, x)) += 1
	    end if

	    % Finds the most common colour of neighbours (not including dead)
	    most_c := 0
	    for c : 1..col
		if ng(c) > most_c then
		    most_c := ng(c)
		    n_c := c
		end if
	    end for
	    
	    % Decides outcome of tile
	    if grid (y, x) = 0 then
		% Started dead
		if index (birth_r, intstr (n)) > 0 then % Give life
		    gp(y,x) := n_c
		end if
	    else
		% Started alive
		if index (live_r, intstr (n)) = 0 then % Kill
		    gp (y, x) := 0
		end if
	    end if
	end for
    end for

    % Change are made to gp, then copied to grid (which is displayed)
    for c : 0 .. col
	population(c) := 0
    end for
    for x : 0 .. gx
	for y : 0 .. gy
	    grid (y, x) := gp (y, x)
	    population (gp (y, x)) += 1
	end for
    end for
end decide

proc clearGrid
    for x : 0 .. gx
	for y : 0 .. gy
	    grid (y, x) := 0
	    gp (y, x) := 0
	end for
    end for
    decide
end clearGrid

proc input
    % Gather keyboard input
    if pressed >= 10 then
	Input.KeyDown (chars)
	if chars (chr (ORD_SPACE)) then
	    mode := (mode + 1) mod 2
	    pressed := 0
	elsif chars (chr (ORD_1)) then
	    % Hotkey 1 generates grid and pauses
	    generateGrid
	    mode := 0
	    pressed := 0
	elsif chars (chr (ORD_2)) then
	    % Hotkey 3 clears grid and pauses
	    clearGrid
	    mode := 0
	    pressed := 0
	elsif chars (chr (ORD_3)) then
	    % Hotkey 2 toggles gridlines
	    gridlines := not (gridlines)
	    pressed := 0
	elsif chars (chr (ORD_4)) then
	    % Hotkey 4 changes pen colour
	    pen_col := (pen_col+1) mod col
	    pressed := 0
	end if
    end if

    Mouse.Where (mx, my, mb)
    % Maps click to grid coordinate
    if mb = 1 and click >= 5 then
	if mode = 0 then      % edit mode
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

	    grid (y, x) := pen_col
	    gp (y, x) := grid (y, x)

	    click := 0
	end if
    end if
end input

setup
decide
loop
    input
    if mode = 1 then
	decide
	delay (45)
    end if
    draw

    View.Update ()

    click += 1
    pressed += 1
end loop
