import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Commons
import qs.Ui

// Overlay popup centered on the bar icon and pinned against the bar. A click
// outside the card, or Escape, dismisses it.
PanelWindow {
  id: root

  required property Item anchorItem
  required property QtObject bar
  property bool open: false
  property int contentWidth: Style.space(364)
  property int contentHeight: Style.space(200)
  property int padding: Style.spacing.popupPadding
  property int gap: Style.gapsOut
  property Item focusTarget: null
  // The card decides whether a name is being typed; the widget reads it back to
  // keep Enter and Escape away from the close handlers.
  property bool editingName: false

  default property alias contentItem: contentHolder.children
  property alias titleItem: titleHolder.children

  // The title row overlays the card and anchors to its edge, ignoring the card
  // padding, so the content clears whichever of the two reaches lower.
  readonly property real titleBarHeight: Style.space(8) + titleHolder.height + Style.space(8)

  signal closeRequested()

  readonly property var anchorWindow: anchorItem ? anchorItem.QsWindow.window : null
  readonly property string barPos: bar ? bar.position : "top"
  readonly property bool barVertical: barPos === "left" || barPos === "right"
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
  // The card's own size, title row included, so it lands flush against the bar.
  readonly property real cardW: contentWidth
  readonly property real cardH: card ? card.height : contentHeight

  readonly property point cardOrigin: {
    if (!anchorItem || !bar) return Qt.point(gap, gap)
    var x = 0, y = 0
    if (barVertical) {
      x = barPos === "left" ? barW + gap : screenW - barW - cardW - gap
      y = anchorPos.y + anchorH / 2 - cardH / 2
    } else {
      x = anchorPos.x + anchorW / 2 - cardW / 2
      y = barPos === "top" ? barH + gap : screenH - barH - cardH - gap
    }
    x = Math.max(gap, Math.min(x, screenW - cardW - gap))
    y = Math.max(gap, Math.min(y, screenH - cardH - gap))
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

  mask: Region { item: card }

  // Clicking anywhere outside the card clears Hyprland's focus grab, which is
  // how a click on the desktop reaches us at all.
  HyprlandFocusGrab {
    active: root.open
    windows: root.anchorWindow ? [root, root.anchorWindow] : [root]
    onCleared: root.closeRequested()
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
    x: root.cardOrigin.x
    y: root.cardOrigin.y
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

    Item {
      id: titleHolder
      anchors.top: parent.top
      anchors.topMargin: Style.space(8)
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.leftMargin: Style.space(8)
      anchors.rightMargin: Style.space(8)
      height: childrenRect.height
    }
  }
}
