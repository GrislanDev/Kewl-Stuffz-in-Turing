Mouse.ButtonChoose ("multibutton")
View.Set ("offscreenonly")
View.Set("title:Edgy 6")
View.Set("nobuttonbar")
View.Set ("graphics:max;max")

/*
 WELCOME TO EDGY 6
 Highscore : TBD

 This is an action arcade game where you control a ball
 and try to avoid being hit by other balls. Simple?

 Controls (Arrow Keys also work in place of WASD):
 W - Accelerate upwards
 A - Accelerate to the left
 S - Accelerate downwards
 D - Accelerate to the right

 Space Bar / E - Heal HP at the cost of some energy
 Q - Activate special ability
 Mouse - Click the Retry Button

 Gameplay Notes:

 The green bar is your HP - it doesn't regenerate.
 Red balls decrease your HP when they hit your white core.
 Going offscreen decreases HP.

 The blue bar is your energy - it regenerates over time.
 Energy decreases when you heal and move.

 The pink bar is your special charge. Once it fills, you
 can hit SPACE to activate your special ability (slows down all bullets)

 There are bullets to avoid, they are red.
 Large bullets hit hard but move slow.
 Some bullets will aim at you, they get more accurate as the game progresses.

 The number in the bottom left is the Wave you're on. Higher = Harder
 You drift - so watch out for gliding errors. :)


 NEW STUFF:
 04-25-2017 - Fixed Special Ability Bugs, Healing improvements, Nerfed Special Ability (slower charge)
 - Heal ratio is 1 ENG : 1 HP for a max of hamount at a time.
 05-13-2017 - New Bullet Type (bul(6,2)) --> "Pest"
 - Aims directly at player, slows down as it gets near
 - Very annoying, tricky to get rid of
 - Changed bullet spawn rates
 - "Follower" (bul(6,0)) now spawns every 3rd level
 - "Pest" spawns every 4th level (as long as the follower doesn't spawn on the same level)
 - The first 3 bullets are now 2 Followers and a Wild
 - Player size is now 15 instead of 20, for more maneuvering space
 05-20-2017 - Added E as a key binding for heal
 - Removed SPACE as key binding for ability, must now hit Q to activate
 - Before each game, choose your character
 06-20-2017 - Implemented NIGHTFOX and FLAMEHAWK Character's abilities
 - NIGHTFOX: The Standard Character from edgy4
 - Heal ratio 1.25 ENG : 1 HP
 - Special: Bullets do 50% less damage
 - FLAMEHAWK: A faster and smaller rogue-like character
 - Less HP, More speed, Heal ratio 1.5 ENG : 1 HP
 - Special: Slow Down all Bullets (pretty fast charge)
 - STEELHEART: A tankier character - IN PROGRESS
 - More HP, less speed, Heal ratio 1 ENG : 1 HP
 - Special: Temporary Armour (Damage goes to this first, but the armour health decays even when not hit)
 - Changed heal mechanism, hcost is now the ENG cost of heal 1 HP.
 08-05-2017 - Implemented STEELHEART ability
 - Lasts about 20 seconds, loses durability over time and when taking damage
 - If hit by a bullet, damage is subtracted from specAmount instead of HP
 - Damage won't leak over into HP if damage is more than remaining specAmount
 - NIGHTFOX buff:
 - Ability now increases energy regen to 1.75 from 1
 - Added awesome loading animation
 - No functionality
 - Previously, hitting RESTART would also make you pick a character right away
 - Now you can select characters between games
 */

var px, py, pvx, pvy, change : real % Player pos, vel

var mx, my, mb : int            % Mouse pos and button
var chars : array char of boolean

var lcost, fcost, last : int   % Energy cost of lazer and movement, last clicked
lcost := 5
fcost := 2
last := 0

var friction : real     % Multiplied onto vel to slow player down
friction := 0.93

var accelerate : real   % bullet acceleration
accelerate := 0.99
var level : int
var reach : int    % Score required to reach next level

var hcost, hamount : real % Cost of instant heal and heal amount

var psize : int                 % Player's size
var maxHP : real            % Player's maxHP
var maxENG : real          % Player's maxENG
var hpScale, engScale : real
var hp, eng : real              % Player's HP and ENG

var bn : int := 3   % Num of bullets
var bul : array 1 .. 1000000, 0 .. 8 of real % Array of basic bullets and their info
% (xPos,yPos,xVel,yVel,aim,type,colour, finished)

