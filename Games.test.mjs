// Games.js is a QML library, so it has no exports. Evaluate it and pull the
// functions out of the module scope.
import { test } from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"

const src = readFileSync(new URL("./Games.js", import.meta.url), "utf8")
  .replace(".pragma library", "")
const Games = new Function(src + "\nreturn { BUILTIN, allGames, parseGamesFile, pluginState, isMissing, isDisabled, launchCommand, installCommand, enableCommand }")()

test("the three builtins are always listed", () => {
  const ids = Games.allGames([]).map((g) => g.id)
  assert.deepEqual(ids, ["jankeesvw.omasweeper", "nosignal.quattrolitaire", "terminal.tetris"])
})

test("extras keep their order after the builtins", () => {
  const games = Games.allGames([
    { id: "a", label: "A", kind: "tui", command: "a" },
    { id: "b", kind: "gui", command: "b --full" }
  ])
  assert.deepEqual(games.slice(3).map((g) => [g.id, g.label]), [["a", "A"], ["b", "b"]])
})

test("malformed extras and builtin id clashes are dropped", () => {
  const extra = [
    null,
    { id: "no-kind" },
    { id: "bad-kind", kind: "wat" },
    { id: "no-command", kind: "tui" },
    { id: "terminal.tetris", kind: "gui", command: "impostor" }
  ]
  assert.equal(Games.allGames(extra).length, Games.BUILTIN.length)
})

test("games.json accepts a bare array or a games key, and survives junk", () => {
  assert.equal(Games.parseGamesFile('[{"id":"a"}]').length, 1)
  assert.equal(Games.parseGamesFile('{"games":[{"id":"a"}]}').length, 1)
  assert.deepEqual(Games.parseGamesFile("not json"), [])
})

test("a plugin is missing until it shows up in the plugin list", () => {
  const state = Games.pluginState('[{"id":"terminal.tetris","enabled":true}]')
  const [sweeper, , tetris] = Games.allGames([])
  assert.equal(Games.isMissing(tetris, state), false)
  assert.equal(Games.isMissing(sweeper, state), true)
})

// A disabled plugin ignores `toggle`, so it must be told apart from a live one.
test("an installed plugin that is switched off is not missing", () => {
  const state = Games.pluginState('[{"id":"terminal.tetris","enabled":false}]')
  const tetris = Games.allGames([])[2]
  assert.equal(Games.isMissing(tetris, state), false)
  assert.equal(Games.isDisabled(tetris, state), true)
})

test("a tui or gui game is never missing or disabled", () => {
  const game = Games.allGames([{ id: "a", kind: "tui", command: "a" }])[3]
  assert.equal(Games.isMissing(game, {}), false)
  assert.equal(Games.isDisabled(game, {}), false)
})

test("plugins launch through the shell", () => {
  assert.deepEqual(
    Games.launchCommand(Games.allGames([])[0]),
    ["omarchy-shell", "shell", "toggle", "jankeesvw.omasweeper"]
  )
})

test("a tui game gets a terminal, a gui game does not", () => {
  const tui = Games.launchCommand(Games.allGames([{ id: "a", kind: "tui", command: "nethack -x" }])[3])
  assert.match(tui[2], /command -v nethack .*\$\{TERMINAL:-kitty\}" -e nethack -x/)
  const gui = Games.launchCommand(Games.allGames([{ id: "b", kind: "gui", command: "supertux2" }])[3])
  assert.match(gui[2], /uwsm-app -- supertux2$/)
  assert.doesNotMatch(gui[2], /TERMINAL/)
})

test("installing a plugin needs no confirmation, and enabling is its own step", () => {
  const tetris = Games.allGames([])[2]
  assert.deepEqual(
    Games.installCommand(tetris),
    ["omarchy", "plugin", "add", "https://github.com/Ycaro-Oleg/omarchy-my-tetris.git", "--yes"]
  )
  assert.deepEqual(Games.enableCommand(tetris), ["omarchy", "plugin", "enable", "terminal.tetris"])
})

test("every game has an icon, extras falling back to a generic one", () => {
  const games = Games.allGames([{ id: "a.b", label: "A", kind: "gui", command: "a" }])
  assert.ok(games.every(g => g.icon))
  assert.equal(games.at(-1).icon, "\u{1F3AE}")
  assert.equal(games[0].icon, "\u{1F4A3}")
})
