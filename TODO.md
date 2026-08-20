# TODO

## Nickname

Default is Omagotchi. Click the name in the popup to edit it (keyboard-reachable).

- [ ] Type a name, Enter to keep it, Escape to cancel
  - [ ] Empty falls back to Omagotchi
  - [ ] Shows on the popup and the bar right away, and after a restart
  - [ ] Flavor line can use the name once in a while

## Play

Game strip under the mood line (keyboard-reachable). Click a game → close popup → launch it detached.

- [ ] Always listed: Omasweeper, Quattrolitaire, Tetris
  - [ ] Extra games in `~/.config/omagotchi/games.json` (`id`, `label`, `kind: plugin|tui|gui`, `command`, optional `install`)
- [ ] `plugin`: `omarchy-shell shell toggle <id>` (Omasweeper `jankeesvw.omasweeper`, Quattrolitaire `nosignal.quattrolitaire`, Tetris `terminal.tetris`)
  - [ ] Missing plugin: confirm, then `omarchy plugin add <url> --enable`, then toggle
  - [ ] TUI in `$TERMINAL` / kitty; GUI as-is
  - [ ] Missing binary: flavor line

## Care

Attention makes it happy for a moment, then it settles.

- [ ] Opening a game (the click), opening the popup, and clicking the pet on the bar
- [ ] Popup taps: Boop, Honk, Wiggle (keyboard-reachable). Each has its own short motion and sound, then back to watching
  - [ ] Boop: visor tap, little flinch, soft blip
  - [ ] Honk: chest/nose beep, brighter blink
  - [ ] Wiggle: whole-body shake, rattly chirp
  - [ ] Sounds generated on the tap, same family with a little pitch/length wobble. Quiet; follow system mute
- [ ] Left alone a long time: a bit droopy, quieter line
- [ ] Getting plugged in: same brief happy as a click (skip if no battery; skip if already plugged in at load)
  - [ ] Flavor can mention it once
