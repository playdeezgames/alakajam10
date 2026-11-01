// Chaotic Space Mappers of SPLORR!!: the rules, as one plain struct. The original was an F# console game
// (Alakajam 10, September 2020). Nothing here reads a clock or the page; the random seed is an argument, so
// tests can force any world.
package game

import "core:fmt"
import "core:math"
import "core:slice"
import "core:strconv"
import "core:strings"

STAR_COUNT :: 100
WORMHOLE_COUNT :: 10
ENTITY_COUNT :: 1 + STAR_COUNT + WORMHOLE_COUNT
FIRST_STAR :: 1
FIRST_WORMHOLE :: 1 + STAR_COUNT

INTERACT_DISTANCE :: 1.0
VIEW_DISTANCE :: 10.0
WORLD_WIDTH :: 50.0
WORLD_HEIGHT :: 50.0
WORLD_DEPTH :: 50.0
MAXIMUM_FUEL :: 100
REFUEL_RATE_MIN :: 1.0
REFUEL_RATE_MAX :: 5.0
STAR_FUEL_MIN :: 10.0
STAR_FUEL_MAX :: 50.0

Kind :: enum u8 {
	Ship,
	Star,
	Wormhole,
}

// One thing in space. Stars use the last four fields; the ship and wormholes leave them zero.
Entity :: struct {
	kind:           Kind,
	number:         int, // what the player types; scrambled so wormholes cannot be told by their number
	x, y, z:        f64,
	theta, phi:     f64, // degrees
	speed:          f64,
	surveyed:       bool,
	fuel_available: f64,
	fuel_rate:      f64,
	fuel_max:       f64,
}

Screen :: enum u8 {
	Main_Menu,
	Playing,
}

Game :: struct {
	screen:   Screen,
	rng:      Rng,
	entities: [ENTITY_COUNT]Entity, // 0 is the ship, then the stars, then the wormholes
	fuel:     int,
}

Song :: enum u8 {
	Intro,
	Start,
	Lose,
	Survey_Star,
	Wormhole,
	Refuel,
	Win,
	Outro,
	Error,
}

// What a submitted line produced: text for the transcript and songs to play, in order.
Reply :: struct {
	lines: [dynamic]string,
	songs: [dynamic]Song,
}

// ---- randomness (splitmix64; all modulo work is done in u64 before narrowing, see Gotchas on js_wasm32)

Rng :: struct {
	state: u64,
}

next_u64 :: proc(r: ^Rng) -> u64 {
	r.state += 0x9E3779B97F4A7C15
	z := r.state
	z = (z ~ (z >> 30)) * 0xBF58476D1CE4E5B9
	z = (z ~ (z >> 27)) * 0x94D049BB133111EB
	return z ~ (z >> 31)
}

// Uniform in [0, 1).
unit :: proc(r: ^Rng) -> f64 {
	return f64(next_u64(r) >> 11) * (1.0 / 9007199254740992.0)
}

range_f :: proc(r: ^Rng, lo, hi: f64) -> f64 {
	return unit(r) * (hi - lo) + lo
}

// Uniform in [0, n).
below :: proc(r: ^Rng, n: int) -> int {
	return int(next_u64(r) % u64(n))
}

// ---- construction

new_game :: proc(seed: u64) -> Game {
	return Game{screen = .Main_Menu, rng = Rng{state = seed}}
}

random_position :: proc(g: ^Game, e: ^Entity) {
	e.x = range_f(&g.rng, -WORLD_WIDTH / 2, WORLD_WIDTH / 2)
	e.y = range_f(&g.rng, -WORLD_HEIGHT / 2, WORLD_HEIGHT / 2)
	e.z = range_f(&g.rng, -WORLD_DEPTH / 2, WORLD_DEPTH / 2)
}

