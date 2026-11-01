#+build !js
package game

import "core:fmt"
import "core:math"
import "core:strings"
import "core:testing"

// A started game with a known seed.
started :: proc(seed: u64 = 1) -> Game {
	g := new_game(seed)
	r := new_reply()
	submit(&g, "start", &r)
	return g
}

run :: proc(g: ^Game, line: string) -> Reply {
	r := new_reply()
	submit(g, line, &r)
	return r
}

said :: proc(r: Reply, text: string) -> bool {
	for l in r.lines {
		if strings.contains(l, text) {
			return true
		}
	}
	return false
}

sang :: proc(r: Reply, s: Song) -> bool {
	for x in r.songs {
		if x == s {
			return true
		}
	}
	return false
}

first_of :: proc(g: Game, k: Kind) -> int {
	for e, i in g.entities {
		if e.kind == k {
			return i
		}
	}
	return -1
}

// Puts the ship right next to entity i, so its number is in reach.
park_at :: proc(g: ^Game, i: int) {
	t := g.entities[i]
	g.entities[0].x, g.entities[0].y, g.entities[0].z = t.x + 0.5, t.y, t.z
}

number_text :: proc(g: Game, i: int) -> string {
	return fmt.tprintf("%d", g.entities[i].number)
}

@(test)
test_world_is_built_as_the_original_built_it :: proc(t: ^testing.T) {
	g := started()
	stars, holes, ships := 0, 0, 0
	for e in g.entities {
		switch e.kind {
		case .Ship:
			ships += 1
		case .Star:
			stars += 1
			testing.expect(t, e.fuel_max >= STAR_FUEL_MIN && e.fuel_max <= STAR_FUEL_MAX)
			testing.expect(t, e.fuel_available >= 0 && e.fuel_available <= e.fuel_max)
			testing.expect(t, e.fuel_rate >= REFUEL_RATE_MIN && e.fuel_rate <= REFUEL_RATE_MAX)
			testing.expect(t, !e.surveyed)
		case .Wormhole:
			holes += 1
		}
		if e.kind != .Ship {
			testing.expect(t, abs(e.x) <= WORLD_WIDTH / 2 && abs(e.y) <= WORLD_HEIGHT / 2 && abs(e.z) <= WORLD_DEPTH / 2)
		}
	}
	testing.expect_value(t, ships, 1)
	testing.expect_value(t, stars, STAR_COUNT)
	testing.expect_value(t, holes, WORMHOLE_COUNT)
	testing.expect_value(t, g.fuel, MAXIMUM_FUEL)
	testing.expect_value(t, g.entities[0].speed, 1.0)
	testing.expect_value(t, g.entities[0].x, 0.0)
	testing.expect_value(t, g.screen, Screen.Playing)
}

@(test)
test_entity_numbers_are_a_permutation_and_hide_the_wormholes :: proc(t: ^testing.T) {
	g := started(7)
	seen: [ENTITY_COUNT + 1]bool
	for e in g.entities {
		testing.expect(t, e.number >= 1 && e.number <= ENTITY_COUNT)
		testing.expect(t, !seen[e.number])
		seen[e.number] = true
	}
	// With ten wormholes in 111 numbers, the wormholes are not the last ten in any of these seeds.
	for seed in 1 ..= u64(20) {
		w := started(seed)
		all_last := true
		for i in FIRST_WORMHOLE ..< ENTITY_COUNT {
			if w.entities[i].number <= ENTITY_COUNT - WORMHOLE_COUNT {
				all_last = false
			}
		}
		testing.expect(t, !all_last)
	}
}

@(test)
test_random_values_are_never_negative_or_out_of_range :: proc(t: ^testing.T) {
	r := Rng {
		state = 42,
	}
	for _ in 0 ..< 20000 {
		v := unit(&r)
		testing.expect(t, v >= 0 && v < 1)
		n := below(&r, 7)
		testing.expect(t, n >= 0 && n < 7)
	}
}

