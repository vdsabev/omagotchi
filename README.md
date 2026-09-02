# Omagotchi

A cute tiny robot that sits in your [Omarchy](https://github.com/basecamp/omarchy) bar and keeps you company while you work.

![Omagotchi preview](preview.png)

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
- Hyprland socket - `cursorpos` is used to track the cursor for eye pupil direction
- UPower - charger plug/unplug sounds, if you have a battery
- `$TERMINAL` - required to launch TUI games (e.g. Omasweeper, Quattrolitaire)

## Features

- Omagotchi lives in the status bar and watches your moving mouse cursor
- Left click to open the popup
- Click the name to rename your Omagotchi
- Send your Omagotchi out to patrol your screen
- Shortcuts to games: Omasweeper, Quattrolitaire, Tetris, and Sudoku. You can add custom games in `~/.config/omagotchi/games.json`
- Moods and sound effects - mute in the popup
- Current state stored in: `~/.config/omagotchi/state.json`

## File structure

- `BarBot.qml` - the bar icon: that head on a stubby body
- `BarWidget.qml` - bar eyes + popup (one Panel-rooted entry point)
- `bin`
	- `beep.sh` - beep sound script
	- `charge.sh` - charger plug-in chirp
	- `land.sh` - thud when it comes down
	- `launch.sh` - whoosh when the robot is slung into the air
	- `play.sh` - shared playback for the sound scripts
	- `roll.sh` - motor whirr on the way out and back
	- `unplug.sh` - charger unplug tone
	- `whir.sh` - whir sound script
- `checkManifest.mjs` - CI guard requiring a version bump on every PR
- `CursorTracker.qml` - Hyprland socket `cursorpos` → look direction
- `Eyes.qml` - shared binocular head
- `Games.js` - game list, launch and install commands
- `Games.test.mjs` - game list tests
- `GameStrip.qml` - game icon strip, install confirm
- `loadLib.mjs` - test helper that loads QML libraries into Node
- `manifest.json` - plugin contract (kind: bar-widget)
- `NicknameField.qml` - editable pet name
- `package.json` - test runner config
- `PetPanel.qml` - popup card centered on the bar icon
- `PetState.js` - moods, flavor, nickname and state-file rules
- `PetState.test.mjs` - mood tests
- `PowerWatcher.qml` - UPower `onBattery` → charger plug and unplug sounds
- `RoamWindow.qml` - the strip at the foot of the screen the robot paces on
- `Robot.qml` - full body
- `SoundEngine.qml` - sound effect playback

Run tests with `npm test`.

## License

[MIT](LICENSE)
