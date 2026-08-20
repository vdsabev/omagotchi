.pragma library

var moods = {
  watching: { line: "Watching you work." },
  curious: { line: "Something moved. Interesting." },
  sleepy: { line: "Idle circuits cooling down." },
  happy: { line: "You clicked. That was nice." },
  night: { line: "Night shift. I'll keep watch." }
}

function moodFor(nowMs, lastMoveMs, lastClickMs, hour, lastGlanceMs) {
  if (lastClickMs > 0 && nowMs - lastClickMs < 8000)
    return "happy"
  if (hour < 7 || 22 <= hour)
    return "night"
  var idle = nowMs - lastMoveMs
  if (idle > 45000)
    return "sleepy"
  if (lastGlanceMs > 0 && nowMs - lastGlanceMs < 400)
    return "curious"
  return "watching"
}

function flavor(moodId) {
  return moods[moodId] ? moods[moodId].line : moods.watching.line
}

function defaultState() {
  return {
    hatched: new Date().toISOString(),
    lastClick: 0,
    nickname: "Omagotchi"
  }
}
