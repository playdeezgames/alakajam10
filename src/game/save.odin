// Saving. A game in progress is one line of space-separated integers behind a tag, so there is no allocator to
// manage. Every f64 is stored as its bit pattern (exact round trip), every field is read with its legal range,
// and a parse only succeeds if the whole line is consumed; a failed parse leaves the caller's game untouched.
// The writer and the reader list the fields in the same order (a round-trip test pins them together).
package game

import "core:fmt"
import "core:math"
import "core:strconv"
import "core:strings"

SAVE_TAG :: "CSM"
SAVE_VERSION :: 1
SAVE_LIMIT :: 1000.0 // no honest game puts anything farther than this from the origin

put_u64 :: proc(sb: ^strings.Builder, v: u64) {
	fmt.sbprintf(sb, " %d", v)
}

put_f64 :: proc(sb: ^strings.Builder, v: f64) {
	put_u64(sb, transmute(u64)v)
}

// Only a game in progress is saved; the menu has nothing to resume.
serialize_game :: proc(g: Game) -> string {
	sb := strings.builder_make(context.temp_allocator)
	fmt.sbprintf(&sb, "%s %d", SAVE_TAG, SAVE_VERSION)
	put_u64(&sb, g.rng.state)
	put_u64(&sb, u64(g.fuel))
	for e in g.entities {
		put_u64(&sb, u64(e.number))
		put_f64(&sb, e.x)
		put_f64(&sb, e.y)
		put_f64(&sb, e.z)
		put_f64(&sb, e.theta)
		put_f64(&sb, e.phi)
		put_f64(&sb, e.speed)
		put_u64(&sb, 1 if e.surveyed else 0)
		put_f64(&sb, e.fuel_available)
		put_f64(&sb, e.fuel_rate)
		put_f64(&sb, e.fuel_max)
	}
	return strings.to_string(sb)
}

Reader :: struct {
	words: []string,
	at:    int,
	ok:    bool,
}

next_word :: proc(r: ^Reader) -> string {
	if r.at >= len(r.words) {
		r.ok = false
		return ""
	}
	w := r.words[r.at]
	r.at += 1
	return w
}

read_u64 :: proc(r: ^Reader, lo, hi: u64) -> u64 {
	v, parsed := strconv.parse_u64_of_base(next_word(r), 10)
	if !parsed || v < lo || v > hi {
		r.ok = false
		return lo
	}
	return v
}

// A float with a legal range; NaN and infinity are never legal.
read_f64 :: proc(r: ^Reader, lo, hi: f64) -> f64 {
	v := transmute(f64)read_u64(r, 0, max(u64))
	if math.is_nan(v) || math.is_inf(v) || v < lo || v > hi {
		r.ok = false
		return lo
	}
	return v
}

parse_game :: proc(text: string) -> (g: Game, ok: bool) {
	r := Reader {
		words = strings.fields(text, context.temp_allocator),
		ok    = true,
	}
	if next_word(&r) != SAVE_TAG || read_u64(&r, 0, 1 << 20) != SAVE_VERSION {
		return {}, false
	}
	g.rng.state = read_u64(&r, 0, max(u64))
	g.fuel = int(read_u64(&r, 0, MAXIMUM_FUEL))
	seen: [ENTITY_COUNT + 1]bool
	for i in 0 ..< ENTITY_COUNT {
		e: Entity
		e.kind = .Ship if i == 0 else .Star if i < FIRST_WORMHOLE else .Wormhole
		number := int(read_u64(&r, 1, ENTITY_COUNT))
		if seen[number] { 	// the numbers are a permutation of 1..ENTITY_COUNT
			return {}, false
		}
		seen[number] = true
		e.number = number
		e.x = read_f64(&r, -SAVE_LIMIT, SAVE_LIMIT)
		e.y = read_f64(&r, -SAVE_LIMIT, SAVE_LIMIT)
		e.z = read_f64(&r, -SAVE_LIMIT, SAVE_LIMIT)
		e.theta = read_f64(&r, -180, 180)
		e.phi = read_f64(&r, -90, 90)
		e.speed = read_f64(&r, 0, 1)
		e.surveyed = read_u64(&r, 0, 1) == 1
		e.fuel_max = 0
		e.fuel_available = read_f64(&r, 0, STAR_FUEL_MAX)
		e.fuel_rate = read_f64(&r, 0, REFUEL_RATE_MAX)
		e.fuel_max = read_f64(&r, 0, STAR_FUEL_MAX)
		if e.fuel_available > e.fuel_max {
			return {}, false
		}
		if e.kind != .Star && (e.surveyed || e.fuel_max != 0) {
			return {}, false
		}
		g.entities[i] = e
		if !r.ok {
			return {}, false
		}
	}
	if !r.ok || r.at != len(r.words) {
		return {}, false
	}
	g.screen = .Playing
	return g, true
}
