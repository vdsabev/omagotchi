import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui

// Full-screen overlay panel. A MouseArea covers the screen and closes the
// panel on outside clicks; a Region mask excludes the bar strip so bar
// interactions still work.
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
  // The card decides whether a name is being typed; the widget reads it back to
  // keep Enter and Escape away from the close handlers.
  property bool editingName: false

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
    anchorWatcher.transform  // reactive dependency
    if (!anchorItem || !anchorWindow)
      return Qt.point(0, 0)
    return anchorItem.mapToItem(anchorWindow.contentItem, 0, 0)
  }

  readonly property real barW: anchorWindow ? anchorWindow.width : screenW
  readonly property real barH: anchorWindow ? anchorWindow.height : 0
  readonly property real screenW: screen ? screen.width : 0
  readonly property real screenH: screen ? screen.height : 0
  readonly property real anchorW: anchorItem ? anchorItem.width : 0
  readonly property real anchorH: anchorItem ? anchorItem.height : 0

  readonly property point cardOrigin: {
    if (!anchorItem || !bar) return Qt.point(gap, gap)
    var x = 0, y = 0
    if (barPos === "bottom") {
      x = anchorPos.x + anchorW / 2 - contentWidth / 2
      y = screenH - barH - contentHeight - gap
    } else if (barPos === "top") {
      x = anchorPos.x + anchorW / 2 - contentWidth / 2
      y = barH + gap
    } else if (barPos === "left") {
      x = barW + gap
      y = anchorPos.y + anchorH / 2 - contentHeight / 2
    } else { // "right"
      x = screenW - barW - contentWidth - gap
      y = anchorPos.y + anchorH / 2 - contentHeight / 2
    }
    x = Math.max(gap, Math.min(x, screenW - contentWidth - gap))
    y = Math.max(gap, Math.min(y, screenH - contentHeight - gap))
    return Qt.point(Math.round(x), Math.round(y))
  }

  screen: anchorWindow ? anchorWindow.screen : null
  visible: open
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore

  WlrLayershell.namespace: "omagotchi-panel"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

  // Full-screen overlay — the card inside is positioned explicitly via cardOrigin.
  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  mask: Region {
    width: root.screenW
    height: root.screenH
  }

  onVisibleChanged: {
    if (visible && focusTarget)
      Qt.callLater(function() { if (root.focusTarget) root.focusTarget.forceActiveFocus() })
  }

  // Track every layout change between the bar's contentItem and the
  // anchor item. `transform` updates whenever any item in that chain
  // moves/resizes, which is what makes the position binding below
  // actually reactive — mapToItem on its own is a one-shot.
  TransformWatcher {
    id: anchorWatcher
    a: anchorWindow ? anchorWindow.contentItem : null
    b: anchorItem
  }

  // Clicking anywhere outside the card closes the panel.
  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.AllButtons
    onClicked: root.closeRequested()
  }

  BorderSurface {
    id: card
    x: root.cardOrigin.x
    y: root.cardOrigin.y
    width: root.contentWidth
    height: root.contentHeight
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
