import QtQuick
import QtCore
import QtQuick.Window
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "PetState.js" as PetState
import "Games.js" as Games

// The bar eyes and the popup live in one Panel-rooted entry point: the bar host
// wires `bar`/`settings` into the widget it instantiates, and only that
// instance's PanelController can show a popup.
Panel {
  id: root
  moduleName: "vdsabev.omagotchi"
  ipcTarget: "vdsabev.omagotchi"

  property bool blink: false
  property real lastClickMs: 0
  property string mood: "idle"
  property string nickname: PetState.DEFAULT_NICKNAME
  property string hatchedIso: new Date().toISOString()
  property bool soundMuted: false
  // Out for a walk beside the bar. Per-widget, so the robot roams on the
  // screen whose popup sent it out.
  property bool roaming: false
  property bool restored: false
  readonly property bool editingName: panel.editingName
  // Re-drawn per mood change, so the flavor line does not flicker between the
  // plain and the named variant while the mood holds.
  property real flavorRoll: 1
  property var extraGames: []
  property var pluginState: ({})
  // A short message that takes over the flavor line: install and launch news.
  property string notice: ""

  readonly property var games: Games.allGames(root.extraGames)

  readonly property string barPosition: bar ? bar.position : "top"
  readonly property bool verticalBar: bar ? bar.vertical : false
  readonly property color themeFg: bar ? bar.foreground : Color.foreground
  readonly property color themeBg: bar ? bar.background : Qt.rgba(0.05, 0.05, 0.07, 1)
  readonly property color themeAccent: Color.accent
  readonly property string contentFontFamily: bar ? bar.fontFamily : Style.font.family

  // Every bar gets its own copy of the widget, so an unprompted sound would
  // play once per monitor, in unison. The copy on the first screen takes them.
  readonly property bool soundLead: {
    var window = root.QsWindow ? root.QsWindow.window : null
    var screens = Quickshell.screens
    return !window || !window.screen || !screens.length || window.screen === screens[0]
  }

  implicitWidth: verticalBar ? Style.bar.iconSlot : 36
  implicitHeight: verticalBar ? 28 : (bar ? bar.barSize : 26)

  readonly property string flavorText: root.notice || PetState.flavor(root.mood, root.nickname, root.flavorRoll)

  function say(text) {
    root.notice = text
    noticeTimer.restart()
  }

  onMoodChanged: root.flavorRoll = Math.random()

  function tickMood() {
    root.mood = PetState.moodFor(Date.now(), tracker.lastMoveMs, root.lastClickMs, new Date().getHours(), tracker.lastGlanceMs)
  }

  function persistState() {
    stateFile.setText(JSON.stringify({
      hatched: root.hatchedIso,
      lastClick: root.lastClickMs,
      muted: root.soundMuted,
      roaming: root.roaming,
      nickname: root.nickname
    }, null, 2))
  }

  // Unmuting plays the popup sound back, so the button confirms itself.
  function toggleMute() {
    root.soundMuted = !root.soundMuted
    root.persistState()
    if (!root.soundMuted)
      soundEngine.play("beep")
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
    interval: 200
    running: true
    repeat: true
    onTriggered: {
      tracker.setAnchor(hit)
      root.tickMood()
    }
  }

  Timer {
    interval: 4000
    running: true
    repeat: true
    onTriggered: {
      interval = 2000 + Math.random() * 6000
      root.blink = true
      if (root.opened && Math.random() < 0.3)
        soundEngine.play("whir")
      blinkOff.start()
    }
  }

  Timer {
    id: noticeTimer
    interval: 8000
    onTriggered: root.notice = ""
  }

  Timer {
    id: blinkOff
    interval: 200
    onTriggered: root.blink = false
  }

  FileView {
    id: stateFile
    path: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.config/omagotchi/state.json"
    blockLoading: true
    // A sibling bar writing the file is how a mute reaches this one.
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
      var s = PetState.parseState(typeof text === "function" ? text() : text)
      root.hatchedIso = s.hatched
      root.nickname = s.nickname
      root.lastClickMs = s.lastClick
      root.soundMuted = s.muted
      // Patrol is per-widget once the shell is up, so only the first read of
      // the file restores it; a sibling bar's write must not send this one out.
      if (!root.restored) {
        root.restored = true
        root.roaming = s.roaming
      }
    }
  }

  FileView {
    id: gamesFile
    path: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.config/omagotchi/games.json"
    printErrors: false
    onLoaded: root.extraGames = Games.parseGamesFile(typeof text === "function" ? text() : text)
  }

  // Which game plugins are installed can change while the shell runs, so the
  // list is re-read every time the popup opens.
  Process {
    id: pluginList
    command: ["omarchy", "plugin", "list", "--json"]
    stdout: StdioCollector {
      onStreamFinished: root.pluginState = Games.pluginState(text)
    }
  }

  onOpenedChanged: if (root.opened) {
    pluginList.running = true
    soundEngine.play("beep")
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
      BarBot {
        anchors.fill: parent
        lookX: tracker.lookX
        lookY: tracker.lookY
        blink: root.blink
        alert: tracker.tracking
        sleepy: root.mood === "sleepy" || root.mood === "night"
        rimColor: root.themeFg
        accent: root.themeAccent
        dark: root.themeBg
        chassis: Qt.rgba(root.themeFg.r, root.themeFg.g, root.themeFg.b, 0.12)
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

  function toggleRoam() {
    root.roaming = !root.roaming
    root.persistState()
    soundEngine.play("roll")
    root.say(root.roaming ? PetState.roamNotice(root.nickname) : PetState.homeNotice(root.nickname))
  }

  readonly property var hostWindow: root.QsWindow ? root.QsWindow.window : null

  RoamWindow {
    visible: root.roaming
    screen: root.hostWindow ? root.hostWindow.screen : null
    barPos: root.barPosition
    barThickness: root.hostWindow
      ? (root.verticalBar ? root.hostWindow.width : root.hostWindow.height) : 0
    themeFg: root.themeFg
    themeBg: root.themeBg
    themeAccent: root.themeAccent
    lookX: tracker.lookX
    lookY: tracker.lookY
    blink: root.blink
    alert: tracker.tracking
    sleepy: (root.mood === "sleepy" || root.mood === "night") && !tracker.tracking
    mood: root.mood
    onPoked: {
      soundEngine.play("whir")
      root.blink = true
      blinkOff.restart()
    }
    onLaunched: soundEngine.play("launch")
    onLanded: soundEngine.play("land")
    // Lighter and higher than the landing, so a wall reads as a glancing knock.
    onBumped: soundEngine.play("land", 140, 140, 0.22)
  }

  SoundEngine {
    id: soundEngine
    muted: root.soundMuted
  }

  PowerWatcher {
    enabled: root.soundLead
    onPluggedIn: soundEngine.play("charge")
    onUnplugged: soundEngine.play("unplug")
  }

  PetPanel {
    id: panel
    anchorItem: hit
    bar: root.bar
    open: root.opened
    editingName: nameField.editing
    focusTarget: keyCatcher
    contentWidth: Style.space(364)
    contentHeight: stage.implicitHeight + Style.space(20)
    onCloseRequested: root.close()

    titleItem: NicknameField {
      id: nameField
      width: parent.width
      nickname: root.nickname
      textColor: root.themeAccent
      fontFamily: root.contentFontFamily
      onCommit: function(name) {
        root.nickname = PetState.normalizeNickname(name)
        root.persistState()
      }
      onEditFinished: keyCatcher.forceActiveFocus()
    }
    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: if (!root.editingName) root.close()
      onActivateRequested: if (!root.editingName) root.close()
      onTabRequested: function(direction) {
        var from = keyCatcher.Window.activeFocusItem || keyCatcher
        var next = from.nextItemInFocusChain(direction > 0)
        if (next)
          next.forceActiveFocus()
      }

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
        spacing: Style.space(10)
        width: parent.width - Style.space(16)

        Robot {
          width: parent.width
          height: 180
          lookX: tracker.lookX
          lookY: tracker.lookY
          blink: root.blink
          alert: tracker.tracking
          sleepy: (root.mood === "sleepy" || root.mood === "night") && !tracker.tracking
          mood: root.mood
          accent: root.themeAccent
          yellow: root.themeFg
          chassis: Qt.rgba(root.themeFg.r, root.themeFg.g, root.themeFg.b, 0.12)
          dark: root.themeBg
        }

        Row {
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: Style.space(12)

          // Mute for the pet's own sounds only. The speaker glyphs sit outside
          // Unicode, so they need the bar's Nerd Font.
          Button {
            anchors.verticalCenter: parent.verticalCenter
            iconText: root.soundMuted ? "󰝟" : "󰕾"
            iconSize: Style.font.body
            focusable: true
            foreground: root.themeFg
            fontFamily: root.contentFontFamily
            opacity: root.soundMuted ? 0.5 : 1
            tooltipText: root.soundMuted ? "Unmute " + root.nickname : "Mute " + root.nickname
            onClicked: root.toggleMute()
          }

          GameStrip {
            anchors.verticalCenter: parent.verticalCenter
            games: root.games
            plugins: root.pluginState
            foreground: root.themeFg
            fontFamily: root.contentFontFamily
            onNotice: function(text) { root.say(text) }
            onLaunched: root.close()
            onRefreshRequested: pluginList.running = true
          }

          Button {
            anchors.verticalCenter: parent.verticalCenter
            text: root.roaming ? "Recall" : "Patrol"
            focusable: true
            bordered: true
            foreground: root.themeFg
            fontFamily: root.contentFontFamily
            fontSize: Style.font.bodySmall
            tooltipText: root.roaming
              ? "Recall " + root.nickname + " to the bar"
              : "Send " + root.nickname + " on patrol along the bar"
            onClicked: root.toggleRoam()
          }
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
