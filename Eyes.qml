import QtQuick

// Binocular Wall-E head. Colors come from the Omarchy theme.
Item {
  id: root

  property real lookX: 0   // -1 .. 1
  property real lookY: 0
  property bool blink: false
  property bool sleepy: false
  property color bodyColor: "#1c1c28"
  property color rimColor: "#ffe14d"
  property color wellColor: "#0b0b12"
  property color pupilColor: "#3dfff3"
  property real pixel: Math.max(1, Math.floor(Math.min(width, height) / 14))

  implicitWidth: 28
  implicitHeight: 16

  readonly property real eyeW: pixel * 6
  readonly property real eyeH: blink ? pixel : (sleepy ? pixel * 3 : pixel * 6)
  readonly property real gap: pixel * 2
  readonly property real pupil: sleepy ? pixel : pixel * 2
  readonly property real maxOff: pixel * 1.5

  Rectangle {
    anchors.centerIn: parent
    width: root.eyeW * 2 + root.gap + root.pixel * 2
    height: root.eyeH + root.pixel * 2
    color: root.bodyColor
    border.color: root.rimColor
    border.width: root.pixel
    radius: 0
  }

  Repeater {
    model: 2

    Item {
      required property int index
      width: root.eyeW
      height: root.eyeH
      x: (root.width - (root.eyeW * 2 + root.gap)) / 2 + index * (root.eyeW + root.gap)
      y: (root.height - root.eyeH) / 2

      Rectangle {
        anchors.fill: parent
        color: root.wellColor
        border.color: root.rimColor
        border.width: Math.max(1, root.pixel / 2)
        radius: 0
      }

      Rectangle {
        visible: !root.blink
        width: root.pupil
        height: root.sleepy ? Math.max(1, root.pixel) : root.pupil
        color: root.pupilColor
        x: (parent.width - width) / 2 + root.lookX * root.maxOff
        y: (parent.height - height) / 2 + root.lookY * root.maxOff
      }
    }
  }
}
