--[[
  extract-commands-f4e.lua — Extracteur du catalogue de commandes F-4E (Pilote)

  Cascade différente des deux autres modules : le F-4E charge d'abord
  Cockpit/devices.lua et command_defs.lua (comme F14BU), puis surtout
  Input/utils.lua, Input/bind_dsl.lua et Input/bind_categories.lua — c'est
  utils.lua qui définit `join_override` (fusion de deux tables de commandes
  par nom, utilisée ici au lieu du `join` du F4U-1D), et bind_categories.lua
  qui définit `categories`, `axis_categories` et `bind_templates` (utilisés
  par les binds Jester/désignation en fin de profil). Les fonctions `join`
  et `ignore_features` définies plus bas ne servent pas à ce module — elles
  restent présentes sans effet, pour ne pas diverger inutilement du script
  F4U-1D dont ce fichier est dérivé.

  N'extrait que le profil PILOTE (Saved Games\...\F-4E-45MC\, le seul dossier
  réel écrit par DCS en solo). Le profil F-4E-WSO existe côté module mais
  n'a pas de dossier Saved Games séparé observé — à revisiter si le mapping
  doit un jour couvrir le poste WSO en détail.

  Usage :
    "<DCS>\bin\luae.exe" tools\extract-commands-f4e.lua
]]

local CONFIG = {
  dcsRoot     = os.getenv("DCS_ROOT") or "J:/DCS World/",
  profile     = "Mods/aircraft/F-4E/Input/F-4E-Pilot/joystick/default.lua",
  outputJson  = "F4E/data/f4e-commands.json",
  gameCache   = "tools/game-commands-cache.lua",
  inputFolder = "F-4E-45MC",
  aircraftLabel = "F-4E Phantom II Pilot",
}

--=============================================================================
-- Environnement DCS simulé
--=============================================================================

function _(s) return s end

local rawLoadfile = loadfile
function loadfile(path, ...)
  if path and not path:match("^%a:[/\\]") and not path:match("^[/\\]") then
    path = CONFIG.dcsRoot .. path
  end
  return rawLoadfile(path, ...)
end

local function withFolder(path, fn)
  local previous = _G.folder
  _G.folder = path:match("^(.*[/\\])")
  local ok, result = pcall(fn)
  _G.folder = previous
  if not ok then error(result, 0) end
  return result
end

function dofile(path)
  return withFolder(path, function() return assert(loadfile(path))() end)
end

function external_profile(path)
  return withFolder(path, function() return assert(loadfile(path))() end)
end

function defaultDeviceAssignmentFor(assignmentName) return nil end

