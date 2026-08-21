import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "PetState.js" as PetState

// The bar eyes and the popup live in one Panel-rooted entry point: the bar host
// wires `bar`/`settings` into the widget it instantiates, and only that
// instance's PanelController can show a popup.
Panel {
  id: root
  moduleName: "omagotchi.pet"
  ipcTarget: "omagotchi.pet"

  property bool blink: false
  property real lastClickMs: 0
  property string mood: "idle"
  property string nickname: PetState.DEFAULT_NICKNAME
  property string hatchedIso: new Date().toISOString()
  readonly property bool editingName: panel.editingName
  // Re-drawn per mood change, so the flavor line does not flicker between the
  // plain and the named variant while the mood holds.
  property real flavorRoll: 1

  readonly property bool verticalBar: bar ? bar.vertical : false
  readonly property color themeFg: bar ? bar.foreground : Color.foreground
  readonly property color themeBg: bar ? bar.background : Qt.rgba(0.05, 0.05, 0.07, 1)
  readonly property color themeAccent: Color.accent
  readonly property string contentFontFamily: bar ? bar.fontFamily : Style.font.family

  implicitWidth: verticalBar ? Style.bar.iconSlot : 36
  implicitHeight: verticalBar ? 28 : (bar ? bar.barSize : 26)

  readonly property string flavorText: PetState.flavor(root.mood, root.nickname, root.flavorRoll)

  onMoodChanged: root.flavorRoll = Math.random()

  function tickMood() {
    root.mood = PetState.moodFor(Date.now(), tracker.lastMoveMs, root.lastClickMs, new Date().getHours(), tracker.lastGlanceMs)
  }

  function persistState() {
    stateFile.setText(JSON.stringify({
      hatched: root.hatchedIso,
      lastClick: root.lastClickMs,
      nickname: root.nickname
    }, null, 2))
  }

  function persistClick() {
    root.lastClickMs = Date.now()
    root.mood = "happy"
    root.persistState()
  }

  CursorTracker {
    id: tracker
    dozing: root.mood === "sleepy" || root.mood === "night"
  }

  Timer {
    interval: 120
    running: true
    repeat: true
    onTriggered: {
      tracker.setAnchor(hit)
      root.tickMood()
    }
  }

  Timer {
    interval: 3200
    running: true
    repeat: true
    onTriggered: {
      interval = 2200 + Math.random() * 4000
      root.blink = true
      blinkOff.start()
    }
  }

  Timer {
    id: blinkOff
    interval: 130
    onTriggered: root.blink = false
  }

  FileView {
    id: stateFile
    path: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.config/omagotchi/state.json"
    blockLoading: true
    onLoaded: {
      try {
        var raw = typeof text === "function" ? text() : text
        var s = JSON.parse(raw)
        if (s.hatched) root.hatchedIso = s.hatched
        if (s.nickname) root.nickname = PetState.normalizeNickname(s.nickname)
        if (s.lastClick) root.lastClickMs = s.lastClick
      } catch (e) {}
    }
  }

  Process {
    id: ensureDir
    command: ["mkdir", "-p", StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.config/omagotchi"]
    running: true
    onExited: {
      if (!stateFile.loaded)
        stateFile.setText(JSON.stringify(PetState.defaultState(), null, 2))
    }
  }

  // The bar dispatches clicks to registered targets, so the pet must sit in a
  // WidgetButton — a plugin's own MouseArea never sees bar input.
  BarIconButton {
    id: hit
    anchors.fill: parent
    bar: root.bar
    tooltipText: root.flavorText

    iconComponent: Component {
      Eyes {
        anchors.fill: parent
        lookX: tracker.lookX
        lookY: tracker.lookY
        blink: root.blink
        alert: tracker.tracking
        sleepy: root.mood === "sleepy" || root.mood === "night"
        rimColor: root.themeFg
        pupilColor: root.themeAccent
        wellColor: root.themeBg
        bodyColor: Qt.rgba(root.themeFg.r, root.themeFg.g, root.themeFg.b, 0.12)
      }
    }

    onPressed: function(button) {
      if (button === Qt.RightButton) {
        if (root.bar)
          root.bar.showTooltip(hit, root.flavorText)
        return
      }
      root.persistClick()
      root.toggle()
    }
  }

  PetPanel {
    id: panel
    anchorItem: hit
    bar: root.bar
    open: root.opened
    editingName: nameField.editing
    focusTarget: keyCatcher
    contentWidth: Style.space(280)
    contentHeight: stage.implicitHeight + Style.space(40)
    onCloseRequested: root.close()

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: if (!root.editingName) root.close()
      onActivateRequested: if (!root.editingName) root.close()

      // A click anywhere else in the card ends the edit, which commits the name.
      MouseArea {
        anchors.fill: parent
        enabled: nameField.editing
        onPressed: keyCatcher.forceActiveFocus()
      }

      Column {
        id: stage
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Style.space(8)
        spacing: Style.space(10)
        width: parent.width - Style.space(16)

        NicknameField {
          id: nameField
          anchors.horizontalCenter: parent.horizontalCenter
          width: Math.min(parent.width, Style.space(200))
          nickname: root.nickname
          textColor: root.themeAccent
          fontFamily: root.contentFontFamily
          onCommit: function(name) {
            root.nickname = PetState.normalizeNickname(name)
            root.persistState()
          }
          onEditFinished: keyCatcher.forceActiveFocus()
        }

        Text {
          width: parent.width
          horizontalAlignment: Text.AlignHCenter
          text: PetState.icon(root.mood) + " " + root.mood.toUpperCase()
          color: Qt.darker(root.themeFg, 1.6)
          font.family: root.contentFontFamily
          font.pixelSize: Style.font.caption
          font.letterSpacing: 2
        }

        Robot {
          width: parent.width
          height: 180
          lookX: tracker.lookX
          lookY: tracker.lookY
          blink: root.blink
          alert: tracker.tracking
          sleepy: root.mood === "sleepy" || root.mood === "night"
          mood: root.mood
          accent: root.themeAccent
          yellow: root.themeFg
          chassis: Qt.rgba(root.themeFg.r, root.themeFg.g, root.themeFg.b, 0.12)
          dark: root.themeBg
        }

        Text {
          width: parent.width
          horizontalAlignment: Text.AlignHCenter
          wrapMode: Text.WordWrap
          text: root.flavorText
          color: root.themeFg
          font.family: root.contentFontFamily
          font.pixelSize: Style.font.bodySmall
          opacity: 0.85
        }
      }
    }
  }
}
