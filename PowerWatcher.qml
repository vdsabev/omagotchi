import QtQuick
import Quickshell.Services.UPower

// UPower resolves `onBattery` over DBus after the shell has already started, so
// the first value it reports is state, not an event - without the settle delay
// every login would play a sound.
Item {
  id: root

  // One bar instance owns the sounds; see BarWidget.soundLead.
  property bool enabled: true

  signal pluggedIn()
  signal unplugged()

  readonly property bool onBattery: UPower.onBattery
  property bool armed: false

  onOnBatteryChanged: {
    if (!root.armed || !root.enabled)
      return
    if (root.onBattery)
      root.unplugged()
    else
      root.pluggedIn()
  }

  Timer {
    interval: 3000
    running: true
    onTriggered: root.armed = true
  }
}
