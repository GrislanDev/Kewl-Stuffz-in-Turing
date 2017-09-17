% This is the basis of a clicker!
View.Set ("offscreenonly")
setscreen ("graphics:640;400")

var points : int        % total points
var clickValue : int    % points gained per click
var idleTicks : int     % time before idle points are gained
var idleValue : int     % points per unit time

var chars : array char of boolean   % Set up keyboard input
var hit : boolean := false
var c : int := 0

points := 0
clickValue := 1
idleTicks := 100
idleValue := 5

var level : int     % current level
level := 1
var xp : int        % xp gained since previous level
xp := 0
var xpNeeded : int  % xp needed to advance to next level
xpNeeded := 20

var mouseX, mouseY, button : int    % prepare for mouse input
var lastClicked : int               % time at which mosue was last pressed
lastClicked := 0
const mouseWait : int := 2          % time that needs to pass between mouse detection
const FPS : int := 20               % ticks per second
var ticks : int                     % keep track of how many ticks have passed
ticks := 0

var bigFont : int                   % prepare to draw font
bigFont := Font.New ("Impact:75")
var smallFont : int
smallFont := Font.New ("Impact:25")

var fontCol : int
var backgroundCol : int
fontCol := 101
backgroundCol := 1

var messages : array 1 .. 10 of string
messages (1) := "WHAT A PRO!"
messages (2) := "DAMN SON!"
messages (3) := "CLICK DAT!"
messages (4) := "SUCH POWER!"
messages (5) := "LEGENDARY!"
messages (6) := "WHAT A LEGEND!"
messages (7) := "BOI WADDUP!"
messages (8) := "GEEZ YOU'RE GOOD!"
messages (9) := "WHY YOU SO GOOD?!"
messages (10) := "TEACH ME YOUR WAYS!"
var message : int
randint (message, 1, 10)

process playMusic
    loop
	Music.PlayFile ("time.mp3")
    end loop
end playMusic

fork playMusic
loop
    Draw.FillBox (0, 0, 640, 400, backgroundCol)
    hit := false

    % Take in input
    Mouse.Where (mouseX, mouseY, button)
    Input.KeyDown (chars)
    if ticks - lastClicked > mouseWait then
	if button = 1 then
	    points := points + clickValue
	    xp := xp + clickValue
	    lastClicked := ticks
	else
	    c := 32
	    loop
		exit when (c = 126 or hit)
		hit := chars (chr (c))
		c += 1
	    end loop
	    if hit then
		points := points + clickValue
		xp := xp + clickValue
		lastClicked := ticks
	    end if
	end if
    end if

    % Add idle points
    if ticks mod idleTicks = 0 then
	points := points + idleValue
	xp := xp + round (idleValue * 0.2)
    end if

    % Determine if player has leveled up
    if xp > xpNeeded then
	level := level + 1
	fontCol := (level + 100) mod 247
	backgroundCol := level mod 247
	xp := 0
	xpNeeded := round (xpNeeded * 1.2)

	idleValue := round (idleValue * 1.2)
	idleTicks := round (idleTicks * 0.95)
	clickValue := clickValue + 1
	randint (message, 1, 10)
    end if

    Font.Draw (intstr (points), 20, 60, bigFont, fontCol)
    Font.Draw ("LVL: " + intstr (level), 10, 150, smallFont, fontCol)
    Font.Draw (messages (message), 10, 360, smallFont, fontCol)

    Draw.FillBox (10, 10, round (640 * (xp / xpNeeded)), 50, fontCol)
    Draw.FillBox (0, 0, 10, 400, backgroundCol)
    Draw.FillBox (630, 0, 640, 400, backgroundCol)

    View.Update ()
    delay (1000 div FPS)
    ticks := ticks + 1
end loop
