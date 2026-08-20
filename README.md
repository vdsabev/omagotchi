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

- Bar: binocular eyes themed from the Omarchy bar (`bar.foreground`, `bar.background`, `Color.accent`). Pupils glance at the cursor when you move your mouse, then settle down. Between glances they wander and blink. Sleepy lids at night or after idle.
- Left click: popup with the full robot and a mood line.
- Right click: tooltip with the current flavor line.
- Moods:
	- `watching`
	- `curious` (glancing at the pointer)
	- `sleepy` (idle)
	- `night` (22:00–07:00)
	- `happy` (you clicked)
- State: `~/.config/omarchy/state.json` (nickname, last click).

## File structure

- `manifest.json` - plugin contract (kind: bar-widget)
- `BarWidget.qml` - bar eyes + panel host
- `CursorTracker.qml` - hyprctl cursorpos → short glance bursts
- `Eyes.qml` - shared binocular head
- `Panel.qml` - popup stage
- `PetState.js` - moods + flavor
- `Robot.qml` - full body

## Later

See [TODO.md](TODO.md).
