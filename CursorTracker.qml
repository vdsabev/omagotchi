import QtQuick
import Quickshell.Io

// Polls Hyprland for the global cursor. Eyes glance for 5–10s, then
// settle for 5–10 min. Between glances they wander.
Item {
  id: root

  property real lookX: 0
  property real lookY: 0
  property real lastMoveMs: Date.now()
  property real lastGlanceMs: 0
  property bool tracking: false
  property real trackUntilMs: 0
  property real nextTrackMs: Date.now()
  property int cursorX: 0
  property int cursorY: 0
  property int widgetX: 0
  property int widgetY: 0
  property int widgetW: 28
  property int widgetH: 16
  property bool idleWander: true

  property real wanderX: 0
  property real wanderY: 0

  function burstMs() {
    return 5000 + Math.random() * 5000
  }

  function cooldownMs() {
    return 300000 + Math.random() * 300000
  }

  function settle() {
    tracking = false
    idleWander = true
    lookX = wanderX
    lookY = wanderY
    nextTrackMs = Date.now() + cooldownMs()
  }

  function setAnchor(item) {
    if (!item)
      return
    var p = item.mapToGlobal(0, 0)
    widgetX = p.x
    widgetY = p.y
    widgetW = item.width
    widgetH = item.height
  }

  function applyCursor(x, y) {
    var now = Date.now()
    var moved = x !== cursorX || y !== cursorY
    if (moved)
      lastMoveMs = now
    cursorX = x
    cursorY = y

    if (tracking && now >= trackUntilMs) {
      settle()
      return
    }

    if (!tracking) {
      if (moved && now >= nextTrackMs) {
        tracking = true
        idleWander = false
        trackUntilMs = now + burstMs()
      } else {
        idleWander = true
        lookX = wanderX
        lookY = wanderY
        return
      }
    }

    if (moved)
      lastGlanceMs = now

    var cx = widgetX + widgetW / 2
    var cy = widgetY + widgetH / 2
    var dx = x - cx
    var dy = y - cy
    var mag = Math.sqrt(dx * dx + dy * dy)
    if (mag < 1) {
      lookX = 0
      lookY = 0
      return
    }
    var scale = Math.min(1, mag / 420)
    lookX = Math.max(-1, Math.min(1, (dx / mag) * scale))
    lookY = Math.max(-1, Math.min(1, (dy / mag) * scale))
  }

  Timer {
    interval: root.tracking ? 90 : 400
    running: true
    repeat: true
    onTriggered: {
      proc.running = false
      proc.running = true
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
        root.lookX = wanderX
        root.lookY = wanderY
      }
    }
  }

  Process {
    id: proc
    command: ["hyprctl", "cursorpos"]
    stdout: StdioCollector {
      onStreamFinished: {
        var t = text.trim()
        var parts = t.split(",")
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
