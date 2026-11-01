# Chaotic Space Mappers of SPLORR!!

My entry for Alakajam 10 (September 2020; themes Maps, Chaos and Ships). Survey all 100 stars in a cube of space
50 across, refuel from the stars you have surveyed, and do not trust anything that only looks like a star.

It was an F# console game. In November 2026 it was rebuilt in Odin and WebAssembly so it runs in a browser, with
Claude Code (an AI agent) doing the porting. The rules and numbers are the original's; `QUIRKS.md` lists the few
changes and everything odd that was kept on purpose.

- Play: GitHub Pages is **not live yet** (this repo is private until the user decides).
- Commands: `engage`, `set heading <theta> <phi>`, `set speed <0 to 1>`, `survey <number>`, `refuel <number>`, `help`, `abandon`.
- The original F# source is still in `ChaoticSpaceMappersOfSplorr/` (build with `dotnet`; `publish.sh` is the Windows-era release script).

## Building the web game

```bash
tools/test.sh     # native tests of src/game plus a wasm type-check
tools/build.sh    # build/web (use --size for shipping)
tools/serve.sh    # http://localhost:8080 (wasm needs http, not file://)
tools/pages.sh    # tests, size build, copy to docs/ for GitHub Pages; never commits or pushes
```

`src/game` is the pure rules package (no clock, no page; the random seed is an argument), `src/web` is the thin
browser layer, and `web/index.html` is the console-style page. Needs Odin `dev-2026-07` or newer.