@(test)
test_engage_moves_along_the_heading_and_costs_one_fuel :: proc(t: ^testing.T) {
	g := started()
	run(&g, "set heading 90 0")
	run(&g, "set speed 0.5")
	r := run(&g, "engage")
	testing.expect(t, said(r, "You have moved!"))
	testing.expect_value(t, g.fuel, MAXIMUM_FUEL - 1)
	testing.expect(t, abs(g.entities[0].x) < 1e-9)
	testing.expect(t, abs(g.entities[0].y - 0.5) < 1e-9)
	run(&g, "set heading 0 90")
	run(&g, "set speed 1")
	run(&g, "engage")
	testing.expect(t, abs(g.entities[0].z - 1.0) < 1e-9)
}

@(test)
test_engage_grows_every_star_up_to_its_maximum :: proc(t: ^testing.T) {
	g := started()
	i := first_of(g, .Star)
	g.entities[i].fuel_available = g.entities[i].fuel_max - 0.5
	before_other := g.entities[i + 1].fuel_available
	run(&g, "engage")
	testing.expect_value(t, g.entities[i].fuel_available, g.entities[i].fuel_max)
	testing.expect(t, g.entities[i + 1].fuel_available > before_other || g.entities[i + 1].fuel_available == g.entities[i + 1].fuel_max)
}

@(test)
test_engage_with_no_fuel_ends_the_game :: proc(t: ^testing.T) {
	g := started()
	g.fuel = 1
	r := run(&g, "engage")
	testing.expect_value(t, g.fuel, 0)
	testing.expect_value(t, g.screen, Screen.Playing)
	testing.expect(t, !said(r, "Game over!"))
	r = run(&g, "engage")
	testing.expect(t, said(r, "You are out of fuel!"))
	testing.expect(t, said(r, "Game over!"))
	testing.expect(t, sang(r, .Lose))
	testing.expect_value(t, g.screen, Screen.Main_Menu)
}

@(test)
test_set_speed_and_heading_validate_their_ranges :: proc(t: ^testing.T) {
	g := started()
	testing.expect(t, said(run(&g, "set speed 1.5"), "Invalid speed"))
	testing.expect(t, said(run(&g, "set speed -0.1"), "Invalid speed"))
	testing.expect(t, said(run(&g, "set speed fast"), "Invalid speed"))
	testing.expect(t, said(run(&g, "set speed nan"), "Invalid speed"))
	testing.expect(t, said(run(&g, "set speed 0.25"), "Updated speed!"))
	testing.expect_value(t, g.entities[0].speed, 0.25)
	testing.expect(t, said(run(&g, "set heading 181 0"), "Invalid theta"))
	testing.expect(t, said(run(&g, "set heading -181 0"), "Invalid theta"))
	testing.expect(t, said(run(&g, "set heading 0 91"), "Invalid phi"))
	testing.expect(t, said(run(&g, "set heading 0 -91"), "Invalid phi"))
	testing.expect(t, said(run(&g, "set heading -93.54 -18.47"), "Updated heading!"))
	testing.expect_value(t, g.entities[0].theta, -93.54)
	testing.expect_value(t, g.entities[0].phi, -18.47)
	// A bad phi leaves the heading as it was.
	run(&g, "set heading 10 100")
	testing.expect_value(t, g.entities[0].theta, -93.54)
}

@(test)
test_survey_marks_a_star_and_counts_it :: proc(t: ^testing.T) {
	g := started()
	i := first_of(g, .Star)
	park_at(&g, i)
	r := run(&g, strings.concatenate({"survey ", number_text(g, i)}, context.temp_allocator))
	testing.expect(t, said(r, "Star surveyed!"))
	testing.expect(t, sang(r, .Survey_Star))
	testing.expect(t, g.entities[i].surveyed)
	testing.expect_value(t, surveyed_count(g), 1)
	testing.expect(t, said(r, "Surveyed Entities: 1/100"))
	// Surveying again does not count twice.
	run(&g, strings.concatenate({"survey ", number_text(g, i)}, context.temp_allocator))
	testing.expect_value(t, surveyed_count(g), 1)
}