var charge : real       % Current charge of player's special
var chargeSpeed : real  % Speed at which the charge regens
var specTicks : real    % Time left before special dies
var specAmount : real   % Effect of special
var specLength : real   % Length of special time

const maxv := 20 % Maximum bullet velocity

var ticks, score, scoreproxy : int  % Ticks since run and player score
var scorestr, levelstr : string               % String representing score and level

var onscreen : boolean     % Is the player in bounds?

const td : int := 15       % Milliseconds between ticks
var cont, loopcont : boolean      % Should game continue?
loopcont := true

var font : int                   % prepare to draw font
var textx, textx2, textx3 : int
font := Font.New ("Impact:75")
textx := (maxx - Font.Width ("YOU DEAD.", font)) div 2
textx2 := (maxx - Font.Width ("RETRY", font)) div 2
textx3 := (maxx - Font.Width ("00000000000", font)) div 2

var character : string  % Character type of player

procedure spawnBul (x : int, t : int) % Spawns bullet
    bul (x, 4) := intreal (Rand.Int (10, 15)) % Size
    bul (x, 5) := 0.2       % Aim of bullet
    bul (x, 6) := t         % Bullet type (follow, wild)
    bul (x, 8) := 0

    % Set colour
    bul (x, 7) := 40


    % Determine vel based on size and pos
    if Rand.Int (0, 1) = 0 then
	bul (x, 0) := Rand.Int (0, maxx)
	bul (x, 2) := 0
	if Rand.Int (0, 1) = 0 then
	    bul (x, 1) := maxy - 5
	    bul (x, 3) := (50 - bul (x, 4)) * -0.02
	else
	    bul (x, 1) := 5
	    bul (x, 3) := (50 - bul (x, 4)) * 0.02
	end if
    else
	bul (x, 1) := Rand.Int (0, maxy)
	bul (x, 3) := 0
	if Rand.Int (0, 1) = 0 then
	    bul (x, 0) := maxx - 5
	    bul (x, 2) := (50 - bul (x, 4)) * -0.02
	else
	    bul (x, 0) := 5
	    bul (x, 2) := (50 - bul (x, 4)) * 0.02
	end if
    end if
end spawnBul

proc load
    var times : int := 0
    var rad : real := 22
    var radVel : real := 0.2

    var a, b, aVel : real
    var mode : boolean := true
    a := 0
    b := 0
    aVel := 0.1

    var ringRad : int := 75

    loop
	rad += radVel
	radVel *= 1.02
	aVel *= 1.01

	if rad > maxy div 2 then
	    radVel := -0.2
	elsif rad < 20 then
	    radVel := 0.2
	    times := 5
	end if

	if mode then
	    b += 2
	    if b >= 360 then
		mode := false
	    end if
	else
	    b -= 2
	    if b <= 0 then
		mode := true
	    end if
	end if

	if abs (aVel) > 4 and sign (aVel) = 1 then
	    aVel := -0.1
	elsif abs (aVel) > 4 and sign (aVel) = -1 then
	    aVel := 0.1
	end if

	a += aVel

	drawfillbox (0, 0, maxx, maxy, 7)
	for i : 0 .. rad div ringRad
	    drawfillarc (maxx div 2, maxy div 2, floor (rad) - i * ringRad, floor (rad) - i * ringRad, floor (a mod 360 + i * 240), floor ((a + b) mod 360 + i * 240), 40)
	    drawfilloval (maxx div 2, maxy div 2, floor (rad) - i * ringRad - 10, floor (rad) - i * ringRad - 10, 7)
	end for
	View.Update ()
	delay (5)
	exit when times = 5
    end loop
end load