-- Fusionne des entrées de commandes dans une table existante (mutation en
-- place, comme le fait le moteur DCS réel).
function join(target, source)
  for _, v in ipairs(source or {}) do target[#target + 1] = v end
  return target
end

-- Retire d'une table de commandes celles dont le tag `features` recoupe la
-- liste donnée — c'est ainsi que le fichier commun (partagé par plusieurs
-- avions) est réduit aux systèmes que CET avion possède réellement.
function ignore_features(commands, ignoreList)
  local ignoreSet = {}
  for _, f in ipairs(ignoreList or {}) do ignoreSet[f] = true end
  local kept = {}
  for _, cmd in ipairs(commands) do
    local skip = false
    if cmd.features then
      for _, f in ipairs(cmd.features) do
        if ignoreSet[f] then skip = true; break end
      end
    end
    if not skip then kept[#kept + 1] = cmd end
  end
  for i = #commands, 1, -1 do commands[i] = nil end
  for i, cmd in ipairs(kept) do commands[i] = cmd end
end

local GAME_PREFIX = "GAMECMD:"
setmetatable(_G, {
  __index = function(_, key)
    if type(key) == "string" and key:match("^[iI]Command") then
      return GAME_PREFIX .. key
    end
    return nil
  end,
})

local function isGameCommand(value)
  return type(value) == "string" and value:sub(1, #GAME_PREFIX) == GAME_PREFIX
end

--=============================================================================
-- Calcul du hash
--=============================================================================

local function segment(value)
  if value == nil or isGameCommand(value) then return "nil" end
  return tostring(value)
end

local function keyHash(cmd)
  return "d"   .. segment(cmd.down)
      .. "p"   .. segment(cmd.pressed)
      .. "u"   .. segment(cmd.up)
      .. "cd"  .. segment(cmd.cockpit_device_id)
      .. "vd"  .. segment(cmd.value_down)
      .. "vp"  .. segment(cmd.value_pressed)
      .. "vu"  .. segment(cmd.value_up)
end

local function axisHash(cmd)
  return "a" .. segment(cmd.action) .. "cd" .. segment(cmd.cockpit_device_id)
end

--=============================================================================
-- Normalisation
--=============================================================================

local function categoryList(category)
  if category == nil then return {} end
  if type(category) == "string" then return {category} end
  local out = {}
  for _, c in ipairs(category) do
    if type(c) == "string" then out[#out + 1] = c end
  end
  return out
end

local function engineConstant(cmd)
  for _, field in ipairs({"down", "pressed", "up", "action"}) do
    if isGameCommand(cmd[field]) then
      return cmd[field]:sub(#GAME_PREFIX + 1)
    end
  end
  return nil
end

local gameHashes = {}
do
  local chunk = rawLoadfile(CONFIG.gameCache)
  if chunk then gameHashes = chunk() or {} end
end

local function collect(commands, kind, hashFn)
  local out = {}
  for _, cmd in ipairs(commands) do
    if cmd.name then
      local constant = engineConstant(cmd)
      local hash = (constant == nil) and hashFn(cmd) or gameHashes[kind .. "|" .. cmd.name]
      out[#out + 1] = {
        name       = cmd.name,
        kind       = kind,
        categories = categoryList(cmd.category),
        hash       = hash,
        engine     = constant,
        resolved   = hash ~= nil,
        source     = hash and (constant == nil and "computed" or "harvested") or nil,
      }
    end
  end
  return out
end

--=============================================================================
-- Sérialisation JSON
--=============================================================================

local ESCAPES = {
  ['"'] = '\\"', ['\\'] = '\\\\', ['\b'] = '\\b', ['\f'] = '\\f',
  ['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t',
}

local function jsonString(s)
  return '"' .. s:gsub('[%c"\\]', function(c)
    return ESCAPES[c] or string.format('\\u%04x', c:byte())
  end) .. '"'
end

local function jsonStringArray(list)
  local parts = {}
  for i, v in ipairs(list) do parts[i] = jsonString(v) end
  return "[" .. table.concat(parts, ",") .. "]"
end

local function entryToJson(entry)
  local fields = {
    '"name":'       .. jsonString(entry.name),
    '"kind":'       .. jsonString(entry.kind),
    '"categories":' .. jsonStringArray(entry.categories),
    '"resolved":'   .. tostring(entry.resolved),
  }
  if entry.hash then
    table.insert(fields, 3, '"hash":' .. jsonString(entry.hash))
  end
  if entry.engine then
    table.insert(fields, 3, '"engine":' .. jsonString(entry.engine))
  end
  if entry.source then
    table.insert(fields, 3, '"source":' .. jsonString(entry.source))
  end
  return "{" .. table.concat(fields, ",") .. "}"
end

--=============================================================================
-- Exécution
--=============================================================================

local profilePath = CONFIG.dcsRoot .. CONFIG.profile
local profile = withFolder(profilePath, function()
  return assert(loadfile(profilePath))()
end)

local entries = {}
for _, e in ipairs(collect(profile.keyCommands,  "key",  keyHash))  do entries[#entries + 1] = e end
for _, e in ipairs(collect(profile.axisCommands, "axis", axisHash)) do entries[#entries + 1] = e end

local computedCount, harvestedCount = 0, 0
for _, e in ipairs(entries) do
  if e.source == "computed" then computedCount = computedCount + 1
  elseif e.source == "harvested" then harvestedCount = harvestedCount + 1 end
end
local resolvedCount = computedCount + harvestedCount

local lines = {}
lines[#lines + 1] = "{"
lines[#lines + 1] = '"aircraft":' .. jsonString(CONFIG.aircraftLabel) .. ","
lines[#lines + 1] = '"inputFolder":' .. jsonString(CONFIG.inputFolder) .. ","
lines[#lines + 1] = '"total":' .. #entries .. ","
lines[#lines + 1] = '"resolved":' .. resolvedCount .. ","
lines[#lines + 1] = '"commands":['
for i, entry in ipairs(entries) do
  lines[#lines + 1] = entryToJson(entry) .. (i < #entries and "," or "")
end
lines[#lines + 1] = "]"
lines[#lines + 1] = "}"

local out = assert(io.open(CONFIG.outputJson, "w"))
out:write(table.concat(lines, "\n"))
out:close()

print(string.format("%d commandes extraites", #entries))
print(string.format("  hash calculé  : %d", computedCount))
print(string.format("  hash récolté  : %d", harvestedCount))
print(string.format("  non résolues  : %d", #entries - resolvedCount))
print("écrit dans " .. CONFIG.outputJson)
