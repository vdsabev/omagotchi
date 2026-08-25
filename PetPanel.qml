import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui

// Overlay panel that stays open until it is dismissed on purpose — the close
// button, Escape, or the bar icon. The input mask covers only the card, so
// clicks anywhere else go to the windows below instead of closing it.
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
  // Dragged position, in screen coordinates. Negative means "not moved yet", so
  // the card follows the bar icon until you drag it.
  property real dragX: -1
  property real dragY: -1
  property bool muted: false
  // The speaker glyphs sit outside Unicode, so they need the bar's Nerd Font.
  property string glyphFamily: Style.font.family

  default property alias contentItem: contentHolder.children
  // Sits in the top bar, between the mute button and the close button.
  property alias titleItem: titleHolder.children

  // The top bar overlays the card and anchors to its edge, ignoring the card
  // padding, so the content clears whichever of the two reaches lower.
  readonly property real titleBarHeight: closeButton.y + closeButton.height / 2
    + Math.max(handle.height, muteButton.height, titleHolder.height) / 2 + Style.space(8)

  signal closeRequested()
  signal muteToggled()

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

  // Align the card with the icon's end of the bar, so an icon in a corner opens
  // a card in that corner instead of one centered half off the screen.
  function alignedStart(anchorStart, anchorLen, cardLen, screenLen) {
    var center = anchorStart + anchorLen / 2
    if (center < screenLen / 3)
      return anchorStart
    if (center > screenLen * 2 / 3)
      return anchorStart + anchorLen - cardLen
    return center - cardLen / 2
  }

  readonly property point cardOrigin: {
    if (!anchorItem || !bar) return Qt.point(gap, gap)
    var x = 0, y = 0
    if (barVertical) {
      x = barPos === "left" ? barW + gap : screenW - barW - contentWidth - gap
      y = alignedStart(anchorPos.y, anchorH, contentHeight, screenH)
    } else {
      x = alignedStart(anchorPos.x, anchorW, contentWidth, screenW)
      y = barPos === "top" ? barH + gap : screenH - barH - contentHeight - gap
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
    item: card
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

  BorderSurface {
    id: card
    x: root.dragX >= 0 ? root.dragX : root.cardOrigin.x
    y: root.dragY >= 0 ? root.dragY : root.cardOrigin.y
    width: root.contentWidth
    height: root.contentHeight + Math.max(card.contentTopInset, root.titleBarHeight)
    color: Color.popups.background
    borderSpec: Border.surfaceSpec("popups", "border", Color.popups.border, Math.max(1, Style.space(2)))
    padding: root.padding
    radius: Style.cornerRadius

    Item {
      id: contentHolder
      anchors.fill: parent
      anchors.topMargin: Math.max(card.contentTopInset, root.titleBarHeight)
      anchors.rightMargin: card.contentRightInset
      anchors.bottomMargin: card.contentBottomInset
      anchors.leftMargin: card.contentLeftInset
    }

    Text {
      id: closeButton
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

    Item {
      id: titleHolder
      anchors.verticalCenter: closeButton.verticalCenter
      anchors.left: muteButton.right
      anchors.right: closeButton.left
      anchors.leftMargin: Style.space(4)
      anchors.rightMargin: Style.space(4)
      height: childrenRect.height
    }

    // Mute for the pet's own sounds only, right of the drag grip.
    Text {
      id: muteButton
      anchors.verticalCenter: closeButton.verticalCenter
      anchors.left: handle.right
      anchors.leftMargin: Style.space(8)
      // The same speaker glyphs the first-party audio panel uses.
      text: root.muted ? "󰝟" : "󰕾"
      color: Color.foreground
      font.family: root.glyphFamily
      font.pixelSize: Style.font.iconLarge
      // Pinned, so a font without the glyph cannot resize the title bar.
      width: Style.space(22)
      horizontalAlignment: Text.AlignHCenter
      opacity: root.muted ? (muteMouse.containsMouse ? 0.8 : 0.4)
        : (muteMouse.containsMouse ? 1 : 0.6)

      MouseArea {
        id: muteMouse
        anchors.fill: parent
        anchors.margins: -Style.space(10)
        // The pad stops at the middle of each gap, so it takes no click from
        // the grip - declared later, so it wins overlaps - or from the name.
        anchors.leftMargin: -Style.space(4)
        anchors.rightMargin: -Style.space(2)
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.muteToggled()
      }
    }

    // Drag grip, mirroring the close button. Hyprland moves only toplevel
    // windows, not layer-shell surfaces, so the panel moves itself.
    Item {
      id: handle
      anchors.verticalCenter: closeButton.verticalCenter
      anchors.left: parent.left
      anchors.leftMargin: Style.space(4) + root.rounding * 0.5
      width: Style.space(12)
      height: width
      opacity: mover.moving || mover.containsMouse ? 1 : 0.5

      Grid {
        anchors.centerIn: parent
        columns: 3
        spacing: Style.space(3)

        Repeater {
          model: 9

          Rectangle {
            width: Style.space(2)
            height: width
            radius: width / 2
            color: Color.foreground
          }
        }
      }

      MouseArea {
        id: mover
        anchors.fill: parent
        anchors.margins: -Style.space(6)
        anchors.rightMargin: -Style.space(4)
        hoverEnabled: true
        cursorShape: moving ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        property bool moving: false
        property real grabX: 0
        property real grabY: 0

        onPressed: function(mouse) {
          moving = true
          grabX = mouse.x + handle.x + mover.x
          grabY = mouse.y + handle.y + mover.y
        }

        onPositionChanged: function(mouse) {
          if (!moving)
            return
          var dx = mouse.x + handle.x + mover.x - grabX
          var dy = mouse.y + handle.y + mover.y - grabY
          root.dragX = Math.max(0, Math.min(card.x + dx, root.screenW - card.width))
          root.dragY = Math.max(0, Math.min(card.y + dy, root.screenH - card.height))
        }

        onReleased: moving = false
        onCanceled: moving = false
      }
    }
  }
}