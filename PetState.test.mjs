import { test } from "node:test"
import assert from "node:assert/strict"
import { loadLib } from "./loadLib.mjs"

const PetState = loadLib("./PetState.js", [
  "moodFor", "flavor", "defaultState", "parseState", "normalizeNickname",
  "roamNotice", "homeNotice", "DEFAULT_NICKNAME"
])

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
  assert.equal(mood({ lastMove: NOW - 60001 }), "sleepy")
  assert.equal(mood({ lastMove: NOW - 59999 }), "idle")
})

test("a click shows happy briefly, then the glance takes over", () => {
  assert.equal(mood({ lastClick: NOW - 100, lastGlance: NOW }), "happy")
  assert.equal(mood({ lastClick: NOW - 1001, lastGlance: NOW }), "curious")
})

test("curious lasts as long as CursorTracker holds the look", () => {
  assert.equal(mood({ lastGlance: NOW - 4999 }), "curious")
  assert.equal(mood({ lastGlance: NOW - 5000 }), "idle")
})

test("every mood has a line, named and plain", () => {
  for (const id of ["idle", "curious", "sleepy", "happy", "night"]) {
    assert.ok(PetState.flavor(id, "Bolt", 1))
    assert.match(PetState.flavor(id, "Bolt", 0), /Bolt/)
  }
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

test("a fresh pet starts unmuted", () => {
  assert.equal(PetState.defaultState().muted, false)
})

test("a saved state round-trips, and a bad one falls back to the defaults", () => {
  const saved = PetState.parseState('{"nickname":"  bo  bo ","lastClick":42,"muted":true,"roaming":true}')
  assert.equal(saved.nickname, "bo bo")
  assert.equal(saved.lastClick, 42)
  assert.equal(saved.muted, true)
  assert.equal(saved.roaming, true)

  for (const raw of ["", "{", "null", "[]"])
    assert.deepEqual(PetState.parseState(raw).nickname, PetState.DEFAULT_NICKNAME)

  // An older state file has neither field, so the pet is heard and stays home.
  assert.equal(PetState.parseState('{"nickname":"bo"}').muted, false)
  assert.equal(PetState.parseState('{"nickname":"bo"}').roaming, false)
})

test("the roam notices name the pet, default included", () => {
  assert.match(PetState.roamNotice("Bolt"), /^Bolt /)
  assert.match(PetState.homeNotice("Bolt"), /^Bolt /)
  assert.match(PetState.roamNotice(""), new RegExp("^" + PetState.DEFAULT_NICKNAME + " "))
})