create_world :: proc(g: ^Game) {
	g.entities = {}
	g.fuel = MAXIMUM_FUEL
	g.entities[0] = Entity {
		kind  = .Ship,
		speed = 1.0,
	}
	for i in FIRST_STAR ..< FIRST_WORMHOLE {
		e := Entity {
			kind     = .Star,
			fuel_max = range_f(&g.rng, STAR_FUEL_MIN, STAR_FUEL_MAX),
		}
		e.fuel_available = range_f(&g.rng, 0, e.fuel_max)
		e.fuel_rate = range_f(&g.rng, REFUEL_RATE_MIN, REFUEL_RATE_MAX)
		random_position(g, &e)
		g.entities[i] = e
	}
	for i in FIRST_WORMHOLE ..< ENTITY_COUNT {
		e := Entity {
			kind = .Wormhole,
		}
		random_position(g, &e)
		g.entities[i] = e
	}
	// Entity numbers 1..ENTITY_COUNT, dealt out in a random order (Fisher-Yates).
	numbers: [ENTITY_COUNT]int
	for i in 0 ..< ENTITY_COUNT {
		numbers[i] = i + 1
	}
	for i := ENTITY_COUNT - 1; i > 0; i -= 1 {
		j := below(&g.rng, i + 1)
		numbers[i], numbers[j] = numbers[j], numbers[i]
	}
	for i in 0 ..< ENTITY_COUNT {
		g.entities[i].number = numbers[i]
	}
}

// ---- geometry

to_radians :: proc(degrees: f64) -> f64 {
	return degrees / 180.0 * math.PI
}

to_degrees :: proc(radians: f64) -> f64 {
	return radians * 180.0 / math.PI
}

distance_between :: proc(a, b: Entity) -> f64 {
	dx, dy, dz := a.x - b.x, a.y - b.y, a.z - b.z
	return math.sqrt(dx * dx + dy * dy + dz * dz)
}

// Heading from `from` to `to`: theta around the z axis, phi up from the xy plane, both in degrees.
bearing_between :: proc(from, to: Entity) -> (theta, phi: f64) {
	dx, dy, dz := to.x - from.x, to.y - from.y, to.z - from.z
	xy := math.sqrt(dx * dx + dy * dy)
	return to_degrees(math.atan2(dy, dx)), to_degrees(math.atan2(dz, xy))
}

surveyed_count :: proc(g: Game) -> int {
	n := 0
	for i in FIRST_STAR ..< FIRST_WORMHOLE {
		if g.entities[i].surveyed {
			n += 1
		}
	}
	return n
}

type_name :: proc(e: Entity) -> string {
	switch e.kind {
	case .Ship:
		return "ship"
	case .Star:
		return "surveyed star" if e.surveyed else "unknown"
	case .Wormhole:
		return "unknown"
	}
	return "unknown"
}

// ---- reply helpers (strings live on the temp allocator; the caller frees it after each draw)

say :: proc(r: ^Reply, format: string, args: ..any) {
	append(&r.lines, fmt.aprintf(format, ..args, allocator = context.temp_allocator))
}

blank :: proc(r: ^Reply) {
	append(&r.lines, "")
}

play :: proc(r: ^Reply, s: Song) {
	append(&r.songs, s)
}

new_reply :: proc() -> Reply {
	return Reply {
		lines = make([dynamic]string, context.temp_allocator),
		songs = make([dynamic]Song, context.temp_allocator),
	}
}

// ---- screens

banner :: proc(r: ^Reply) {
	say(r, "Welcome to the Chaotic Space Mappers of SPLORR!!")
	say(r, "A production of TheGrumpyGameDev")
	say(r, "For Alakajam 10")
}

show_menu :: proc(r: ^Reply) {
	blank(r)
	say(r, "Main Menu:")
	say(r, "start - start the game")
	say(r, "help - how to play")
	say(r, "quit - quit the game")
}

show_help :: proc(r: ^Reply) {
	blank(r)
	say(r, "In Game Help:")
	say(r, "abandon - abandon the game and return to the main menu")
	say(r, "help - show help (you are here!)")
	say(r, "engage - moves yer ship")
	say(r, "refuel <number> - attempts to refuel from a given entity <number>")
	say(r, "set heading <theta> <phi> - sets the heading of yer ship")
	say(r, "\t<theta> is between -180 and 180")
	say(r, "\t<phi> is between -90 and 90")
	say(r, "set speed <speed> - sets the speed of yer ship (<speed> is between 0.0 and 1.0)")
	say(r, "survey <number> - attempts to survey a given entity <number>")
}

