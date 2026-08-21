import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui

// Popup that stays open until it is closed on purpose.
//
// Not Ui.KeyboardPanel: that one spans the screen with a MouseArea that closes
// on any click outside the card, and without the close the same overlay would
// swallow every click on the desktop. This window is only as large as the card,
// so the rest of the screen keeps working while the pet is on show.
PanelWindow {
  id: root

  required property Item anchorItem
  required property QtObject bar
  property bool open: false
  property int contentWidth: Style.space(280)
  property int contentHeight: Style.space(200)
  property int padding: Style.spacing.popupPadding
  property int gap: Style.gapsOut
  property Item focusTarget: null

  default property alias contentItem: contentHolder.children

  signal closeRequested()

  // Hyprland's corner rounding, so the close button clears the rounded corner
  // instead of sitting under it.
  property int rounding: 0

  Process {
    command: ["hyprctl", "getoption", "decoration:rounding"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        var m = text.match(/int:\s*(\d+)/)
        if (m)
          root.rounding = parseInt(m[1], 10)
      }
    }
  }

  readonly property var anchorWindow: anchorItem ? anchorItem.QsWindow.window : null
  readonly property string barPos: bar ? bar.position : "top"
  readonly property bool barVertical: barPos === "left" || barPos === "right"
  readonly property real barThickness: anchorWindow
    ? (barVertical ? anchorWindow.width : anchorWindow.height)
    : 0
  readonly property point anchorPos: {
    anchorWatcher.revision  // reactive dependency
    if (!anchorItem || !anchorWindow)
      return Qt.point(0, 0)
    return anchorItem.mapToItem(anchorWindow.contentItem, 0, 0)
  }

  function clampAlong(pos, size, limit) {
    return Math.round(Math.max(gap, Math.min(pos, limit - size - gap)))
  }

  screen: anchorWindow ? anchorWindow.screen : null
  visible: open
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  implicitWidth: contentWidth
  implicitHeight: contentHeight

  WlrLayershell.namespace: "omagotchi-panel"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

  // One anchored edge per axis, so the window keeps its own size and the
  // margins place it next to the icon.
  anchors {
    top: barPos !== "bottom"
    bottom: barPos === "bottom"
    left: barPos !== "right"
    right: barPos === "right"
  }

  margins {
    top: root.barVertical
      ? root.clampAlong(root.anchorPos.y, root.contentHeight, root.screen ? root.screen.height : 0)
      : (root.barPos === "top" ? root.barThickness + root.gap : 0)
    bottom: root.barPos === "bottom" ? root.barThickness + root.gap : 0
    left: root.barVertical
      ? (root.barPos === "left" ? root.barThickness + root.gap : 0)
      : root.clampAlong(root.anchorPos.x, root.contentWidth, root.screen ? root.screen.width : 0)
    right: root.barPos === "right" ? root.barThickness + root.gap : 0
  }

  onVisibleChanged: {
    if (visible && focusTarget)
      Qt.callLater(function() { if (root.focusTarget) root.focusTarget.forceActiveFocus() })
  }

  // mapToItem is not a binding dependency, so watch the anchor for layout moves.
  Item {
    id: anchorWatcher
    property int revision: 0
    Connections {
      target: root.anchorItem
      function onXChanged() { anchorWatcher.revision++ }
      function onYChanged() { anchorWatcher.revision++ }
      function onWidthChanged() { anchorWatcher.revision++ }
    }
  }

  BorderSurface {
    id: card
    anchors.fill: parent
    color: Color.popups.background
    borderSpec: Border.surfaceSpec("popups", "border", Color.popups.border, Math.max(1, Style.space(2)))
    padding: root.padding
    radius: Style.cornerRadius

    Item {
      id: contentHolder
      anchors.fill: parent
      anchors.topMargin: card.contentTopInset
      anchors.rightMargin: card.contentRightInset
      anchors.bottomMargin: card.contentBottomInset
      anchors.leftMargin: card.contentLeftInset
    }

    Text {
      anchors.top: parent.top
      anchors.right: parent.right
      anchors.topMargin: Style.space(4)
      anchors.rightMargin: Style.space(4) + root.rounding * 0.5
      text: "×"
      color: Color.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.displayLarge
      opacity: closeMouse.containsMouse ? 1 : 0.5

      MouseArea {
        id: closeMouse
        anchors.fill: parent
        anchors.margins: -Style.space(6)
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.closeRequested()
      }
    }
  }
}
