.pragma library

var DEFAULT_NICKNAME = "Omagotchi"
var MAX_NICKNAME = 24

var moods = {
  idle: { line: "Watching you work.", named: "{name} is watching you work.", icon: "\u{1F916}" },
  curious: { line: "Something moved. Interesting.", named: "Something moved. {name} noticed.", icon: "\u{1F440}" },
  sleepy: { line: "Idle circuits cooling down.", named: "{name} is cooling down.", icon: "\u{1F634}" },
  happy: { line: "You clicked. That was nice.", named: "{name} liked that click.", icon: "\u{1F60A}" },
  night: { line: "Night shift. I'll keep watch.", named: "{name} has the night shift.", icon: "\u{1F319}" }
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

// `roll` is a 0..1 draw from the caller, so the name only turns up now and then
// and the tests can pick the outcome.
function flavor(moodId, nickname, roll) {
  var m = moods[moodId] || moods.idle
  if (nickname && roll < 0.3)
    return m.named.replace("{name}", nickname)
  return m.line
}

function normalizeNickname(name) {
  var trimmed = String(name === undefined || name === null ? "" : name).replace(/\s+/g, " ").trim()
  return trimmed.slice(0, MAX_NICKNAME) || DEFAULT_NICKNAME
}

function defaultState() {
  return {
    hatched: new Date().toISOString(),
    lastClick: 0,
    nickname: DEFAULT_NICKNAME
  }
}