show_how_to_play :: proc(r: ^Reply) {
	blank(r)
	say(r, "How to play:")
	say(r, "Survey all %d stars to win. Yer ship sits at (0, 0, 0) in a cube of space 50 across.", STAR_COUNT)
	say(r, "Set a heading and a speed, then 'engage' to move one step along it. Every step costs 1 fuel.")
	say(r, "Anything within 1.0 of the ship is interactable and has an entity number.")
	say(r, "'survey <number>' charts a star. A surveyed star shows its fuel, and 'refuel <number>' tops yer ship up from it.")
	say(r, "Stars make more fuel as time passes (every engage). Not everything that looks like a star is one.")
	say(r, "Engage with no fuel left and the game is over. Type 'help' in the game for the commands.")
}

show_status :: proc(r: ^Reply, g: Game) {
	ship := g.entities[0]
	blank(r)
	say(r, "Ship Status:")
	say(r, "Position: (%.6f, %.6f, %.6f)", ship.x, ship.y, ship.z)
	say(r, "Heading: (%.6f, %.6f)", ship.theta, ship.phi)
	say(r, "Speed: (%.6f)", ship.speed)
	say(r, "Surveyed Entities: %d/%d", surveyed_count(g), STAR_COUNT)
	say(r, "Fuel: %d/%d", g.fuel, MAXIMUM_FUEL)

	Seen :: struct {
		index:    int,
		distance: f64,
	}
	near := make([dynamic]Seen, context.temp_allocator)
	for i in 1 ..< ENTITY_COUNT {
		d := distance_between(ship, g.entities[i])
		if d <= VIEW_DISTANCE {
			append(&near, Seen{i, d})
		}
	}
	slice.stable_sort_by(near[:], proc(a, b: Seen) -> bool {return a.distance < b.distance})

	say(r, "Interactable Entities:")
	any_close := false
	for s in near {
		if s.distance > INTERACT_DISTANCE {
			continue
		}
		any_close = true
		e := g.entities[s.index]
		theta, phi := bearing_between(ship, e)
		suffix := ""
		if e.kind == .Star && e.surveyed {
			suffix = fmt.aprintf(" (Fuel Available: %.0f/%.0f)", e.fuel_available, e.fuel_max, allocator = context.temp_allocator)
		}
		say(r, "Type: %s Distance: %.2f Bearing: %.2f x %.2f (Entity#: %d)%s", type_name(e), s.distance, theta, phi, e.number, suffix)
	}
	if !any_close {
		say(r, "(nothing)")
	}
	say(r, "Viewable Entities:")
	if len(near) == 0 {
		say(r, "(nothing)")
	}
	for s in near {
		e := g.entities[s.index]
		theta, phi := bearing_between(ship, e)
		say(r, "Type: %s Distance: %.2f Bearing: %.2f x %.2f", type_name(e), s.distance, theta, phi)
	}
}

// Prints whatever the player should see next: the menu, or the ship's status (and the win, when it is earned).
show_screen :: proc(g: ^Game, r: ^Reply) {
	switch g.screen {
	case .Main_Menu:
		show_menu(r)
	case .Playing:
		show_status(r, g^)
		if surveyed_count(g^) == STAR_COUNT {
			play(r, .Win)
			blank(r)
			say(r, "You won the game!")
			end_game(g)
			show_menu(r)
		}
	}
}

end_game :: proc(g: ^Game) {
	g.screen = .Main_Menu
	g.entities = {}
	g.fuel = 0
}

game_over :: proc(g: ^Game, r: ^Reply) {
	play(r, .Lose)
	blank(r)
	say(r, "Game over!")
	end_game(g)
}

// ---- input

// The F# game split on single spaces and lowercased; this splits on any whitespace, so extra spaces are harmless.
tokens :: proc(line: string) -> []string {
	parts := strings.fields(line, context.temp_allocator)
	for &p in parts {
		p = strings.to_lower(p, context.temp_allocator)
	}
	return parts
}

// Int32.TryParse: an optional sign and digits only, and it must fit 32 bits.
parse_int32 :: proc(s: string) -> (value: int, ok: bool) {
	body := s
	if len(body) > 0 && (body[0] == '+' || body[0] == '-') {
		body = body[1:]
	}
	if len(body) == 0 || len(body) > 10 {
		return 0, false
	}
	for c in body {
		if c < '0' || c > '9' {
			return 0, false
		}
	}
	v, parsed := strconv.parse_i64_of_base(s, 10)
	if !parsed || v < -2147483648 || v > 2147483647 {
		return 0, false
	}
	return int(v), true
}