@(test)
test_survey_too_far_or_unknown_is_refused :: proc(t: ^testing.T) {
	g := started()
	i := first_of(g, .Star)
	g.entities[0].x, g.entities[0].y, g.entities[0].z = g.entities[i].x + 1.5, g.entities[i].y, g.entities[i].z
	r := run(&g, strings.concatenate({"survey ", number_text(g, i)}, context.temp_allocator))
	testing.expect(t, said(r, "Invalid entity number or not near enough to entity!"))
	testing.expect(t, sang(r, .Error))
	testing.expect(t, !g.entities[i].surveyed)
	testing.expect(t, said(run(&g, "survey 0"), "Invalid entity number"))
	testing.expect(t, said(run(&g, "survey 9999"), "Invalid entity number"))
	testing.expect(t, said(run(&g, "survey abc"), "Invalid entity number"))
	testing.expect(t, said(run(&g, "survey 99999999999"), "Invalid entity number"))
}

@(test)
test_survey_a_wormhole_teleports_and_stays_unsurveyed :: proc(t: ^testing.T) {
	g := started(3)
	w := first_of(g, .Wormhole)
	park_at(&g, w)
	from := g.entities[0]
	r := run(&g, strings.concatenate({"survey ", number_text(g, w)}, context.temp_allocator))
	testing.expect(t, said(r, "It was not a star, but a wormhole!"))
	testing.expect(t, said(r, "What's on the other end?"))
	testing.expect(t, sang(r, .Wormhole))
	to := g.entities[0]
	testing.expect(t, abs(to.x) <= WORLD_WIDTH / 2 && abs(to.y) <= WORLD_HEIGHT / 2 && abs(to.z) <= WORLD_DEPTH / 2)
	testing.expect(t, from.x != to.x || from.y != to.y || from.z != to.z)
	testing.expect_value(t, surveyed_count(g), 0)
}

@(test)
test_surveying_the_ship_itself_is_not_a_star :: proc(t: ^testing.T) {
	g := started()
	r := run(&g, strings.concatenate({"survey ", number_text(g, 0)}, context.temp_allocator))
	testing.expect(t, said(r, "Not a star!"))
}

@(test)
test_refuel_needs_a_surveyed_star_and_empties_it :: proc(t: ^testing.T) {
	g := started()
	i := first_of(g, .Star)
	park_at(&g, i)
	g.fuel = 50
	g.entities[i].fuel_available = 30.9
	n := number_text(g, i)
	r := run(&g, strings.concatenate({"refuel ", n}, context.temp_allocator))
	testing.expect(t, said(r, "Invalid entity number"), "an unsurveyed star cannot refuel")
	testing.expect_value(t, g.fuel, 50)
	run(&g, strings.concatenate({"survey ", n}, context.temp_allocator))
	r = run(&g, strings.concatenate({"refuel ", n}, context.temp_allocator))
	testing.expect(t, said(r, "You refueled yer ship!"))
	testing.expect(t, sang(r, .Refuel))
	testing.expect_value(t, g.fuel, 80) // 30.9 is taken as 30
	testing.expect_value(t, g.entities[i].fuel_available, 0.0)
}

@(test)
test_refuel_never_goes_over_the_tank :: proc(t: ^testing.T) {
	g := started()
	i := first_of(g, .Star)
	park_at(&g, i)
	g.entities[i].surveyed = true
	g.entities[i].fuel_available = 40
	g.fuel = 90
	run(&g, strings.concatenate({"refuel ", number_text(g, i)}, context.temp_allocator))
	testing.expect_value(t, g.fuel, MAXIMUM_FUEL)
}

@(test)
test_refuel_a_wormhole_is_refused :: proc(t: ^testing.T) {
	g := started()
	w := first_of(g, .Wormhole)
	park_at(&g, w)
	testing.expect(t, said(run(&g, strings.concatenate({"refuel ", number_text(g, w)}, context.temp_allocator)), "Invalid entity number"))
}

