% Allows the user to use the mouse to edit frequency and speed envelopes for Music.Sound

View.Set ("offscreenonly")
setscreen ("graphics:max;max")
Mouse.ButtonChoose ("multibutton")

var mx, my, mb : int                % Prep for mouse input
var chars : array char of boolean   % Prep for keyboard input
var last : int := 50                % Ticks since space bar last pressed

var mode : int := 0         % Freq Edit = 0, Tempo Edit = 1
var pos : int := 1          % Position of envelope

const w : int := 25         % Width of column
var c : int                 % Number of columns

c := maxx div w

const minFreq : int := 2500     % Minimum frequency
const maxFreq : int := 3000     % Maximum frequency

const minTemp : int := 50     % Minimum tempo
const maxTemp : int := 1000     % Maximum tempo

var freq : array 1 .. c of int  % Values of frequency envelope
var temp : array 1 .. c of int  % Values of tempo envelope

const freqScale : real := (maxy - w * 2) / (maxTemp - minTemp)
const tempScale : real := (maxy - w * 2) / (maxTemp - minTemp)

% Set up fonts
var titleFont : int := Font.New ("Courier:35")
var infoFont : int := Font.New ("Courier:10")

% Set up initial values
for i : 1 .. c
    freq (i) := Rand.Int(w,maxy-w)  % round(maxy * 0.65)
    temp (i) := Rand.Int(w,maxy-w)  % round(maxy * 0.45)
end for

function limit (n : int, mini : int, maxi : int) : int
    % Takes n and makes sure it's mini < n < maxi
    if n < mini then
	result mini
    elsif n > maxi then
	result maxi
    end if
    result n
end limit

process roll
    % Plays the envelope
    loop
	Music.Sound (round (freq (pos) * freqScale), round (((maxy - w * 2) - temp (pos)) * tempScale))
	pos += 1
	if pos > c then
	    pos := 1
	end if
    end loop
end roll

proc draw
    drawfillbox(0,0,maxx,maxy,7)
    %Font.Draw("GOBLIN",w,0,titleFont,19)

    % Draw line of progress
    drawline (pos * w, w, pos * w, maxy - w, 19)
    % Draws each point of each envelope
    for i : 1 .. c
	if i < c then
	    % Tempo envelope
	    drawline (i * w, temp (i), (i + 1) * w, temp (i + 1), 10)
	    % Freq envelope
	    drawline (i * w, freq (i), (i + 1) * w, freq (i + 1), 40)
	end if
    end for
    
    % Draw info
    %Font.Draw(intstr(freq(pos)),w+15,w+15,infoFont,40)
    %Font.Draw(intstr(temp(pos)),w+15,w+35,infoFont,10)
    
    % Draw border indicating mode
    if mode = 0 then
	drawbox (w, w, maxx - w, maxy - w, 40)
	Font.Draw("FREQUENCY ENVELOPE",w+15,w+15,infoFont,40)
    else
	drawbox (w, w, maxx - w, maxy - w, 10)
	Font.Draw("TEMPO ENVELOPE",w+15,w+15,infoFont,10)
    end if
    
    % Fix artifacts of envelope to the right
    drawfillbox (maxx - w + 1, 0, maxx, maxy, 7)
    View.Update ()
end draw

proc input
    % Uses space to toggle through modes
    Input.KeyDown (chars)
    if chars (chr (ORD_SPACE)) and last > 50 then
	mode := (mode + 1) mod 2
	last := 0
    end if

    % When clicking, map mouse input to envelopes
    Mouse.Where (mx, my, mb)

    if mb = 1 then
	mx := limit (mx, w, maxx)
	if mode = 0 then
	    freq (mx div w) := limit (my, w, maxy - w)
	else
	    temp (mx div w) := limit (my, w, maxy - w)
	end if
    end if
end input

fork roll
loop
    draw
    input
    last += 1
end loop
