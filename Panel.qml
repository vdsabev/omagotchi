import QtQuick
import qs.Commons
import qs.Ui
import "PetState.js" as PetState

Panel {
  id: root
  moduleName: "omagotchi.pet"
  ipcTarget: "omagotchi.pet"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var pet: ({
    lookX: 0,
    lookY: 0,
    blink: false,
    sleepy: false,
    mood: "watching",
    flavor: "Watching you work.",
    accent: Color.accent,
    foreground: Color.foreground,
    background: Qt.rgba(0.05, 0.05, 0.07, 1),
    nickname: "W-E"
  })

  readonly property var barIdentity: hostWidget || root
  readonly property color contentForeground: bar ? bar.foreground : Color.foreground
  readonly property string contentFontFamily: bar ? bar.fontFamily : Style.font.family

  function open() {
    root.controller.show()
    Qt.callLater(function() {
      if (root.opened) setCenterHoverRevealSuppressed(true)
    })
  }

  function close() {
    setCenterHoverRevealSuppressed(false)
    root.controller.hide()
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  function setCenterHoverRevealSuppressed(value) {
    if (root.bar && "centerHoverRevealSuppressed" in root.bar)
      root.bar.centerHoverRevealSuppressed = value
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    centerOnBar: true
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(280))
    contentHeight: panel.fittedContentHeight(stage.implicitHeight + Style.space(24))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onActivateRequested: root.close()

      Column {
        id: stage
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Style.space(8)
        spacing: Style.space(10)
        width: parent.width - Style.space(16)

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: (root.pet.nickname || "W-E").toUpperCase()
          color: root.pet.accent || root.contentForeground
          font.family: root.contentFontFamily
          font.pixelSize: Style.font.body
          font.letterSpacing: 3
          font.bold: true
        }

        Robot {
          width: parent.width
          height: 180
          lookX: root.pet.lookX || 0
          lookY: root.pet.lookY || 0
          blink: root.pet.blink === true
          sleepy: root.pet.sleepy === true
          mood: root.pet.mood || "watching"
          accent: root.pet.accent || Color.accent
          yellow: root.pet.foreground || root.contentForeground
          chassis: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.12)
          dark: root.pet.background || Qt.rgba(0.05, 0.05, 0.07, 1)
        }

        Text {
          width: parent.width
          horizontalAlignment: Text.AlignHCenter
          wrapMode: Text.WordWrap
          text: root.pet.flavor || PetState.flavor("watching")
          color: root.contentForeground
          font.family: root.contentFontFamily
          font.pixelSize: Style.font.bodySmall
          opacity: 0.85
        }

        Text {
          width: parent.width
          horizontalAlignment: Text.AlignHCenter
          text: (root.pet.mood || "watching").toUpperCase()
          color: Qt.darker(root.contentForeground, 1.6)
          font.family: root.contentFontFamily
          font.pixelSize: Style.font.caption
          font.letterSpacing: 2
        }
      }
    }
  }
}