procedure setup % Resets game
    % Loading animation
    load
    % Draw buttons to choose class
    drawfillbox (0, 0, maxx, maxy, 7)
    drawbox ((maxx - Font.Width ("NIGHTFOX", font)) div 2, (maxy - 300) div 2, (maxx - Font.Width ("NIGHTFOX", font)) div 2 + Font.Width ("NIGHTFOX", font), (maxy - 300) div 2 + 100, 40)
    drawbox ((maxx - Font.Width ("FLAMEHAWK", font)) div 2, (maxy - 300) div 2 + 100, (maxx - Font.Width ("FLAMEHAWK", font)) div 2 + Font.Width ("FLAMEHAWK", font), (maxy - 300) div 2 + 200, 40)
    drawbox ((maxx - Font.Width ("STEELHEART", font)) div 2, (maxy - 300) div 2 + 200, (maxx - Font.Width ("STEELHEART", font)) div 2 + Font.Width ("STEELHEART", font), (maxy - 300) div 2 + 300, 40)
    Font.Draw ("NIGHTFOX", (maxx - Font.Width ("NIGHTFOX", font)) div 2, (maxy - 300) div 2 + 10, font, 40)
    Font.Draw ("FLAMEHAWK", (maxx - Font.Width ("FLAMEHAWK", font)) div 2, (maxy - 300) div 2 + 110, font, 40)
    Font.Draw ("STEELHEART", (maxx - Font.Width ("STEELHEART", font)) div 2, (maxy - 300) div 2 + 210, font, 40)

    View.Update ()
    % Wait for class to be chosen
    loop
	Mouse.Where (mx, my, mb)
	if mb = 1 then
	    if (maxx - Font.Width ("NIGHTFOX", font)) div 2 < mx and mx < (maxx - Font.Width ("NIGHTFOX", font)) div 2 + Font.Width ("NIGHTFOX", font) then
		if (maxy - 300) div 2 < my and my < (maxy - 300) div 2 + 100 then
		    character := "NIGHTFOX"
		    maxHP := 360
		    maxENG := 360

		    hp := maxHP
		    eng := maxENG
		    psize := 15

		    fcost := 3
		    hcost := 1.5    % ENG cost per 1 HP
		    hamount := 60
		    change := 0.7

		    specTicks := 0.0
		    specAmount := 1.5
		    specLength := 300

		    charge := 0.0
		    chargeSpeed := 0.6
		    exit
		end if
	    end if
	    if (maxx - Font.Width ("FLAMEHAWK", font)) div 2 < mx and mx < (maxx - Font.Width ("FLAMEHAWK", font)) div 2 + Font.Width ("FLAMEHAWK", font) then
		if (maxy - 300) div 2 + 100 < my and my < (maxy - 300) div 2 + 200 then
		    character := "FLAMEHAWK"
		    maxHP := 240
		    maxENG := 240

		    hp := maxHP
		    eng := maxENG
		    psize := 10

		    fcost := 2
		    hcost := 2     % ENG cost per 1 HP
		    hamount := 60
		    change := 0.8

		    specTicks := 0.0
		    specAmount := 0.4
		    specLength := 150

		    charge := 0.0
		    chargeSpeed := 1.0
		    exit
		end if
	    end if
	    if (maxx - Font.Width ("STEELHEART", font)) div 2 < mx and mx < (maxx - Font.Width ("STEELHEART", font)) div 2 + Font.Width ("STEELHEART", font) then
		if (maxy - 300) div 2 + 200 < my and my < (maxy - 300) div 2 + 300 then
		    character := "STEELHEART"
		    maxHP := 360
		    maxENG := 360

		    hp := maxHP
		    eng := maxENG
		    psize := 22

		    fcost := 3
		    hcost := 1
		    hamount := 60
		    change := 0.6

		    specTicks := 0.0
		    specAmount := 0
		    specLength := 720

		    charge := 0.0
		    chargeSpeed := 0.35
		    exit
		end if
	    end if
	end if
	delay (5)
    end loop

    onscreen := true
    px := maxx / 2
    py := maxy / 2
    pvx := 0.0
    pvy := 0.0

    hpScale := 360 / maxHP
    engScale := 360 / maxENG

    bn := 3

    ticks := 0
    score := 0
    scoreproxy := 0
    scorestr := ""
    cont := true

    level := 0
    reach := 250

    spawnBul (1, 0)
    spawnBul (2, 1)
    spawnBul (3, 0)

    % Counts down before player begins
    for decreasing x : 5 .. 1
	drawfillbox (0, 0, maxx, maxy, 7)
	Font.Draw (intstr (x), (maxx - Font.Width (intstr (x), font)) div 2, (maxy - 75) div 2, font, 40)
	View.Update ()
	delay (600)
    end for
end setup

procedure pad (s, l : int) % Pads number s to length l with zeroes
    scorestr := ""
    for x : 1 .. (l - length (intstr (s)))
	scorestr := scorestr + "0"
    end for
    scorestr := scorestr + intstr (s)
end pad