// Double.TryParse for ordinary numbers: digits, sign, point and exponent only (so "nan" and "inf" are refused,
// which the range checks would have refused anyway).
parse_number :: proc(s: string) -> (value: f64, ok: bool) {
	if len(s) == 0 {
		return 0, false
	}
	for c in s {
		switch c {
		case '0' ..= '9', '+', '-', '.', 'e':
		case:
			return 0, false
		}
	}
	v, parsed := strconv.parse_f64(s)
	if !parsed || math.is_nan(v) || math.is_inf(v) {
		return 0, false
	}
	return v, true
}

find_by_number :: proc(g: Game, number: int) -> (index: int, ok: bool) {
	for i in 0 ..< ENTITY_COUNT {
		if g.entities[i].number == number {
			return i, true
		}
	}
	return 0, false
}

invalid_target :: proc(r: ^Reply) {
	play(r, .Error)
	blank(r)
	say(r, "Invalid entity number or not near enough to entity!")
}

// The entity a survey or refuel names: it must exist and be within reach. Says why not, and returns false.
reachable :: proc(g: Game, r: ^Reply, text: string) -> (index: int, ok: bool) {
	number, parsed := parse_int32(text)
	if !parsed {
		invalid_target(r)
		return 0, false
	}
	i, found := find_by_number(g, number)
	if !found || distance_between(g.entities[0], g.entities[i]) > INTERACT_DISTANCE {
		invalid_target(r)
		return 0, false
	}
	return i, true
}

do_survey :: proc(g: ^Game, r: ^Reply, text: string) {
	i, ok := reachable(g^, r, text)
	if !ok {
		return
	}
	switch g.entities[i].kind {
	case .Star:
		play(r, .Survey_Star)
		blank(r)
		say(r, "Star surveyed!")
		g.entities[i].surveyed = true
	case .Wormhole:
		play(r, .Wormhole)
		blank(r)
		say(r, "It was not a star, but a wormhole!")
		say(r, "What's on the other end?")
		ship := &g.entities[0]
		random_position(g, ship)
	case .Ship:
		blank(r)
		say(r, "Not a star!")
	}
}

do_refuel :: proc(g: ^Game, r: ^Reply, text: string) {
	i, ok := reachable(g^, r, text)
	if !ok {
		return
	}
	star := &g.entities[i]
	if star.kind != .Star || !star.surveyed {
		invalid_target(r)
		return
	}
	play(r, .Refuel)
	blank(r)
	say(r, "You refueled yer ship!")
	g.fuel = min(g.fuel + int(star.fuel_available), MAXIMUM_FUEL)
	star.fuel_available = 0
}

do_engage :: proc(g: ^Game, r: ^Reply) {
	if g.fuel <= 0 {
		blank(r)
		say(r, "You are out of fuel!")
		game_over(g, r)
		return
	}
	blank(r)
	say(r, "You have moved!")
	g.fuel -= 1
	ship := &g.entities[0]
	t, p := to_radians(ship.theta), to_radians(ship.phi)
	ship.x += ship.speed * math.cos(t) * math.cos(p)
	ship.y += ship.speed * math.sin(t) * math.cos(p)
	ship.z += ship.speed * math.sin(p)
	for i in FIRST_STAR ..< FIRST_WORMHOLE {
		s := &g.entities[i]
		s.fuel_available = min(s.fuel_available + s.fuel_rate, s.fuel_max)
	}
}

do_set_speed :: proc(g: ^Game, r: ^Reply, text: string) {
	speed, ok := parse_number(text)
	if !ok || speed < 0.0 || speed > 1.0 {
		play(r, .Error)
		blank(r)
		say(r, "Invalid speed - must be numeric and between 0.0 and 1.0!")
		return
	}
	g.entities[0].speed = speed
	blank(r)
	say(r, "Updated speed!")
}

