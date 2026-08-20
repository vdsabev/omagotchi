# Omagotchi

A Tamagotchi-like [Omarchy](https://github.com/basecamp/omarchy) plugin: a tiny Wall-E-style robot whose eyes sit in the bar and watch the pointer. Click the eyes to open a pixel-art full-body popup. Eyes, rims, and pupils use the live Omarchy bar theme (`bar.foreground`, `bar.background`, `Color.accent`).

v1 is a pet, not a care sim — moods and flavor text, no hunger or death.

## Install

```bash
omarchy plugin add git@github.com:vdsabev/omagotchi.git --enable --yes
omarchy plugin enable omagotchi.pet --section right
```

Or drop the repo at `~/.config/omarchy/plugins/omagotchi.pet/` and run:

```bash
omarchy-shell shell rescanPlugins
omarchy plugin enable omagotchi.pet
```

Requires Omarchy Quattro (`omarchy-shell` / Quickshell). The old Waybar stack is gone on that branch.

## Behavior

| Surface | What you see |
|---|---|
| Bar | Binocular yellow eyes. Pupils track the Hyprland cursor; when the pointer is still they wander and blink. Sleepy lids at night or after idle. |
| Left click | Popup with the full 8-bit neon robot and a mood line. |
| Right click | Tooltip with the current flavor line. |

Moods: `watching`, `curious` (pointer just moved), `sleepy` (idle), `night` (23:00–06:00), `happy` (you clicked).

State lives in `~/.config/omagotchi/state.json` (hatch time, nickname, last click).

## Layout

```
manifest.json     plugin contract (kind: bar-widget)
BarWidget.qml     bar eyes + panel host
Panel.qml         popup stage
Eyes.qml          shared binocular head
Robot.qml         full body
CursorTracker.qml hyprctl cursorpos → look vector
PetState.js       moods + flavor
```

## Later (not in v1)

Hunger, play, evolution, death/reset, webcam face tracking.
