import QtQuick

// The bar icon: the Eyes head on a stubby 9x9 body, drawn at whole pixels so
// it stays crisp in the bar's small icon canvas.
Item {
  id: root

  property real lookX: 0
  property real lookY: 0
  property bool blink: false
  property bool sleepy: false
  property bool alert: false
  property color accent: "#3dfff3"
  property color rimColor: "#ffe14d"
  property color chassis: "#2a2438"
  property color dark: "#0b0b12"

  readonly property int cols: 9
  readonly property int rows: 9
  // Two is the smallest size the eye wells still read at, so the sprite is
  // allowed to overflow the icon canvas rather than shrink below it.
  readonly property real px: Math.max(2, Math.floor(height / rows))

  implicitWidth: px * cols
  implicitHeight: px * rows

  // Body only; Eyes draws the five head rows. Y = rim, C = chassis, A = accent.
  readonly property var sprite: [
    "....Y....",
    "YYYYYYYYY",
    "YCCC.CCCY",
    "Y.YYYYY.Y"
  ]

  function paint(code) {
    switch (code) {
    case "Y": return rimColor
    case "C": return chassis
    case "A": return sleepy ? Qt.darker(accent, 2.4) : accent
    }
    return "transparent"
  }

  Item {
    anchors.centerIn: parent
    width: root.px * root.cols
    height: root.px * root.rows

    Eyes {
      width: root.px * root.cols
      height: root.px * 5
      gap: 1
      lookX: root.lookX
      lookY: root.lookY
      blink: root.blink
      alert: root.alert
      sleepy: root.sleepy
      rimColor: root.rimColor
      pupilColor: root.accent
      bodyColor: root.chassis
      wellColor: root.dark
    }

    Repeater {
      model: root.sprite.length * root.cols

      Rectangle {
        required property int index
        readonly property int col: index % root.cols
        readonly property int row: Math.floor(index / root.cols)

        x: root.px * col
        y: root.px * (5 + row)
        width: root.px
        height: root.px
        color: root.paint(root.sprite[row].charAt(col))
      }
    }
  }
}