do_set_heading :: proc(g: ^Game, r: ^Reply, theta_text, phi_text: string) {
	theta, theta_ok := parse_number(theta_text)
	if !theta_ok || theta < -180.0 || theta > 180.0 {
		play(r, .Error)
		blank(r)
		say(r, "Invalid theta - must be numeric and between -180.0 and 180.0!")
		return
	}
	phi, phi_ok := parse_number(phi_text)
	if !phi_ok || phi < -90.0 || phi > 90.0 {
		play(r, .Error)
		blank(r)
		say(r, "Invalid phi - must be numeric and between -90.0 and 90.0!")
		return
	}
	g.entities[0].theta = theta
	g.entities[0].phi = phi
	blank(r)
	say(r, "Updated heading!")
}

// One line typed by the player: echo it, run it, then show what comes next.
submit :: proc(g: ^Game, line: string, r: ^Reply) {
	blank(r)
	say(r, ">%s", line)
	t := tokens(line)
	switch g.screen {
	case .Main_Menu:
		if len(t) == 1 && t[0] == "start" {
			play(r, .Start)
			create_world(g)
			g.screen = .Playing
		} else if len(t) == 1 && t[0] == "help" {
			show_how_to_play(r)
		} else if len(t) == 1 && t[0] == "quit" {
			play(r, .Outro)
			blank(r)
			say(r, "Thank you for playing!")
		} else {
			play(r, .Error)
			blank(r)
			say(r, "Please type 'start', 'help' or 'quit'. There aren't any other options here!")
		}
	case .Playing:
		switch {
		case len(t) == 2 && t[0] == "refuel":
			do_refuel(g, r, t[1])
		case len(t) == 2 && t[0] == "survey":
			do_survey(g, r, t[1])
		case len(t) == 1 && t[0] == "engage":
			do_engage(g, r)
		case len(t) == 3 && t[0] == "set" && t[1] == "speed":
			do_set_speed(g, r, t[2])
		case len(t) == 4 && t[0] == "set" && t[1] == "heading":
			do_set_heading(g, r, t[2], t[3])
		case len(t) == 1 && t[0] == "abandon":
			game_over(g, r)
		case len(t) == 1 && t[0] == "help":
			show_help(r)
		case:
			play(r, .Error)
			blank(r)
			say(r, "Maybe try 'help'?")
		}
	}
	show_screen(g, r)
}

// ---- the little songs (frequency in Hz, duration in ms), as the original played them through Console.Beep

Note :: struct {
	freq, ms: i32,
}

intro_notes := [?]Note{{261, 100}, {293, 100}, {329, 100}, {349, 100}, {392, 100}, {440, 100}, {494, 100}, {523, 100}}
start_notes := [?]Note{{261, 200}, {329, 200}, {392, 200}, {523, 400}, {392, 200}, {523, 400}}
lose_notes := [?]Note{{349, 200}, {261, 200}, {293, 200}, {261, 400}, {329, 200}, {349, 600}}
survey_notes := [?]Note{{494, 200}, {440, 200}, {392, 200}, {440, 200}, {494, 200}, {494, 200}, {494, 400}}
wormhole_notes := [?]Note {
	{261, 100},
	{392, 100},
	{293, 100},
	{494, 100},
	{329, 100},
	{349, 100},
	{329, 100},
	{329, 100},
	{392, 100},
	{440, 100},
	{329, 100},
	{494, 100},
	{349, 100},
	{523, 100},
}
refuel_notes := [?]Note{{261, 100}, {329, 100}, {392, 100}, {523, 100}, {261, 100}, {329, 100}, {392, 100}, {523, 100}}
win_notes := [?]Note{{261, 200}, {261, 200}, {261, 200}, {392, 800}, {392, 200}, {392, 200}, {440, 400}, {392, 200}, {349, 200}, {392, 400}, {261, 800}}
outro_notes := [?]Note{{523, 100}, {494, 100}, {440, 100}, {392, 100}, {349, 100}, {329, 100}, {293, 100}, {261, 100}}
error_notes := [?]Note{{130, 250}}

song_notes :: proc(s: Song) -> []Note {
	switch s {
	case .Intro:
		return intro_notes[:]
	case .Start:
		return start_notes[:]
	case .Lose:
		return lose_notes[:]
	case .Survey_Star:
		return survey_notes[:]
	case .Wormhole:
		return wormhole_notes[:]
	case .Refuel:
		return refuel_notes[:]
	case .Win:
		return win_notes[:]
	case .Outro:
		return outro_notes[:]
	case .Error:
		return error_notes[:]
	}
	return nil
}
