# Omagotchi

A cute robot that sits in your [Omarchy](https://github.com/basecamp/omarchy) bar and keeps you company while you work.

![Omagotchi preview](screenshot.png)

## Install

```bash
omarchy plugin add git@github.com:vdsabev/omagotchi.git --enable --yes
omarchy plugin enable vdsabev.omagotchi --section right
```

Or clone the repo at `~/.config/omarchy/plugins/vdsabev.omagotchi/` and run:

```bash
omarchy-shell shell rescanPlugins
omarchy plugin enable vdsabev.omagotchi
```

## Remove

```bash
omarchy plugin disable vdsabev.omagotchi
omarchy plugin remove vdsabev.omagotchi
```

## Dependencies

- Omarchy Quattro (`omarchy-shell` / Quickshell)
- Hyprland socket — `cursorpos` is used to track the cursor for pupil direction
- `$TERMINAL` — required to launch TUI games (e.g. Omasweeper, Quattrolitaire)
- Uninstalled games are offered via a one-time `omarchy plugin add` confirmation in the popup

## State

The plugin writes nickname and last-click state to `~/.config/omagotchi/state.json`.

## Features

- Bar: binocular eyes themed from the Omarchy bar (`bar.foreground`, `bar.background`, `Color.accent`). Pupils follow the cursor while you move the mouse, then wander when it is still. Blinking happens inside the eyes. Sleepy lids at night or after idle.
- Left click: popup with the full robot, a mood line, and the game strip. Click the name (or Tab to it and press Enter) to rename: Enter keeps it, Escape cancels, empty falls back to Omagotchi.
- Games: one row of icons under the robot, the name in the tooltip. Omasweeper, Quattrolitaire, and Tetris are always listed; a plugin that is not installed sits dimmed and asks once, in the flavor line, before `omarchy plugin add`. A game that is installed but switched off is switched on first. Extra games go in `~/.config/omagotchi/games.json` — an array of `{ id, label, icon, kind: plugin|tui|gui, command, install }`, where `tui` gets `$TERMINAL -e` and a missing binary answers in the flavor line.
- Right click: tooltip with the current flavor line.
- Moods:
	- `idle`
	- `curious` (glancing at the pointer)
	- `sleepy` (idle)
	- `night` (22:00–07:00)
	- `happy` (you clicked)
- State: `~/.config/omagotchi/state.json` (nickname, last click).

## File structure

- `manifest.json` - plugin contract (kind: bar-widget)
- `BarWidget.qml` - bar eyes + popup (one Panel-rooted entry point)
- `CursorTracker.qml` - Hyprland socket `cursorpos` → look direction
- `Eyes.qml` - shared binocular head
- `GameStrip.qml` - game icon strip, install confirm
- `Games.js` - game list, launch and install commands
- `Games.test.mjs` - game list tests
- `NicknameField.qml` - editable pet name
- `PetState.js` - moods, flavor, nickname rules
- `PetState.test.mjs` - mood tests
- `PetPanel.qml` - persistent popup window
- `Robot.qml` - full body

Tests run with `npm test`.

## License

[MIT](LICENSE)

## Later

See [TODO.md](TODO.md).