procedure getInput
    % Get keyboard input
    Input.KeyDown (chars)
    if (chars (chr (ORD_LOWER_A)) or chars (KEY_LEFT_ARROW)) and eng > fcost then
	pvx -= change
	eng -= fcost
    elsif (chars (chr (ORD_LOWER_D)) or chars (KEY_RIGHT_ARROW)) and eng > fcost then
	pvx += change
	eng -= fcost
    elsif (chars (chr (ORD_LOWER_W)) or chars (KEY_UP_ARROW)) and eng > fcost then
	pvy += change
	eng -= fcost
    elsif (chars (chr (ORD_LOWER_S)) or chars (KEY_DOWN_ARROW)) and eng > fcost then
	pvy -= change
	eng -= fcost
    else
	pvx *= friction
	pvy *= friction
    end if

    if chars (chr (ORD_SPACE)) or chars (chr (ORD_LOWER_E)) then
	% Heal
	if eng > (maxHP - hp) * hcost and last > 10 then
	    % If the player's health deficit is less than the heal amount, don't take off as much energy
	    if maxHP - hp < hamount then
		eng -= (maxHP - hp) * hcost
		hp := maxHP
	    else
		eng -= hamount * hcost
		hp += hamount
	    end if

	    last := 0
	elsif last > 10 then
	    % Heal as much as energy allows for
	    hp += floor(eng / hcost)
	    eng := 0
	    last := 0
	end if
    end if
    if chars (chr (ORD_LOWER_Q)) then
	% If availible, use special
	if 360 <= charge then
	    charge := 0
	    specTicks := specLength
	    if character = "STEELHEART" then
		specAmount := 360
	    end if
	end if
    end if
    Mouse.Where (mx, my, mb)
end getInput

procedure update
    % If dead, check to see if player wants to go again
    if not cont then
	if mb = 1 then
	    if textx2 - 10 < mx and mx < textx2 + 250 then
		if 120 < my and my < 220 then
		    setup
		end if
	    end if
	end if
    end if

    % Update all bullets
    for b : 1 .. bn
	if bul (b, 8) = 0 then
	    % Update velocity
	    bul (b, 2) *= accelerate
	    bul (b, 3) *= accelerate

	    % Angle towards player if not a wild bullet
	    if bul (b, 6) = 0 then
		if bul (b, 0) < px then
		    bul (b, 2) += bul (b, 5)
		elsif bul (b, 0) > px then
		    bul (b, 2) -= bul (b, 5)
		end if
		if bul (b, 1) < py then
		    bul (b, 3) += bul (b, 5)
		elsif bul (b, 1) > py then
		    bul (b, 3) -= bul (b, 5)
		end if
		% Wild bullets move straight
	    elsif bul (b, 6) = 1 then
		bul (b, 2) *= 1.05 % Accelerate for DEADLINESS
		bul (b, 3) *= 1.05
	    elsif bul (b, 6) = 2 then % Go precisely at player
		bul (b, 2) := (px - bul (b, 0)) * 0.007
		bul (b, 3) := (py - bul (b, 1)) * 0.007

		if abs (bul (b, 2)) < 0.2 then
		    bul (b, 2) := 0
		end if

		if abs (bul (b, 3)) < 0.2 then
		    bul (b, 3) := 0
		end if
	    end if
	    % Update position
	    if character = "FLAMEHAWK" and specTicks > 0 then
		bul (b, 0) += bul (b, 2) * specAmount
		bul (b, 1) += bul (b, 3) * specAmount
	    else
		bul (b, 0) += bul (b, 2)
		bul (b, 1) += bul (b, 3)
	    end if

	    % If offscreen, respawn
	    if not (-bul(b,4) < round (bul (b, 0))) or not (round (bul (b, 0)) < maxx + bul(b,4)) then
		if cont then
		    spawnBul (b, round (bul (b, 6)))
		    score += 1
		else
		    bul (b, 8) := 1
		end if

	    elsif not (-bul(b,4) < round (bul (b, 1))) or not (round (bul (b, 1)) < maxy + bul(b,4)) then
		if cont then
		    spawnBul (b, round (bul (b, 6)))
		    score += 1
		else
		    bul (b, 8) := 1
		end if
	    end if

	    % If hit player, deal effect and respawn
	    if sqrt ((px - bul (b, 0)) ** 2 + (py - bul (b, 1)) ** 2) <= psize + bul (b, 4) then
		if cont then
		    if character = "NIGHTFOX" and specTicks > 0 then
			hp -= bul (b, 4) * 1.5
		    elsif character = "STEELHEART" and specTicks > 0 then
			specAmount -= bul (b, 4) * 3
		    else
			hp -= bul (b, 4) * 3
		    end if

		    spawnBul (b, round (bul (b, 6)))
		end if
	    end if
	end if
    end for

    % Update player position
    px := px + pvx
    py := py + pvy

    if not (0 < round (px)) or not (round (px) < maxx) then
	onscreen := false
    elsif not (0 < round (py)) or not (round (py) < maxy) then
	onscreen := false
    else
	onscreen := true
    end if

    if onscreen then
	%hp += 1.0
	if hp > maxHP then
	    hp := maxHP
	end if
    else
	hp -= 2.0
    end if

    if specTicks > 0 then
	if character = "STEELHEART" then
	    if specAmount > 0 then
		specAmount -= 0.5
	    end if
	    if specAmount <= 0 then
		specTicks := 0
	    end if
	elsif character = "NIGHTFOX" then
	    if specAmount > 0 then
		eng += 0.75
		if eng > 360 then
		    eng := 360
		end if
	    end if
	end if
    end if

    if hp < 0.0 then
	cont := false
	hp := 0.0
    end if

    if cont then
	score += 1
	if score > reach then
	    level += 1
	    reach += 600
	    reach := round (reach * 1.2)
	    score += 250
	    % Increase bullet aims
	    for b : 1 .. bn
		bul (b, 5) += 0.05
	    end for
	    % Spawn new follower bullet
	    if level mod 3 = 0 then
		bn += 1
		spawnBul (bn, 0)
	    elsif level mod 4 = 0 then  % Slow tracker bullet
		bn += 1
		spawnBul (bn, 2)
	    end if
	    % Spawn wild bullet anyways
	    bn += 1
	    spawnBul (bn, 1)
	end if
    else
	% Makes score roll up at end of game
	scoreproxy += 15
	if scoreproxy > score then
	    scoreproxy := score
	end if
	pad (scoreproxy, 11)
	if mb = 1 then
	    scoreproxy := score
	end if
    end if

    eng := eng + 1
    if eng > maxENG then
	eng := maxENG
    end if


    if specTicks > 0 then
	specTicks -= 1
    end if

    if charge < 360.0 and specTicks = 0 then
	charge += chargeSpeed
    end if
