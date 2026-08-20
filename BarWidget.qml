import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "PetState.js" as PetState

BarWidget {
  id: root
  moduleName: "omagotchi.pet"

  property bool blink: false
  property real lastClickMs: 0
  property string mood: "watching"
  property string nickname: "W-E"

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false
  readonly property color themeFg: bar ? bar.foreground : Color.foreground
  readonly property color themeBg: bar ? bar.background : Qt.rgba(0.05, 0.05, 0.07, 1)
  readonly property color themeAccent: Color.accent

  function open() {
    if (panelLoader.item) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item) panelLoader.item.close()
  }

  function togglePanel() {
    if (panelLoader.item) panelLoader.item.toggle()
  }

  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = hit
    if ("hostWidget" in target) target.hostWidget = root
    if ("pet" in target) {
      target.pet = {
        lookX: tracker.lookX,
        lookY: tracker.lookY,
        blink: root.blink,
        sleepy: root.mood === "sleepy" || root.mood === "night",
        mood: root.mood,
        flavor: PetState.flavor(root.mood),
        accent: root.themeAccent,
        foreground: root.themeFg,
        background: root.themeBg,
        nickname: root.nickname
      }
    }
  }

  function tickMood() {
    var hour = new Date().getHours()
    root.mood = PetState.moodFor(Date.now(), tracker.lastMoveMs, root.lastClickMs, hour)
    injectPanel()
  }

  function persistClick() {
    root.lastClickMs = Date.now()
    root.mood = "happy"
    stateFile.setText(JSON.stringify({
      hatched: hatchedIso,
      lastClick: root.lastClickMs,
      nickname: root.nickname
    }, null, 2))
    injectPanel()
  }

  property string hatchedIso: new Date().toISOString()

  implicitWidth: vertical ? Style.bar.iconSlot : 36
  implicitHeight: vertical ? 28 : (bar ? bar.barSize : 26)

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  CursorTracker {
    id: tracker
  }

  Timer {
    interval: 120
    running: true
    repeat: true
    onTriggered: {
      if (hit)
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
      if (root.mood === "sleepy")
        return
      root.blink = true
      blinkOff.start()
    }
  }

  Timer {
    id: blinkOff
    interval: 90
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
        if (s.nickname) root.nickname = s.nickname
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

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  Item {
    id: hit
    anchors.fill: parent

    Eyes {
      anchors.centerIn: parent
      width: Math.min(parent.width - 4, 32)
      height: Math.min(parent.height - 4, 16)
      lookX: tracker.lookX
      lookY: tracker.lookY
      blink: root.blink
      sleepy: root.mood === "sleepy" || root.mood === "night"
      rimColor: root.themeFg
      pupilColor: root.themeAccent
      wellColor: root.themeBg
      bodyColor: Qt.rgba(root.themeFg.r, root.themeFg.g, root.themeFg.b, 0.12)
    }

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onPressed: function(mouse) {
        if (mouse.button === Qt.RightButton) {
          if (root.bar)
            root.bar.showTooltip(hit, PetState.flavor(root.mood))
          return
        }
        root.persistClick()
        root.togglePanel()
      }
      onReleased: {
        if (root.bar)
          root.bar.hideTooltip(hit)
      }
    }
  }
}
