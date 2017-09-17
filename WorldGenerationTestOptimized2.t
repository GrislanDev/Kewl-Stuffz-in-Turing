% Attempts Crown and Council inspired map generation, using structure of Conway's Game of Life
% Ooh - cool note! A higher value of iter (like 75 - 100) seems to make the sea level appear higher
% Any iter value under 25 is pretty trash .-.

/*
Update Goals:
- Different countries?
    - Diff colours
- Elevation?
*/

% Set up screen and input
View.Set ("offscreenonly")
setscreen ("graphics:600;600")
Mouse.ButtonChoose ("multibutton")

var mx, my, mb : int        % Prep for mouse input
var x, y : int              % The grid coordinates that mouse clicks correspond to
var font : int              % The font used

var gridlines : boolean := false     % Draw the gridlines, or nah?
var iter : int := 250   % Number of times decide is called
var count : int := 0

var cutDelay : int := round(iter * 0.08)     % Values of iter where no cuts are made, to allow blocks to grow
var threshold : int := round(iter * 0.93)   % Values of iter where rectangular cuts are allowed
var threshold2 : int := round(iter * 0.97)  % Values of iter where circular cuts are allowed

var w : int                         % Width of block
var gx, gy : int                    % Width and height of grid

font := Font.New ("Courier:10")
w := 4
gx := maxx div w
gy := maxy div w

var n : int

var chars : array char of boolean

% Prepare grid of blocks
var grid : array 0 .. gy, 0 .. gx of int
var gp : array 0 .. gy, 0 .. gx of int

proc mapGp
    for x : 0..gx
	for y : 0..gy
	    gp(y,x) := grid(y,x)
	end for
    end for
end mapGp

proc cut
    var width, height : int % Width and height of cut
    width := Rand.Int(0,gx div 3)
    height := Rand.Int(0,gy div 3)
    
    var sx, sy : int        % Where the cut starts (top right corner)
    sx := Rand.Int(0,gx)
    sy := Rand.Int(0,gy)
    
    for x : 0..width
	for y : 0..height
	    grid((sy+y) mod gy, (sx+x) mod gx) := 0
	    gp((sy+y) mod gy, (sx+x) mod gx) := 0
	end for
    end for
end cut

proc cut2
    var r : int % Radius of cut
    r := 6
    var sx, sy : int        % Where the cut box (circle is inside) starts (top right corner)
    var cx, cy : int        % Circle center

    for i : 0 .. Rand.Int (10, 20)
	sx := Rand.Int (0, gx)
	sy := Rand.Int (0, gy)


	cx := sx + r
	cy := sy + r

	for x : sx .. sx + r * 2
	    for y : sy .. sy + r * 2
		if sqrt (abs (cx - x) ** 2 + abs (cy - y) ** 2) < intreal (r) then
		    grid (y mod gy, x mod gx) := 0
		    gp (y mod gy, x mod gx) := 0
		end if
	    end for
	end for
    end for
end cut2

proc block
    var width, height : int % Width and height of block
    width := Rand.Int(0,gx div 3)
    height := Rand.Int(0,gy div 3)
    
    var sx, sy : int        % Where the block starts (top right corner)
    sx := Rand.Int(0,gx)
    sy := Rand.Int(0,gy)
    
    for x : 0..width
	for y : 0..height
	    grid((sy+y) mod gy, (sx+x) mod gx) := 1
	    gp((sy+y) mod gy, (sx+x) mod gx) := 1
	end for
    end for
end block

proc clearGrid
    for x : 0..gx
	for y : 0..gy
	    grid(y,x) := 0
	    gp(y,x) := 0
	end for
    end for
end clearGrid

proc generateGrid2
    for x : 0..5
	block
    end for
end generateGrid2

proc decide
    % Cut out chunks of land
    if cutDelay < count then
	if count < threshold and Rand.Int(0,4) = 0 then
	    cut
	elsif count < threshold2 and Rand.Int(0,2) = 0 then
	    cut2
	end if
    end if
    
    % Apply rules on all tiles
    for x : 0 .. gx
	for y : 0 .. gy        
	    % Count neighbours
	    n := 0
	    
	    if not grid(y, (x - 1) mod gx) = 0 then
		n += 1
	    end if
	    
	    if not grid((y - 1) mod gy, (x - 1) mod gx) = 0 then
		n += 1
	    end if
	    
	    if not grid((y + 1) mod gy, (x - 1) mod gx) = 0 then
		n += 1
	    end if
	    
	    if not grid(y, (x + 1) mod gx) = 0 then
		n += 1
	    end if
	    
	    if not grid((y - 1) mod gy, (x + 1) mod gx) = 0 then
		n += 1
	    end if
	    
	    if not grid((y + 1) mod gy, (x + 1) mod gx) = 0 then
		n += 1
	    end if

	    if not grid((y - 1) mod gy, x) = 0 then           
		n += 1
	    end if
	    
	    if not grid((y + 1) mod gy, x) = 0 then           
		n += 1
	    end if
	    
	    % Decides outcome of tile
	    if grid (y, x) = 0 then
		% Started dead
		if n >= 3 and Rand.Int(0,8-n) = 0 then   % Give life
		    gp(y,x) := 1
		end if
	    elsif n < 2 then
		gp(y,x) := 0
	    end if
	end for
    end for
    
    % Change are made to gp, then copied to grid (which is displayed)
    for x : 0..gx
	for y : 0..gy
	    grid(y,x) := gp(y,x)
	    if grid(y,x) = 0 then
		drawfillbox (x * w, y * w, x * w + w, y * w + w, 78)
	    elsif grid(y,x) = 1 then
		drawfillbox (x * w, y * w, x * w + w, y * w + w, 190)
	    end if
	end for
    end for
end decide

clearGrid
generateGrid2

loop
    decide
    Font.Draw(intstr(count)+":"+intstr(iter),10,10,font,7)
    View.Update()    
    count += 1
    exit when count = iter + 1
end loop

View.Update()