end update

procedure draw
    % Fill screen
    Draw.FillBox (0, 0, maxx, maxy, 7)

    if cont then
	% Draw wave coutner
	Font.Draw ("WAVE: " + intstr (level + 1), 10, 10, font, 40)
    
	% Draw bars of stats and player ship
	if character = "STEELHEART" and specAmount > 0 then
	    Draw.FillArc (round (px), round (py), psize + 30, psize + 30, 0, round (specAmount), 27)            % Armour left in Steelheart special
	end if
	Draw.FillArc (round (px), round (py), psize + 30, psize + 30, 0, round (charge), 37)                    % Special charge bar
	Draw.FillArc (round (px), round (py), psize + 25, psize + 25, 0, round (eng * engScale), 9)             % Fuel
	Draw.FillArc (round (px), round (py), psize + 15, psize + 15, 0, round (hp * hpScale), 10)              % HP
	Draw.FillOval (round (px), round (py), psize, psize, 0)                                                 % Player's hitbox
	Draw.FillOval (round (px), round (py), round (specTicks / (specLength / psize)), round (specTicks / (specLength / psize)), 37)            % Special time left indication
    else
	Font.Draw ("YOU DEAD.", textx, 350, font, 40)
	Font.Draw (scorestr, textx3, 240, font, 40)
	Font.Draw ("RETRY", textx2, 130, font, 40)
	drawbox (textx2 - 10, 120, textx2 + 250, 220, 40)
	px := maxx * 2
	py := maxy * 2
    end if
    
    % Draw bullets
    for b : 1 .. bn
	Draw.FillOval (round (bul (b, 0)), round (bul (b, 1)), round (bul (b, 4)), round (bul (b, 4)), round (bul (b, 7)))
    end for

    View.Update
end draw

setup
loop
    if not loopcont then
	exit
    end if

    getInput
    update
    draw

    delay (td)
    ticks += 1
    last += 1
end loop

