import QtQuick

// Full-body Wall-E drawn as a 16x16 pixel sprite. Head rows are left empty in
// the map because Eyes draws them.
Item {
  id: root

  property real lookX: 0
  property real lookY: 0
  property bool blink: false
  property bool sleepy: false
  property bool alert: false
  property string mood: "idle"
  property color accent: "#3dfff3"
  property color yellow: "#ffe14d"
  property color chassis: "#2a2438"
  property color dark: "#0b0b12"

  implicitWidth: 220
  implicitHeight: 220

  readonly property real px: Math.max(1, Math.floor(Math.min(width, height) / 16))

  // Y = rim/frame, C = chassis, D = recess, A = accent, L = screen light.
  readonly property var sprite: [
    "................",
    "................",
    "................",
    "................",
    "................",
    ".......YY.......",
    ".......YY.......",
    "Y.YYYYYYYYYYYY.Y",
    "Y.YCDDDDDDDDCY.Y",
    "Y.YCDLLLLLLDCY.Y",
    "Y.YCDDDDDDDDCY.Y",
    "AAYCCYYYYYYCCYAA",
    "..YYYYYYYYYYYY..",
    "AAAAAAA..AAAAAAA",
    "ADYDYDA..ADYDYDA",
    "AAAAAAA..AAAAAAA"
  ]

  function paint(code) {
    switch (code) {
    case "Y": return yellow
    case "C": return chassis
    case "D": return dark
    case "A": return accent
    case "L": return sleepy ? Qt.darker(accent, 2.4) : accent
    }
    return "transparent"
  }

  Item {
    anchors.centerIn: parent
    width: root.px * 16
    height: root.px * 16

    Repeater {
      model: 256

      Rectangle {
        required property int index
        readonly property int col: index % 16
        readonly property int row: Math.floor(index / 16)

        x: root.px * col
        y: root.px * row
        width: root.px
        height: root.px
        color: root.paint(root.sprite[row].charAt(col))
      }
    }

    // Sleep drops the head onto the torso, which swallows the neck rows.
    Eyes {
      x: root.px * 3
      y: root.headY
      width: root.px * 10
      height: root.px * 5
      lookX: root.lookX
      lookY: root.lookY
      blink: root.blink
      alert: root.alert
      sleepy: root.sleepy
      rimColor: root.yellow
      pupilColor: root.accent
      bodyColor: root.chassis
      wellColor: root.dark
    }
  }

  property real headY: sleepy ? px * 2 : 0
  Behavior on headY { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }
}
