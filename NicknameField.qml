import QtQuick
import qs.Commons
import qs.Ui
import "PetState.js" as PetState

// The pet's name: a focusable label that turns into a text field on Enter or a
// click. Enter keeps the name, Escape puts the old one back.
FocusScope {
  id: root

  required property string nickname
  property color textColor: Color.foreground
  property string fontFamily: Style.font.family
  readonly property bool editing: input.visible

  signal commit(string name)
  // The bar takes the focus back, so the focus ring does not stay on the name.
  signal editFinished()

  implicitHeight: label.implicitHeight + Style.space(6)
  activeFocusOnTab: true

  function startEdit() {
    input.text = root.nickname
    input.visible = true
    input.forceActiveFocus()
    input.selectAll()
  }

  function stopEdit() {
    input.visible = false
    root.editFinished()
  }

  // Enter reaches the scope after the field has taken it, so the guard keeps a
  // commit from re-opening the edit.
  Keys.onReturnPressed: if (!root.editing) root.startEdit()
  Keys.onEnterPressed: if (!root.editing) root.startEdit()

  Rectangle {
    anchors.fill: parent
    radius: Style.cornerRadius
    color: "transparent"
    border.width: root.activeFocus ? Math.max(1, Style.space(1)) : 0
    border.color: root.textColor
    opacity: root.editing ? 0.35 : 0.6
  }

  Text {
    id: label
    anchors.centerIn: parent
    visible: !root.editing
    text: root.nickname.toUpperCase()
    color: root.textColor
    font.family: root.fontFamily
    font.pixelSize: Style.font.body
    font.letterSpacing: 3
    font.bold: true

    MouseArea {
      anchors.fill: parent
      anchors.margins: -Style.space(4)
      cursorShape: Qt.PointingHandCursor
      onClicked: root.startEdit()
    }
  }

  TextInput {
    id: input
    visible: false
    anchors.centerIn: parent
    width: parent.width - Style.space(8)
    horizontalAlignment: TextInput.AlignHCenter
    maximumLength: PetState.MAX_NICKNAME
    color: root.textColor
    selectionColor: root.textColor
    selectedTextColor: Color.popups.background
    selectByMouse: true
    font.family: root.fontFamily
    font.pixelSize: Style.font.body
    font.letterSpacing: 3
    font.bold: true
    font.capitalization: Font.AllUppercase

    onAccepted: {
      root.commit(text)
      root.stopEdit()
    }

    Keys.onReturnPressed: function(event) { event.accepted = true; input.accepted() }
    Keys.onEnterPressed: function(event) { event.accepted = true; input.accepted() }

    Keys.onEscapePressed: function(event) {
      root.stopEdit()
      event.accepted = true
    }

    // Clicking away keeps what was typed; only Escape puts the old name back.
    onActiveFocusChanged: {
      if (!activeFocus && visible) {
        root.commit(text)
        root.stopEdit()
      }
    }
  }
}
