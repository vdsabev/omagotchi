.pragma library

var moods = {
  idle: { line: "Watching you work.", icon: "\u{1F916}" },
  curious: { line: "Something moved. Interesting.", icon: "\u{1F440}" },
  sleepy: { line: "Idle circuits cooling down.", icon: "\u{1F634}" },
  happy: { line: "You clicked. That was nice.", icon: "\u{1F60A}" },
  night: { line: "Night shift. I'll keep watch.", icon: "\u{1F319}" }
}

function moodFor(nowMs, lastMoveMs, lastClickMs, hour, lastGlanceMs) {
  if (hour < 7 || 22 <= hour)
    return "night"
  var idle = nowMs - lastMoveMs
  if (idle > 45000)
    return "sleepy"
  // A click wins for a moment, then the glance takes over: the cursor moves
  // right after a click, and otherwise happy would never be seen.
  if (lastClickMs > 0 && nowMs - lastClickMs < 600)
    return "happy"
  // Matches CursorTracker holdMs.
  if (lastGlanceMs > 0 && nowMs - lastGlanceMs < 5000)
    return "curious"
  return "idle"
}

function icon(moodId) {
  return moods[moodId] ? moods[moodId].icon : moods.idle.icon
}

function flavor(moodId) {
  return moods[moodId] ? moods[moodId].line : moods.idle.line
}

function defaultState() {
  return {
    hatched: new Date().toISOString(),
    lastClick: 0,
    nickname: "Omagotchi"
  }
}
