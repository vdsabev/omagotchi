import QtQuick
import Quickshell

Item {
  id: root

  readonly property string binDir: Qt.resolvedUrl(".").toString().replace(/^file:\/\//, "")

  function play(type, freq, dur, vol) {
    var name = type || "beep"
    var script = root.binDir + "bin/" + name + ".sh"
    var args = ["sh", script]
    if (freq !== undefined) args.push(String(freq))
    if (dur !== undefined) args.push(String(dur))
    if (vol !== undefined) args.push(String(vol))
    Quickshell.execDetached(args)
  }
}
