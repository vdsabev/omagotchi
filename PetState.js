.pragma library

var DEFAULT_NICKNAME = "Omagotchi"
var MAX_NICKNAME = 24

var moods = {
  idle: { line: "Watching you work…", named: "{name} is watching you work", icon: "\u{1F916}" },
  curious: { line: "Something moved - curious…", named: "Something moved - {name} noticed", icon: "\u{1F440}" },
  sleepy: { line: "Idle circuits cooling down…", named: "{name} is cooling down", icon: "\u{1F634}" },
  happy: { line: "You clicked - that was nice ☺️", named: "{name} enjoyed that click", icon: "\u{1F60A}" },
  night: { line: "Night shift - I'll keep watch!", named: "{name} has the night shift", icon: "\u{1F319}" }
}

function moodFor(nowMs, lastMoveMs, lastClickMs, hour, lastGlanceMs) {
  if (hour < 7 || 22 <= hour)
    return "night"
  var idle = nowMs - lastMoveMs
  if (idle > 60000)
    return "sleepy"
  // A click wins for a moment, then the glance takes over: the cursor moves
  // right after a click, and otherwise happy would never be seen.
  if (lastClickMs > 0 && nowMs - lastClickMs < 1000)
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
    muted: false,
    nickname: DEFAULT_NICKNAME
  }
}

// The state file is hand-editable and shared by every bar instance, so a
// missing or malformed field falls back to its default instead of throwing.
function parseState(raw) {
  var state = defaultState()
  var s
  try {
    s = JSON.parse(raw)
  } catch (e) {
    return state
  }
  if (!s || typeof s !== "object")
    return state
  if (s.hatched) state.hatched = String(s.hatched)
  if (s.nickname) state.nickname = normalizeNickname(s.nickname)
  if (s.lastClick) state.lastClick = Number(s.lastClick) || 0
  state.muted = !!s.muted
  return state
}
