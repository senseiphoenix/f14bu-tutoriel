--[[
  extract-commands.lua — Extracteur du catalogue de commandes F-14B(U)

  Charge la cascade de profils d'entrée du mod F14BU avec l'interpréteur Lua
  fourni par DCS, résout les IDs numériques, calcule le hash de chaque commande
  (la clé utilisée dans les fichiers .diff.lua) et écrit un catalogue JSON.

  Usage :
    "<DCS>\bin\luae.exe" tools\extract-commands.lua

  Voir tools/README.md pour la configuration et le format de sortie.
]]

--=============================================================================
-- Configuration
--=============================================================================

local CONFIG = {
  dcsRoot     = os.getenv("DCS_ROOT") or "J:/DCS World/",
  profile     = "Mods/aircraft/F14BU/Input/F-14BU-Pilot/joystick/default.lua",
  outputJson  = "F14BU/data/f14bu-commands.json",
  -- Hash des commandes jeu, produit par tools/harvest-game-commands.lua
  gameCache   = "tools/game-commands-cache.lua",
  -- Dossier créé par DCS dans Saved Games (clé InputProfiles de entry.lua)
  inputFolder = "F-14BU",
}

--=============================================================================
-- Environnement DCS simulé
--=============================================================================

-- Les fichiers d'entrée passent tous les libellés par _() pour la traduction.
function _(s) return s end

-- DCS résout les chemins sans lettre de lecteur depuis la racine d'installation.
local rawLoadfile = loadfile
function loadfile(path, ...)
  if path and not path:match("^%a:[/\\]") and not path:match("^[/\\]") then
    path = CONFIG.dcsRoot .. path
  end
  return rawLoadfile(path, ...)
end

-- Chaque fichier lit la globale 'folder' pour résoudre ses chemins relatifs.
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

-- Sans assistant de configuration, DCS renvoie nil : aucune touche pré-assignée.
function defaultDeviceAssignmentFor(assignmentName) return nil end

-- Les constantes de commande du moteur (graphies iCommandXxx et ICommandXxx)
-- n'existent dans aucun .lua. On les marque pour les résoudre ensuite via les
-- diff.lua du joueur, où le couple nom/hash est enregistré en clair.
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

-- Un segment vaut "nil" quand le champ est absent. Les nombres passent par
-- tostring : Lua 5.1 formate en %.14g, donc 1.0 donne bien "1" comme DCS.
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

-- category vaut soit une chaîne, soit une table de chaînes.
local function categoryList(category)
  if category == nil then return {} end
  if type(category) == "string" then return {category} end
  local out = {}
  for _, c in ipairs(category) do
    if type(c) == "string" then out[#out + 1] = c end
  end
  return out
end

-- Nom de la constante moteur d'une commande jeu, pour la résoudre plus tard.
local function engineConstant(cmd)
  for _, field in ipairs({"down", "pressed", "up", "action"}) do
    if isGameCommand(cmd[field]) then
      return cmd[field]:sub(#GAME_PREFIX + 1)
    end
  end
  return nil
end

-- Hash des commandes jeu récoltés dans les diff.lua du joueur. Absent tant que
-- harvest-game-commands.lua n'a pas tourné : l'extraction reste valide, les
-- commandes jeu sortent simplement sans hash.
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
      local hash = (constant == nil) and hashFn(cmd) or gameHashes[cmd.name]
      out[#out + 1] = {
        name       = cmd.name,
        kind       = kind,
        categories = categoryList(cmd.category),
        hash       = hash,
        engine     = constant,
        resolved   = hash ~= nil,
        -- Distingue un hash calculé d'un hash récolté (moins sûr : il dépend
        -- d'un profil écrit par une version antérieure du module).
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
lines[#lines + 1] = '"aircraft":' .. jsonString("F-14B(U) Pilot") .. ","
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
