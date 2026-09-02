import { test } from "node:test"
import assert from "node:assert/strict"
import { loadLib } from "./loadLib.mjs"

const Games = loadLib("./Games.js", [
  "BUILTIN", "allGames", "parseGamesFile", "pluginState", "isMissing",
  "isDisabled", "launchCommand", "installCommand", "enableCommand", "normalizeGame",
  "actionFor", "tooltipFor"
])

test("the builtins are always listed", () => {
  const ids = Games.allGames([]).map((g) => g.id)
  assert.deepEqual(ids, Games.BUILTIN.map((g) => g.id))
})

test("extras keep their order after the builtins", () => {
  const games = Games.allGames([
    { id: "a", label: "A", kind: "tui", command: "a" },
    { id: "b", kind: "gui", command: "b --full" }
  ])
  assert.deepEqual(games.slice(Games.BUILTIN.length).map((g) => [g.id, g.label]), [["a", "A"], ["b", "b"]])
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
  const game = Games.allGames([{ id: "a", kind: "tui", command: "a" }])[Games.BUILTIN.length]
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
  const tui = Games.launchCommand(Games.allGames([{ id: "a", kind: "tui", command: "nethack -x" }])[Games.BUILTIN.length])
  assert.match(tui[2], /command -v nethack .*\$\{TERMINAL:-kitty\}" -e nethack -x/)
  const gui = Games.launchCommand(Games.allGames([{ id: "b", kind: "gui", command: "supertux2" }])[Games.BUILTIN.length])
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

test("normalizeGame trims fields and fills fallbacks", () => {
  const g = Games.normalizeGame({
    id: "  spaced.id  ", kind: " gui ", command: "  app --fast  ",
    label: "   ", icon: "  ", install: " git@host:repo.git "
  })
  assert.deepEqual(g, {
    id: "spaced.id",
    label: "spaced.id",
    kind: "gui",
    icon: "\u{1F3AE}",
    command: "app --fast",
    install: "git@host:repo.git"
  })
})

test("pluginState survives junk and coerces enabled to booleans", () => {
  assert.deepEqual(Games.pluginState("not json"), {})
  const state = Games.pluginState('[{"id":"a","enabled":true},{"id":"b"},{"id":"c","enabled":"yes"},{"id":"d","enabled":false}]')
  assert.deepEqual(state, { a: true, b: false, c: true, d: false })
})

test("the launch wrapper checks the binary before execing uwsm-app", () => {
  const tui = Games.launchCommand({ id: "a", kind: "tui", command: "nethack -x" })
  assert.match(tui[2], /^command -v nethack >\/dev\/null 2>&1 \|\| exit 127;/)
  assert.ok(tui[2].indexOf("exit 127") < tui[2].indexOf("exec uwsm-app"))
})

// The full click decision, as GameStrip.activate wires it up.
test("a busy strip ignores every click and keeps its pending state", () => {
  const game = { id: "a", label: "A", kind: "plugin", install: "git@x" }
  assert.deepEqual(Games.actionFor(game, {}, { busy: true }), { action: "ignore" })
  assert.deepEqual(Games.actionFor(game, {}, { busy: true, confirmed: true }), { action: "ignore" })
})

test("a missing plugin without an install URL just reports", () => {
  const game = { id: "a", label: "A", kind: "plugin" }
  assert.deepEqual(
    Games.actionFor(game, {}),
    { action: "notice", notice: "A is not installed." }
  )
})

test("a missing plugin asks once, then installs on the second click", () => {
  const [sweeper] = Games.allGames([])
  assert.deepEqual(
    Games.actionFor(sweeper, {}, {}),
    { action: "confirm", notice: "Install Omasweeper? Click again." }
  )
  assert.deepEqual(
    Games.actionFor(sweeper, {}, { confirmed: true }),
    { action: "install", notice: "Fetching Omasweeper…" }
  )
})

test("an installed plugin is enabled first; a live one launches right away", () => {
  const tetris = Games.allGames([])[2]
  assert.equal(Games.actionFor(tetris, { "terminal.tetris": false }, {}).action, "enable")
  assert.deepEqual(Games.actionFor(tetris, { "terminal.tetris": true }, {}), { action: "launch" })
})

test("a plugin absent from the list goes through the install flow", () => {
  const tetris = Games.allGames([])[2]
  assert.deepEqual(
    Games.actionFor(tetris, Games.pluginState(""), { confirmed: true }),
    { action: "install", notice: "Fetching Tetris…" }
  )
})

test("tui and gui games always launch", () => {
  const game = { id: "a", label: "A", kind: "gui", command: "a" }
  for (const state of [{}, { a: true }, { a: false }])
    assert.equal(Games.actionFor(game, state, {}).action, "launch")
})

test("tooltips carry the state: fetching while busy, install for the missing", () => {
  const [sweeper] = Games.allGames([])
  assert.equal(Games.tooltipFor(sweeper, {}, "jankeesvw.omasweeper"), "Fetching Omasweeper…")
  assert.equal(Games.tooltipFor(sweeper, {}, ""), "Install Omasweeper")
  assert.equal(Games.tooltipFor(sweeper, { "jankeesvw.omasweeper": true }, ""), "Omasweeper")
})
