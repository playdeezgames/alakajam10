#+build js
package main

import "base:runtime"
import "csmos:game"

foreign import host "env"

@(default_calling_convention = "contextless")
foreign host {
	// Appends one line to the transcript. Strings cross as pointer and length.
	out_line :: proc(text: [^]u8, length: i32) ---
	// Queues one square-wave note; the page plays queued notes one after another.
	play_tone :: proc(freq: i32, ms: i32) ---
	// Copies the text box into buf (at most cap bytes) and returns its length.
	read_text :: proc(buf: [^]u8, cap: i32) -> i32 ---
	// Milliseconds since the epoch, as f64 (an i64 import would need a BigInt on the JS side).
	now_ms :: proc() -> f64 ---
	// localStorage. storage_get returns the value's byte length, or -1 when the key is missing, unreadable or
	// longer than cap.
	storage_get :: proc(key: [^]u8, key_len: i32, buf: [^]u8, cap: i32) -> i32 ---
	storage_set :: proc(key: [^]u8, key_len: i32, val: [^]u8, val_len: i32) ---
	storage_remove :: proc(key: [^]u8, key_len: i32) ---
}

// raw_data rejects a constant string, so the key is a variable.
save_key := "csmos-save"

state: game.Game
save_buf: [32768]u8
input_buf: [256]u8

// A game in progress is saved after every event; the menu has nothing to resume.
save :: proc() {
	if state.screen == .Playing {
		text := game.serialize_game(state)
		storage_set(raw_data(save_key), i32(len(save_key)), raw_data(text), i32(len(text)))
	} else {
		storage_remove(raw_data(save_key), i32(len(save_key)))
	}
}

// A save that does not validate is ignored and left alone.
load :: proc() -> bool {
	n := storage_get(raw_data(save_key), i32(len(save_key)), raw_data(save_buf[:]), i32(len(save_buf)))
	if n < 0 {
		return false
	}
	saved, ok := game.parse_game(string(save_buf[:n]))
	if !ok {
		return false
	}
	saved.rng = game.Rng {
		state = saved.rng.state ~ u64(now_ms()),
	}
	state = saved
	return true
}

emit :: proc(r: game.Reply) {
	for line in r.lines {
		out_line(raw_data(line), i32(len(line)))
	}
	for song in r.songs {
		for note in game.song_notes(song) {
			play_tone(note.freq, note.ms)
		}
	}
	free_all(context.temp_allocator)
}

main :: proc() {
	state = game.new_game(u64(now_ms()))
	r := game.new_reply()
	game.banner(&r)
	game.play(&r, .Intro)
	if load() {
		game.blank(&r)
		game.say(&r, "Welcome back! Yer game was saved where you left it.")
	}
	game.show_screen(&state, &r)
	emit(r)
}

// odin.js stops after main unless a step export exists; the page is event driven, so it does nothing.
@(export)
step :: proc(dt: f64, c: runtime.Context) -> bool {
	return true
}

@(export)
on_submit :: proc "c" () {
	context = runtime.default_context()
	n := read_text(raw_data(input_buf[:]), i32(len(input_buf)))
	r := game.new_reply()
	game.submit(&state, string(input_buf[:n]), &r)
	save()
	emit(r)
}
