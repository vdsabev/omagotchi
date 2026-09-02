import QtQuick

// Binocular head: a 5-row pixel grid, rim + two 3x3 wells. Colors come from
// the Omarchy theme.
Item {
  id: root

  property real lookX: 0   // -1 .. 1
  property real lookY: 0
  property bool blink: false
  property bool sleepy: false
  // Dilated pupils while the eyes are following something.
  property bool alert: false
  property color bodyColor: "#1c1c28"
  property color rimColor: "#ffe14d"
  property color wellColor: "#0b0b12"
  property color pupilColor: "#3dfff3"
  // Cells between the two wells. One pixel makes a narrower head.
  property int gap: 2

  implicitWidth: 40
  implicitHeight: 20

  readonly property int cols: 8 + gap
  readonly property real pixel: Math.max(1, Math.floor(Math.min(width / cols, height / 5)))
  readonly property real gridW: pixel * cols
  readonly property real gridH: pixel * 5

  // Pupil cell inside a 3x3 well. Sleepy lids cover the top row, so the pupil
  // cannot sit there.
  readonly property int pupilX: 1 + Math.max(-1, Math.min(1, Math.round(lookX)))
  readonly property int pupilY: {
    var v = 1 + Math.max(-1, Math.min(1, Math.round(lookY)))
    return sleepy ? Math.max(1, v) : v
  }

  function cellColor(cx, cy) {
    if (blink)
      return cy === 1 ? rimColor : wellColor
    if (sleepy && cy === 0)
      return bodyColor
    if (cx === pupilX && cy === pupilY)
      return pupilColor
    // Alert dilation reads as a halo on the cells around the pupil.
    if (alert && !sleepy && Math.abs(cx - pupilX) <= 1 && Math.abs(cy - pupilY) <= 1)
      return Qt.rgba((pupilColor.r + wellColor.r * 2) / 3,
                     (pupilColor.g + wellColor.g * 2) / 3,
                     (pupilColor.b + wellColor.b * 2) / 3, 1)
    return wellColor
  }

  Item {
    anchors.centerIn: parent
    width: root.gridW
    height: root.gridH

    // Rim
    Rectangle {
      anchors.fill: parent
      color: root.rimColor
    }

    // Face plate
    Rectangle {
      x: root.pixel
      y: root.pixel
      width: root.pixel * (root.cols - 2)
      height: root.pixel * 3
      color: root.bodyColor
    }

    // Two 3x3 wells, one pixel in from the rim.
    Repeater {
      model: 18

      Rectangle {
        required property int index
        readonly property int eye: Math.floor(index / 9)
        readonly property int cx: index % 3
        readonly property int cy: Math.floor((index % 9) / 3)

        x: root.pixel * (1 + eye * (3 + root.gap) + cx)
        y: root.pixel * (1 + cy)
        width: root.pixel
        height: root.pixel
        color: root.cellColor(cx, cy)
      }
    }
  }
}
