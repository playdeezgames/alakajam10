# CLAUDE.md

Chaotic Space Mappers of SPLORR!! (Alakajam 10, 2020). The F# original is in `ChaoticSpaceMappersOfSplorr/`; the Odin/wasm port is `src/game` (pure rules), `src/web` and `web/index.html`. Context lives in the vault: `bok-of-splorr/splorr/Games/Chaotic Space Mappers of SPLORR!!.md`.

- Never `git push` unless the user says so. "Push" is `git push`; "ship" is itch.io, and this game is **Pages only: never ship it to itch.io** (the user plans to retire the itch page `alakajam-10`, only on an explicit yes naming it).
- GitHub Pages: live at https://playdeezgames.github.io/alakajam10/ (branch `master`, folder `/docs`; the repo was made public November 1, 2026 at the user's word).
- Read `QUIRKS.md` before "fixing" anything odd, and add new oddities there.
- Tests: `tools/test.sh`. `int` is 32 bits on `js_wasm32`: do random-number modulo in `u64` first.
