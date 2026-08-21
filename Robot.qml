import QtQuick

// Full-body pixel Wall-E. Rim/pupil colors are the Omarchy theme.
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
  width: 220
  height: 220

  readonly property real px: Math.max(2, Math.floor(Math.min(width, height) / 48))
  property real eyeYOffset: sleepy ? px * 24 : px * 12
  property real neckH: sleepy ? 0 : px * 10

  Behavior on eyeYOffset { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }
  Behavior on neckH { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }

  Item {
    anchors.horizontalCenter: parent.horizontalCenter
    width: column.implicitWidth
    height: root.px * 58

    Eyes {
      id: head
      width: root.px * 28
      height: root.px * 14
      anchors.horizontalCenter: parent.horizontalCenter
      y: root.eyeYOffset
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

    Column {
      id: column
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      height: root.neckH + root.px * 18 + root.px * 6
      spacing: 0

      // Neck. The Eyes item leaves empty space below its drawn head box, so the
      // neck has to span that too or the robot looks decapitated.
      Rectangle {
        width: root.px * 3
        height: root.neckH
        color: root.yellow
        anchors.horizontalCenter: parent.horizontalCenter
      }

      // Torso + arms
      Item {
        width: root.px * 36
        height: root.px * 18
        anchors.horizontalCenter: parent.horizontalCenter

        // Left arm
        Rectangle {
          x: 0
          y: root.px * 2
          width: root.px * 3
          height: root.px * 12
          color: root.yellow
        }
        Rectangle {
          x: 0
          y: root.px * 12
          width: root.px * 5
          height: root.px * 3
          color: root.accent
        }

        // Body
        Rectangle {
          x: root.px * 6
          width: root.px * 24
          height: root.px * 16
          color: root.chassis
          border.color: root.yellow
          border.width: root.px

          Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.px * 3
            width: root.px * 10
            height: root.px * 6
            color: root.dark
            border.color: root.accent
            border.width: Math.max(1, root.px / 2)

            Rectangle {
              anchors.centerIn: parent
              width: root.px * 2
              height: root.px * 2
              color: root.accent
              opacity: root.sleepy ? 0.3 : 1
            }
          }

          Rectangle {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.px * 2
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.px * 14
            height: root.px * 2
            color: root.yellow
          }
        }

        // Right arm
        Rectangle {
          x: parent.width - root.px * 3
          y: root.px * 2
          width: root.px * 3
          height: root.px * 12
          color: root.yellow
        }
        Rectangle {
          x: parent.width - root.px * 5
          y: root.px * 12
          width: root.px * 5
          height: root.px * 3
          color: root.accent
        }
      }

      // Treads
      Row {
        spacing: root.px * 2
        anchors.horizontalCenter: parent.horizontalCenter

        Repeater {
          model: 2
          Rectangle {
            width: root.px * 16
            height: root.px * 6
            color: root.dark
            border.color: root.accent
            border.width: root.px

            Row {
              anchors.centerIn: parent
              spacing: root.px
              Repeater {
                model: 4
                Rectangle {
                  width: root.px
                  height: root.px * 3
                  color: root.yellow
                }
              }
            }
          }
        }
      }
    }
  }
}
