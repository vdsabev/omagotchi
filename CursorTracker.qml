import QtQuick
import Quickshell
import Quickshell.Io

// Polls Hyprland for the global cursor. The eyes follow it while it moves and
// wander once it has been still for a moment.
//
// The poll talks to the Hyprland request socket directly. Running `hyprctl` a
// few times a second costs ~30% of a core in fork/exec alone.
Item {
  id: root

  property real lookX: 0
  property real lookY: 0
  property real lastMoveMs: Date.now()
  property real lastGlanceMs: 0
  property bool tracking: false
  // How long after the last cursor movement the eyes keep following it. Matches
  // the curious mood window in PetState.js, so the pupils shrink and start to
  // wander on the same beat as the mood text.
  readonly property int holdMs: 5000
  property int cursorX: 0
  property int cursorY: 0
  property int widgetX: 0
  property int widgetY: 0
  property int widgetW: 28
  property int widgetH: 16
  property bool idleWander: true

  // Cursor distance that pins the pupils at the horizontal edge of the eye.
  readonly property real reachX: 320
  property int screenTop: 0
  property int screenH: 1080

  property real wanderX: 0
  property real wanderY: 0

  // Where the eyes are heading. A fixed tick copies it into lookX/lookY, which
  // lags the cursor without stalling: delaying the animation instead would keep
  // restarting its pause while the mouse is still moving.
  property real targetX: 0
  property real targetY: 0
  readonly property int reactMs: 200

  Timer {
    interval: root.reactMs
    running: true
    repeat: true
    onTriggered: {
      root.lookX = root.targetX
      root.lookY = root.targetY
    }
  }

  // Constant-rate glide, so the pupils drift instead of snapping.
  Behavior on lookX {
    NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
  }

  Behavior on lookY {
    NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
  }

  function setAnchor(item) {
    if (!item)
      return
    var p = item.mapToGlobal(0, 0)
    widgetX = p.x
    widgetY = p.y
    widgetW = item.width
    widgetH = item.height
    // Which screen the cursor is on decides the vertical range. Item.window is
    // null for bar content here, so match the poll position against the screen
    // list instead.
    for (var i = 0; i < Quickshell.screens.length; i++) {
      var scr = Quickshell.screens[i]
      if (cursorY >= scr.y && cursorY < scr.y + scr.height
          && cursorX >= scr.x && cursorX < scr.x + scr.width) {
        screenTop = scr.y
        screenH = scr.height
        break
      }
    }
  }

  function applyCursor(x, y) {
    var now = Date.now()
    var moved = x !== cursorX || y !== cursorY
    if (moved)
      lastMoveMs = now
    cursorX = x
    cursorY = y

    tracking = now - lastMoveMs < holdMs
    idleWander = !tracking
    if (!tracking) {
      targetX = wanderX
      targetY = wanderY
      return
    }

    if (moved)
      lastGlanceMs = now

    var cx = widgetX + widgetW / 2
    var dx = x - cx
    targetX = Math.max(-1, Math.min(1, dx / reachX))
    // Vertical look is the cursor's place on the screen, not its offset from the
    // widget: the bar sits against a screen edge, so an offset would put the
    // cursor below the eyes nearly always and the pupils would never rise.
    targetY = Math.max(-1, Math.min(1, (y - screenTop) / (screenH / 2) - 1))
  }

  readonly property string socketPath: Quickshell.env("XDG_RUNTIME_DIR") + "/hypr/"
    + Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") + "/.socket.sock"

  Timer {
    interval: root.tracking ? 90 : 250
    running: true
    repeat: true
    onTriggered: {
      if (sock.connected)
        return
      sock.connected = true
    }
  }

  Timer {
    interval: 1800
    running: true
    repeat: true
    onTriggered: {
      wanderX = (Math.random() * 2 - 1) * 0.7
      wanderY = (Math.random() * 2 - 1) * 0.45
      if (root.idleWander) {
        root.targetX = wanderX
        root.targetY = wanderY
      }
    }
  }

  Socket {
    id: sock
    path: root.socketPath

    onConnectedChanged: {
      if (connected) {
        write("cursorpos")
        flush()
      }
    }

    // Hyprland answers, then closes: one reply per connection, ended by EOF.
    // Hyprland replies once and closes. An empty marker hands over each chunk
    // as it arrives; closing here beats Hyprland to it and avoids a
    // PeerClosedError warning per poll.
    parser: SplitParser {
      splitMarker: ""
      onRead: function(chunk) {
        sock.connected = false
        var parts = chunk.trim().split(",")
        if (parts.length < 2)
          return
        var x = parseInt(parts[0], 10)
        var y = parseInt(parts[1], 10)
        if (isNaN(x) || isNaN(y))
          return
        root.applyCursor(x, y)
      }
    }
  }
}
