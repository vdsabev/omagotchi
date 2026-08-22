.pragma library

// The three always-listed games, and the shape every extra game must match:
// `id`, `label`, `kind`, `command` (tui/gui) or `install` (plugin, a git URL),
// and an optional `icon`, since the strip shows icons and keeps the label for
// the tooltip.
var BUILTIN = [
  {
    id: "jankeesvw.omasweeper",
    label: "Omasweeper",
    icon: "\u{1F4A3}",
    kind: "plugin",
    install: "https://github.com/jankeesvw/omasweeper.git"
  },
  {
    id: "nosignal.quattrolitaire",
    label: "Quattrolitaire",
    icon: "\u{1F0CF}",
    kind: "plugin",
    install: "https://github.com/28allday/Quattrolitaire.git"
  },
  {
    id: "terminal.tetris",
    label: "Tetris",
    icon: "\u{1F9F1}",
    kind: "plugin",
    install: "https://github.com/Ycaro-Oleg/omarchy-my-tetris.git"
  }
]

var FALLBACK_ICON = "\u{1F3AE}"

var KINDS = ["plugin", "tui", "gui"]

function normalizeGame(raw) {
  if (!raw || typeof raw !== "object")
    return null
  var id = String(raw.id || "").trim()
  var kind = String(raw.kind || "").trim()
  if (!id || KINDS.indexOf(kind) < 0)
    return null
  var command = String(raw.command || "").trim()
  if (kind !== "plugin" && !command)
    return null
  return {
    id: id,
    label: String(raw.label || "").trim() || id,
    kind: kind,
    icon: String(raw.icon || "").trim() || FALLBACK_ICON,
    command: command,
    install: String(raw.install || "").trim()
  }
}

// Extras keep their file order after the builtins; a repeated id is dropped so
// games.json cannot shadow a builtin button.
function allGames(extra) {
  var out = BUILTIN.map(function(g) { return normalizeGame(g) })
  var seen = {}
  out.forEach(function(g) { seen[g.id] = true })
  ;(Array.isArray(extra) ? extra : []).forEach(function(raw) {
    var g = normalizeGame(raw)
    if (g && !seen[g.id]) {
      seen[g.id] = true
      out.push(g)
    }
  })
  return out
}

function parseGamesFile(text) {
  try {
    var parsed = JSON.parse(text)
    return Array.isArray(parsed) ? parsed : (parsed && parsed.games) || []
  } catch (e) {
    return []
  }
}

// id → enabled, because `toggle` on an installed but disabled plugin exits 0
// and does nothing.
function pluginState(listJson) {
  var state = {}
  try {
    JSON.parse(listJson).forEach(function(p) { state[p.id] = !!p.enabled })
  } catch (e) {}
  return state
}

function isMissing(game, state) {
  return game.kind === "plugin" && !((state || {}).hasOwnProperty(game.id))
}

function isDisabled(game, state) {
  return game.kind === "plugin" && (state || {})[game.id] === false
}

// Exit 127 from the wrapper means the game's own binary is not on PATH, which
// the caller turns into a flavor line instead of a silent no-op.
function launchCommand(game) {
  if (game.kind === "plugin")
    return ["omarchy-shell", "shell", "toggle", game.id]
  var binary = game.command.split(/\s+/)[0]
  var run = game.kind === "tui"
    ? '"${TERMINAL:-kitty}" -e ' + game.command
    : game.command
  return ["bash", "-lc", "command -v " + binary + " >/dev/null 2>&1 || exit 127; exec uwsm-app -- " + run]
}

function installCommand(game) {
  return ["omarchy", "plugin", "add", game.install, "--yes"]
}

// `add --enable` does not reliably stick, so enabling is always its own step.
function enableCommand(game) {
  return ["omarchy", "plugin", "enable", game.id]
}

// The whole click decision, so the strip stays a thin dispatcher: what a click
// on `game` should do, given the plugin state and the click context. `busy`
// blocks everything while an install/enable is in flight; `confirmed` means
// the game was already offered once and clicked again. Copy lives here so the
// strip and the tests agree on the wording.
function actionFor(game, state, opts) {
  opts = opts || {}
  if (opts.busy)
    return { action: "ignore" }
  if (isMissing(game, state)) {
    if (!game.install)
      return { action: "notice", notice: game.label + " is not installed." }
    if (!opts.confirmed)
      return { action: "confirm", notice: "Install " + game.label + "? Click again." }
    return { action: "install", notice: "Fetching " + game.label + "…" }
  }
  if (isDisabled(game, state))
    return { action: "enable" }
  return { action: "launch" }
}

function tooltipFor(game, state, busyId) {
  if (game.id === busyId)
    return "Fetching " + game.label + "…"
  if (isMissing(game, state))
    return "Install " + game.label
  return game.label
}