@(test)
test_status_lists_viewable_and_interactable_entities :: proc(t: ^testing.T) {
	g := started()
	for i in 1 ..< ENTITY_COUNT { 	// clear the sky, then place three things
		g.entities[i].x, g.entities[i].y, g.entities[i].z = 40, 40, 40
	}
	s := first_of(g, .Star)
	w := first_of(g, .Wormhole)
	g.entities[s].x, g.entities[s].y, g.entities[s].z = 0.5, 0, 0
	g.entities[s].surveyed = true
	g.entities[s].fuel_available, g.entities[s].fuel_max = 12.4, 30
	g.entities[w].x, g.entities[w].y, g.entities[w].z = 0, 6, 0
	r := new_reply()
	show_status(&r, g)
	testing.expect(t, said(r, "Type: surveyed star Distance: 0.50 Bearing: 0.00 x 0.00 (Entity#: "))
	testing.expect(t, said(r, "(Fuel Available: 12/30)"))
	testing.expect(t, said(r, "Type: unknown Distance: 6.00 Bearing: 90.00 x 0.00"))
	// The interactable star is also viewable, and the nearest comes first.
	viewable := false
	order := make([dynamic]string, context.temp_allocator)
	for l in r.lines {
		if l == "Viewable Entities:" {
			viewable = true
		} else if viewable {
			append(&order, l)
		}
	}
	testing.expect_value(t, len(order), 2)
	testing.expect(t, strings.contains(order[0], "Distance: 0.50"))
	testing.expect(t, strings.contains(order[1], "Distance: 6.00"))
}

@(test)
test_status_with_nothing_near_says_nothing :: proc(t: ^testing.T) {
	g := started()
	for i in 1 ..< ENTITY_COUNT {
		g.entities[i].x, g.entities[i].y, g.entities[i].z = 40, 40, 40
	}
	r := new_reply()
	show_status(&r, g)
	count := 0
	for l in r.lines {
		if l == "(nothing)" {
			count += 1
		}
	}
	testing.expect_value(t, count, 2)
}

@(test)
test_bearing_matches_the_original_formula :: proc(t: ^testing.T) {
	a := Entity{}
	b := Entity {
		x = -1,
		y = -1,
		z = 0,
	}
	theta, phi := bearing_between(a, b)
	testing.expect(t, abs(theta - -135) < 1e-9)
	testing.expect(t, abs(phi) < 1e-9)
	c := Entity {
		x = 0,
		y = 0,
		z = 5,
	}
	_, phi = bearing_between(a, c)
	testing.expect(t, abs(phi - 90) < 1e-9)
}

@(test)
test_surveying_every_star_wins_and_returns_to_the_menu :: proc(t: ^testing.T) {
	g := started(11)
	r: Reply
	for i in FIRST_STAR ..< FIRST_WORMHOLE {
		park_at(&g, i)
		r = run(&g, strings.concatenate({"survey ", number_text(g, i)}, context.temp_allocator))
	}
	testing.expect(t, said(r, "Surveyed Entities: 100/100"))
	testing.expect(t, said(r, "You won the game!"))
	testing.expect(t, sang(r, .Win))
	testing.expect(t, !sang(r, .Lose), "winning is not losing")
	testing.expect(t, !said(r, "Game over!"))
	testing.expect_value(t, g.screen, Screen.Main_Menu)
	testing.expect(t, said(r, "Main Menu:"))
}

@(test)
test_main_menu_commands :: proc(t: ^testing.T) {
	g := new_game(5)
	r := run(&g, "help")
	testing.expect(t, said(r, "How to play:"))
	testing.expect_value(t, g.screen, Screen.Main_Menu)
	r = run(&g, "dance")
	testing.expect(t, said(r, "Please type 'start', 'help' or 'quit'."))
	testing.expect(t, sang(r, .Error))
	r = run(&g, "quit")
	testing.expect(t, said(r, "Thank you for playing!"))
	testing.expect(t, sang(r, .Outro))
	r = run(&g, "  START  ")
	testing.expect(t, sang(r, .Start))
	testing.expect_value(t, g.screen, Screen.Playing)
}

