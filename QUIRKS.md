# Quirks of the original, and what the Odin port did about them

The F# game (Alakajam 10, September 2020, themes Maps, Chaos and Ships) is still in `ChaoticSpaceMappersOfSplorr/`
and in git history. The port keeps its rules and numbers. Where the original did something odd, it is listed here.
The user chose "fix as I go" for this port, so the **fixed** items were fixed while porting; the **kept** items are
for the user to decide.

## Fixed in the port

| Original behaviour | Port |
| --- | --- |
| The main menu listed `help - how to play`, but typing `help` was refused as invalid input. | `help` shows a short how-to-play text (new text, written for the port). |
| Winning (all 100 stars surveyed) printed "You won the game!" and then also "Game over!" and played the lose song. | Winning plays the win song, says "You won the game!" and returns to the menu. |
| Input was split on single spaces, so a double space or a trailing space made a good command invalid. | Input is split on any whitespace; commands are still case-insensitive. |
| `quit` ended the program. | A browser tab cannot quit: it plays the outro, says "Thank you for playing!" and stays at the menu. |
| Console output scrolled away in the window. | The page keeps a scrolling transcript (the last 800 lines) and has a command row for phones. |
| Nothing was saved. | A game in progress is saved in `localStorage` after every command and resumed on the next visit. Abandoning, winning and losing clear it. |
| Positions and headings printed with six decimals (`%f` in F#). | Same, written `%.6f` (Odin's `%f` prints three). |

## Kept as the original did it

- **The ship has an entity number too.** Numbers 1 to 111 are dealt out at random to the ship, the 100 stars and the 10 wormholes, so one number is always wasted on the ship (`survey` on it says "Not a star!") and the wormholes cannot be told by their numbers.
- **Unsurveyed stars and wormholes both show as "unknown".** The only way to learn which is which is to survey it; a wormhole throws the ship to a random spot and is never marked.
- **Engaging with no fuel is the loss.** Fuel can reach 0 safely; the game ends when you engage again.
- **Engage at speed 0 still costs a fuel and passes a turn.** It is how stars grow their fuel while the ship waits.
- **Every engage grows every star's fuel**, by that star's own rate up to its own maximum, surveyed or not.
- **Refuel takes the star's whole fuel, rounded down**, adds it to the ship up to 100 and empties the star, even if the ship was already full.
- **Surveying an already surveyed star is allowed** and says "Star surveyed!" again; it is not counted twice.
- **Abandoning prints "Game over!"** and plays the lose song, like a loss.
- **Reach is 1.0 and view is 10.0**, both measured as straight-line distance; everything inside reach is also in the viewable list.
- **Heading is theta around the z axis (-180 to 180) and phi up from the xy plane (-90 to 90).** A bearing printed in the status uses the same two angles, so it can be typed straight into `set heading`.
- **Sound.** The original played short tunes through `Console.Beep` and waited for each to finish. The port plays the same notes as square waves in the background, after the first key or click, with a mute button.
