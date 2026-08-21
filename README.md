# Omagotchi

A cute robot that sits in your [Omarchy](https://github.com/basecamp/omarchy) bar and keeps you company while you work.

## Install

```bash
omarchy plugin add git@github.com:vdsabev/omagotchi.git --enable --yes
omarchy plugin enable omagotchi.pet --section right
```

Or clone the repo at `~/.config/omarchy/plugins/omagotchi.pet/` and run:

```bash
omarchy-shell shell rescanPlugins
omarchy plugin enable omagotchi.pet
```

Requires Omarchy Quattro (`omarchy-shell` / Quickshell).

## Features

- Bar: binocular eyes themed from the Omarchy bar (`bar.foreground`, `bar.background`, `Color.accent`). Pupils follow the cursor while you move the mouse, then wander when it is still. Blinking happens inside the eyes. Sleepy lids at night or after idle.
- Left click: popup with the full robot and a mood line.
- Right click: tooltip with the current flavor line.
- Moods:
	- `idle`
	- `curious` (glancing at the pointer)
	- `sleepy` (idle)
	- `night` (22:00–07:00)
	- `happy` (you clicked)
- State: `~/.config/omarchy/state.json` (nickname, last click).

## File structure

- `manifest.json` - plugin contract (kind: bar-widget)
- `BarWidget.qml` - bar eyes + popup (one Panel-rooted entry point)
- `CursorTracker.qml` - Hyprland socket `cursorpos` → look direction
- `Eyes.qml` - shared binocular head
- `PetState.js` - moods + flavor
- `Robot.qml` - full body

## Later

See [TODO.md](TODO.md).
