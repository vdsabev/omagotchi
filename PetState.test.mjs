// PetState.js is a QML library, so it has no exports. Evaluate it and pull the
// functions out of the module scope.
import { test } from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"

const src = readFileSync(new URL("./PetState.js", import.meta.url), "utf8")
  .replace(".pragma library", "")
const PetState = new Function(src + "\nreturn { moodFor, icon, flavor, defaultState, normalizeNickname, DEFAULT_NICKNAME }")()

const NOW = 1000000
const mood = (o = {}) => PetState.moodFor(
  NOW,
  o.lastMove ?? NOW,
  o.lastClick ?? 0,
  o.hour ?? 12,
  o.lastGlance ?? 0
)

test("night wins over everything", () => {
  assert.equal(mood({ hour: 3, lastClick: NOW, lastGlance: NOW }), "night")
  assert.equal(mood({ hour: 22 }), "night")
  assert.equal(mood({ hour: 7 }), "idle")
})

test("a long still cursor sleeps", () => {
  assert.equal(mood({ lastMove: NOW - 45001 }), "sleepy")
  assert.equal(mood({ lastMove: NOW - 44999 }), "idle")
})

test("a click shows happy briefly, then the glance takes over", () => {
  assert.equal(mood({ lastClick: NOW - 100, lastGlance: NOW }), "happy")
  assert.equal(mood({ lastClick: NOW - 600, lastGlance: NOW }), "curious")
})

test("curious lasts as long as CursorTracker holds the look", () => {
  assert.equal(mood({ lastGlance: NOW - 4999 }), "curious")
  assert.equal(mood({ lastGlance: NOW - 5000 }), "idle")
})

test("every mood has an icon and a line, named and plain", () => {
  for (const id of ["idle", "curious", "sleepy", "happy", "night"]) {
    assert.ok(PetState.icon(id))
    assert.ok(PetState.flavor(id, "Bolt", 1))
    assert.match(PetState.flavor(id, "Bolt", 0), /Bolt/)
  }
  assert.equal(PetState.icon("nonsense"), PetState.icon("idle"))
  assert.equal(PetState.flavor("nonsense", "Bolt", 1), PetState.flavor("idle", "Bolt", 1))
})

test("the name only turns up on a low roll", () => {
  assert.doesNotMatch(PetState.flavor("idle", "Bolt", 0.9), /Bolt/)
  assert.doesNotMatch(PetState.flavor("idle", "Bolt", undefined), /Bolt/)
  assert.doesNotMatch(PetState.flavor("idle", "", 0), /undefined/)
})

test("a nickname is trimmed, squeezed, capped, and never empty", () => {
  assert.equal(PetState.normalizeNickname("  Bolt  "), "Bolt")
  assert.equal(PetState.normalizeNickname("Little\n Bolt"), "Little Bolt")
  assert.equal(PetState.normalizeNickname("   "), PetState.DEFAULT_NICKNAME)
  assert.equal(PetState.normalizeNickname(null), PetState.DEFAULT_NICKNAME)
  assert.equal(PetState.normalizeNickname("x".repeat(40)).length, 24)
  assert.equal(PetState.defaultState().nickname, PetState.DEFAULT_NICKNAME)
})
