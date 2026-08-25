import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Games.js" as Games

// The game icons under the mood line. A game whose plugin is not installed
// asks once, then installs, enables, and plays it. The label and the state only
// show in the tooltip and the flavor line, so the strip stays one row.
Row {
  id: root

  property var games: []
  // id → enabled, from Games.pluginState.
  property var plugins: ({})
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family

  property string pendingId: ""
  property string busyId: ""

  signal notice(string text)
  // The popup closes on launch, so the game gets the screen to itself.
  signal launched()
  signal refreshRequested()

  spacing: Style.space(4)

  function tooltipFor(game) {
    return Games.tooltipFor(game, root.plugins, root.busyId)
  }

  function launch(game) {
    launcher.game = game
    launcher.command = Games.launchCommand(game)
    launcher.running = true
    root.launched()
  }

  // The decision is Games.actionFor; this only wires its outcome up to
  // processes, timers, and signals.
  function activate(game) {
    var a = Games.actionFor(game, root.plugins, { busy: !!root.busyId, confirmed: root.pendingId === game.id })
    if (a.action !== "ignore")
      root.pendingId = ""
    if (a.notice)
      root.notice(a.notice)
    if (a.action === "confirm")
      root.pendingId = game.id
    else if (a.action === "install") {
      root.busyId = game.id
      installer.game = game
      installer.command = Games.installCommand(game)
      installer.running = true
    } else if (a.action === "enable") {
      root.busyId = game.id
      enabler.game = game
      enabler.command = Games.enableCommand(game)
      enabler.running = true
    } else if (a.action === "launch")
      root.launch(game)
  }

  onGamesChanged: root.pendingId = ""

  Process {
    id: launcher
    property var game: null
    onExited: function(code) {
      if (code === 127 && launcher.game)
        root.notice(launcher.game.label + " is not installed on this machine.")
    }
  }

  Process {
    id: installer
    property var game: null
    onExited: function(code) {
      var game = installer.game
      if (code !== 0) {
        root.busyId = ""
        root.notice((game ? game.label : "That game") + " would not install.")
        return
      }
      enabler.game = game
      enabler.command = Games.enableCommand(game)
      enabler.running = true
    }
  }

  Process {
    id: enabler
    property var game: null
    onExited: function(code) {
      var game = enabler.game
      root.refreshRequested()
      if (code === 0) {
        // Keep busyId set until the timer fires so no click can sneak in
        // and trigger a duplicate launch during the 700ms delay.
        openAfterEnable.restart()
      } else {
        root.busyId = ""
        root.notice((game ? game.label : "That game") + " would not switch on.")
      }
    }
  }

  // `plugin enable` returns before the shell has loaded the plugin, and a
  // toggle that lands first is silently dropped. 300ms was the shortest delay
  // that worked; this leaves room.
  Timer {
    id: openAfterEnable
    interval: 700
    onTriggered: {
      root.busyId = ""
      if (enabler.game)
        root.launch(enabler.game)
    }
  }

  Repeater {
    model: root.games

    Button {
      required property var modelData
      iconText: modelData.icon
      iconSize: Style.font.body
      iconSpinning: root.busyId === modelData.id
      focusable: true
      foreground: root.foreground
      fontFamily: root.fontFamily
      // A game that still needs installing sits back until it is asked for.
      opacity: Games.isMissing(modelData, root.plugins) && root.pendingId !== modelData.id ? 0.5 : 1
      tooltipText: root.tooltipFor(modelData)
      onClicked: root.activate(modelData)
    }
  }
}