@(test)
test_play_commands_ignore_case_and_extra_spaces :: proc(t: ^testing.T) {
	g := started()
	testing.expect(t, said(run(&g, "SET   Speed   0.5 "), "Updated speed!"))
	testing.expect(t, said(run(&g, "Engage"), "You have moved!"))
	r := run(&g, "xyzzy")
	testing.expect(t, said(r, "Maybe try 'help'?"))
	testing.expect(t, sang(r, .Error))
	testing.expect(t, said(run(&g, ""), "Maybe try 'help'?"))
	testing.expect(t, said(run(&g, "help"), "In Game Help:"))
}

@(test)
test_abandon_returns_to_the_menu :: proc(t: ^testing.T) {
	g := started()
	r := run(&g, "abandon")
	testing.expect(t, said(r, "Game over!"))
	testing.expect_value(t, g.screen, Screen.Main_Menu)
	// A fresh start is a new world.
	run(&g, "start")
	testing.expect_value(t, g.fuel, MAXIMUM_FUEL)
	testing.expect_value(t, surveyed_count(g), 0)
}

@(test)
test_save_round_trips_exactly :: proc(t: ^testing.T) {
	g := started(99)
	run(&g, "set heading -93.54 -18.47")
	for _ in 0 ..< 5 {
		run(&g, "engage")
	}
	i := first_of(g, .Star)
	g.entities[i].surveyed = true
	text := serialize_game(g)
	back, ok := parse_game(text)
	testing.expect(t, ok)
	testing.expect(t, back == g)
	testing.expect_value(t, serialize_game(back), text)
}

@(test)
test_save_rejects_bad_text :: proc(t: ^testing.T) {
	g := started(99)
	good := serialize_game(g)
	_, ok := parse_game("")
	testing.expect(t, !ok)
	_, ok = parse_game("CSM 2 1 1")
	testing.expect(t, !ok)
	_, ok = parse_game(strings.concatenate({good, " 7"}, context.temp_allocator))
	testing.expect(t, !ok, "trailing data")
	_, ok = parse_game(good[:len(good) - 5])
	testing.expect(t, !ok, "truncated")
	// Fuel over the tank.
	words := strings.fields(good, context.temp_allocator)
	words[3] = "101"
	_, ok = parse_game(strings.join(words, " ", context.temp_allocator))
	testing.expect(t, !ok)
	// NaN in a position.
	words = strings.fields(good, context.temp_allocator)
	words[5] = "18444492273895866368" // a NaN bit pattern
	_, ok = parse_game(strings.join(words, " ", context.temp_allocator))
	testing.expect(t, !ok)
	// Two entities with the same number.
	words = strings.fields(good, context.temp_allocator)
	words[4 + 11] = words[4]
	_, ok = parse_game(strings.join(words, " ", context.temp_allocator))
	testing.expect(t, !ok)
}

@(test)
test_a_bot_plays_a_thousand_turns_without_breaking_anything :: proc(t: ^testing.T) {
	g := started(2024)
	lines := [?]string{"engage", "set heading 45 10", "set heading -120 -30", "set speed 0.7", "survey 5", "refuel 9", "engage", "help", "set speed 1", "engage"}
	for i in 0 ..< 1000 {
		r := run(&g, lines[i % len(lines)])
		testing.expect(t, len(r.lines) > 0)
		if g.screen == .Main_Menu {
			run(&g, "start")
		}
		testing.expect(t, g.fuel >= 0 && g.fuel <= MAXIMUM_FUEL)
		for e in g.entities {
			testing.expect(t, !math.is_nan(e.x) && !math.is_nan(e.y) && !math.is_nan(e.z))
		}
		free_all(context.temp_allocator)
	}
}
