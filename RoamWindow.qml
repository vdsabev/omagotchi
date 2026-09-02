import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons

// The playground: a strip along the foot of the screen, where the robot paces
// back and forth. Click-through except the robot itself, so the desktop stays
// usable.
PanelWindow {
  id: root

  property string barPos: "top"
  // Fallback when Hyprland has no reserved area for this monitor yet.
  property real barThickness: 0
  property color themeFg: Color.foreground
  property color themeBg: Qt.rgba(0.05, 0.05, 0.07, 1)
  property color themeAccent: Color.accent
  property real lookX: 0
  property real lookY: 0
  property bool blink: false
  property bool sleepy: false
  property bool alert: false
  property string mood: "idle"

  signal poked()
  signal launched()
  signal landed()
  signal bumped()

  readonly property int spriteSize: 48
  // Headroom for a launch. The strip is always this deep so the sprite never
  // jumps when a drag starts.
  readonly property int flightRoom:
    Math.max(320, Math.round((root.screen ? root.screen.height : 1080) * 0.75))

  // The bar's own strip, so the robot keeps clear of it.
  readonly property real barEdge: {
    var monitor = Hyprland.monitorFor(root.screen)
    var ipc = monitor ? monitor.lastIpcObject : null
    var reserved = ipc && ipc.reserved && ipc.reserved.length > 3 ? ipc.reserved : null
    if (!reserved)
      return barThickness
    switch (barPos) {
    case "left": return Number(reserved[0])
    case "right": return Number(reserved[2])
    case "bottom": return Number(reserved[3])
    default: return Number(reserved[1])
    }
  }

  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.namespace: "omagotchi-roam"
  mask: Region { item: sprite }

  // Gravity points one way, so the floor is the foot of the screen wherever
  // the bar sits; the bar only pushes the strip's edges out of its way.
  anchors {
    left: true
    right: true
    bottom: true
  }
  margins {
    left: root.barPos === "left" ? root.barEdge : 0
    right: root.barPos === "right" ? root.barEdge : 0
    bottom: root.barPos === "bottom" ? root.barEdge : 0
  }
  implicitHeight: root.spriteSize + root.flightRoom

  // --- pacing ----------------------------------------------------------------

  // Height above the floor, against a screen y that grows downwards.
  readonly property real awaySpan: height - spriteSize
  readonly property real maxTravel: Math.max(0, width - spriteSize)
  // Distance from the start of the track to the robot's leading edge.
  property real travel: 0
  property int direction: 1
  property bool walking: true
  readonly property real speed: 60 // px/s

  Timer {
    interval: 40
    running: root.visible
    repeat: true
    onTriggered: {
      if (!root.walking || root.held || root.flying)
        return
      var next = root.travel + root.direction * root.speed * (interval / 1000)
      if (next <= 0 || next >= root.maxTravel) {
        next = Math.max(0, Math.min(root.maxTravel, next))
        root.direction = -root.direction
        root.pause()
      }
      root.travel = next
    }
  }

  // One tread pixel per 1/8 second of travel, so the tracks roll at the pace
  // the robot actually moves.
  Timer {
    interval: Math.max(60, 1000 / (root.speed / 8))
    running: root.visible && root.walking && !root.held && !root.flying
    repeat: true
    onTriggered: sprite.treadPhase += root.direction
  }

  // Held under the cursor: the robot stands still instead of walking.
  property bool held: false

  // --- launch ----------------------------------------------------------------

  // A sling: drag the robot away from where it stands and let go, and it flies
  // out opposite the pull while an arrow at its side shows the aim.
  readonly property real maxStretch: 90
  readonly property real gravity: 800 // px/s^2
  // Pull distance to launch speed, capped so the tallest arc still fits in
  // flightRoom.
  readonly property real launchScale: 12
  readonly property real minLaunch: 12
  // The floor leaves only a sliver to drag downwards, so that axis counts for
  // more and the full range of angles stays reachable.
  readonly property real awayBoost: 4

  // Pointer offset from the grab point, in track/away axes.
  property real stretchTrack: 0
  property real stretchAway: 0
  property real pressTrack: 0
  property real pressAway: 0

  property bool flying: false
  property real altitude: 0
  property real velTrack: 0
  property real velAway: 0

  // The robot may be pulled into the floor, but not so far that it sinks out
  // of sight.
  readonly property real away:
    flying ? altitude : (held ? Math.max(-spriteSize / 2, stretchAway) : 0)
  readonly property real spriteAway: awaySpan - away
  readonly property real spriteTrack:
    Math.max(0, Math.min(maxTravel, travel + (held ? stretchTrack : 0)))

  function grab(mx, my) {
    var wx = sprite.x + mx
    var wy = sprite.y + my
    pressTrack = wx
    pressAway = wy
    stretchTrack = 0
    stretchAway = 0
    flying = false
    held = true
  }

  function drag(mx, my) {
    if (!held)
      return
    var wx = sprite.x + mx
    var wy = sprite.y + my
    var track = wx - pressTrack
    var awayDrag = pressAway - wy
    // Clamped as a vector, so the reach is a circle: the same drag distance
    // pulls equally hard whichever way it points.
    var len = Math.sqrt(track * track + awayDrag * awayDrag)
    var scale = len > maxStretch ? maxStretch / len : 1
    stretchTrack = track * scale
    stretchAway = awayDrag * scale
  }

  // How hard the sling is drawn, and where it points. The boost applies to the
  // direction only, so power stays even in every direction.
  readonly property real pull: Math.sqrt(stretchTrack * stretchTrack + stretchAway * stretchAway)
  readonly property real aimTrack: -stretchTrack
  readonly property real aimAway: -stretchAway * awayBoost
  readonly property real aim: Math.sqrt(aimTrack * aimTrack + aimAway * aimAway)
  readonly property bool aiming: held && pull >= minLaunch
  readonly property real pitch: Math.min(1, pull / maxStretch)

  function release() {
    if (!held)
      return
    var wasAiming = aiming
    var length = Math.max(aim, 1)
    var speed = pull * launchScale
    var track = speed * aimTrack / length
    var up = speed * aimAway / length
    // It leaves from the hand, so the flight picks up where the drag ended.
    var fromTrack = spriteTrack
    var fromAway = Math.max(0, stretchAway)
    held = false
    stretchTrack = 0
    stretchAway = 0
    if (!wasAiming)
      return
    travel = fromTrack
    altitude = fromAway
    velTrack = track
    // A flat sling still has to leave the ground, or it lands on the same tick.
    velAway = Math.max(up, 0.35 * Math.abs(track))
    walking = false
    flying = true
    launched()
  }

  Timer {
    interval: 16
    running: root.visible && root.flying
    repeat: true
    onTriggered: root.fall(interval / 1000)
  }

  function fall(dt) {
    velAway -= gravity * dt
    altitude += velAway * dt
    if (altitude > flightRoom) {
      altitude = flightRoom
      velAway = 0
    }
    var next = travel + velTrack * dt
    if (next <= 0 || next >= maxTravel) {
      next = Math.max(0, Math.min(maxTravel, next))
      // A wall it barely creeps into makes no noise, so a slow bounce is silent.
      if (Math.abs(velTrack) > 60)
        bumped()
      velTrack = -velTrack * 0.6
    }
    travel = next
    if (altitude <= 0) {
      altitude = 0
      flying = false
      direction = velTrack < 0 ? -1 : 1
      landed()
      pause()
    }
  }

  function pause() {
    walking = false
    restTimer.interval = 700 + Math.random() * 2500
    restTimer.restart()
  }

  Timer {
    id: restTimer
    onTriggered: root.walking = true
  }

  // A stroll that only ever turns at the walls is a metronome; turn early now
  // and then so the pacing reads as wandering.
  Timer {
    interval: 6000
    running: root.visible
    repeat: true
    onTriggered: {
      interval = 5000 + Math.random() * 9000
      if (!root.walking)
        return
      if (Math.random() < 0.5)
        root.direction = -root.direction
      root.pause()
    }
  }

  onVisibleChanged: if (visible) {
    travel = Math.max(0, maxTravel / 2)
    direction = Math.random() < 0.5 ? -1 : 1
    walking = true
  }

  // Aim indicator: a pixel arrow at the anchor, pointing where the robot goes.
  Item {
    id: arrow

    // Screen axes, so the arrow can just be rotated into place.
    readonly property real dx: root.aimTrack
    readonly property real dy: -root.aimAway

    // Empty space between the anchor and the tail, so the arrow clears the
    // robot instead of being drawn over it.
    readonly property real gap: root.spriteSize / 2 + 4

    visible: root.aiming
    // Length follows the pull, the same figure that sets the launch speed.
    width: gap + 24 + 96 * root.pitch
    height: root.spriteSize / 4
    // Pinned at the robot and turned about it, so the tail follows the drag
    // and always leaves along the flight line.
    x: sprite.x + root.spriteSize / 2
    y: sprite.y + root.spriteSize / 2 - height / 2
    transformOrigin: Item.Left
    rotation: Math.atan2(dy, dx) * 180 / Math.PI
    opacity: 0.85

    // Shaft and the two head bars all end at the tip, so they meet there
    // whatever the arrow's length.
    Rectangle {
      x: parent.gap
      y: parent.height / 2 - height / 2
      width: parent.width - parent.gap
      height: Math.max(2, parent.height / 3)
      color: root.themeAccent
    }

    Repeater {
      model: 2
      Rectangle {
        required property int index
        width: parent.height * 0.8
        height: Math.max(2, parent.height / 3)
        x: parent.width - width
        y: parent.height / 2 - height / 2
        color: root.themeAccent
        rotation: index === 0 ? -40 : 40
        transformOrigin: Item.Right
      }
    }
  }

  Robot {
    id: sprite
    width: root.spriteSize
    height: root.spriteSize
    x: root.spriteTrack
    y: root.spriteAway
    lookX: root.lookX
    lookY: root.lookY
    blink: root.blink
    alert: root.alert
    sleepy: root.sleepy
    mood: root.mood
    accent: root.themeAccent
    yellow: root.themeFg
    chassis: Qt.rgba(root.themeFg.r, root.themeFg.g, root.themeFg.b, 0.12)
    dark: root.themeBg

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onPressed: function(mouse) { root.grab(mouse.x, mouse.y) }
      onPositionChanged: function(mouse) { root.drag(mouse.x, mouse.y) }
      onReleased: root.release()
      onCanceled: root.release()
      onClicked: if (!root.flying) root.poked()
    }
  }
}
