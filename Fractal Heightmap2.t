View.Set("graphics:513;513")
View.Set("offscreenonly")
View.Set("nobuttonbar")

const maxX : int := maxx
const maxY : int := maxcolour

const variMaxDecay : real := 0.7
const variMinDecay : real := 0.72

RGB.SetColour(0, 0, 0, 150)
for clr : 1 .. maxcolour
    RGB.SetColour(maxcolour + 1 - clr, 0, clr, 0)
end for

% Stores heights
var map : array 0 .. maxX, 0 .. maxX of int

% Stores whether each point has been created
var created : array 0 .. maxX, 0 .. maxX of boolean

% Width between points for each iteration
var width : int := maxX

% Variation applied after averages
var variMax : int := maxY div 2
var variMin : int := maxY div 2

proc setup
    width := maxX div 2
    variMax := maxY div 2
    variMin := maxY div 2
    for y : 0 .. maxX
	for x : 0 .. maxX
	    created(y, x) := false
	    map(y, x) := 0
	end for
    end for
    
    map(0,0) := Rand.Int(0, maxY)
    map(maxX,0) := Rand.Int(0, maxY)
    map(maxX,maxX) := Rand.Int(0, maxY)
    map(0,maxX) := Rand.Int(0, maxY)
    
    created(0,0) := false
    created(maxX,0) := false
    created(maxX,maxX) := false
    created(0,maxX) := false  
end setup

proc draw
    drawfillbox(0,0,maxx,maxy,0)
    % Displays heightmap
    for y : 0 .. maxX
	for x : 0 .. maxX
	    if created(y, x) then
		drawdot(x, y, min(max(0,map(y, x)+1),maxcolour))
	    end if
	end for
    end for
    View.Update()
end draw

proc diamond
    for y : width .. maxX - width by width * 2
	for x : width .. maxX - width by width * 2
	    if not(created(y,x)) then
		map(y,x) := (map(y - width, x - width) + map(y - width, x + width) + map(y + width, x + width) + map(y + width, x - width)) div 4
		map(y,x) += Rand.Int(-variMin, variMax)
		created(y,x) := true
	    end if
	end for
    end for
end diamond

proc square
    for y : width .. maxX - width by width
	for x : width .. maxX - width by width
	    if not(created(y,x)) then
		map(y,x) := (map((y - width) mod maxX, x) + map((y + width) mod maxX, x) + map(y, (x + width) mod maxX) + map(y, (x - width) mod maxX)) div 4
		map(y,x) += Rand.Int(-variMin, variMax)
		created(y,x) := true
	    end if            
	end for
    end for
end square

proc generate
    diamond
    draw
    square
    draw
    
    % Decrease the interval size
    if width > 1 then
	width := width div 2
	% Decrease the variation for each interval
	if variMax > 1 then
	    variMax := floor(variMax * variMaxDecay)
	end if
	if variMin > 1 then
	    variMin := floor(variMin * variMinDecay)
	end if
	generate
    % If the width is 1 our job is done (rhymes XD)
    else
	draw
    end if
end generate

var key : string(1)
loop
    setup
    generate
    getch(key)
end loop

