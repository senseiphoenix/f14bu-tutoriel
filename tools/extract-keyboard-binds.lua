--[[
  extract-keyboard-binds.lua — Touches clavier par défaut du F-14B(U) Pilote

  Charge la cascade de profils CLAVIER du mod F14BU (F14BU-Pilot -> F-14-Pilot
  -> F-14 -> commandes communes à tous les avions -> commandes communes au
  jeu), exactement comme DCS la résout lui-même : chaque fichier chaîne le
  suivant via external_profile() et les recouvrements se font par nom de
  commande (join_override), donc charger le fichier du haut suffit à obtenir
  la liste finale, déjà fusionnée.

  Pour chaque commande on extrait sa touche par défaut (combos = {{key=...,
  reformers={...}}}) si elle existe. Une commande sans "combos" n'a aucune
  touche clavier assignée par défaut (souvent : action pensée pour un axe/
  bouton physique uniquement).

  Usage :
    "<DCS>\bin\luae.exe" tools\extract-keyboard-binds.lua
]]

local CONFIG = {
  dcsRoot    = os.getenv("DCS_ROOT") or "J:/DCS World/",
  profile    = "Mods/aircraft/F14BU/Input/F-14BU-Pilot/keyboard/default.lua",
  outputJson = "F14BU/data/f14bu-keyboard-binds.json",
}

--=============================================================================
-- Environnement DCS simulé (identique à extract-commands.lua)
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

-- Sans assistant de configuration, DCS ne pré-assigne rien : reflète le
-- comportement réel pour les commandes qui dépendent de cet assistant plutôt
-- que d'une touche câblée en dur dans le profil.
function defaultDeviceAssignmentFor(assignmentName) return nil end

local GAME_PREFIX = "GAMECMD:"
setmetatable(_G, {
  __index = function(_, key)
    if type(key) == "string" and key:match("^[iI]Command") then
      return GAME_PREFIX .. key
    end
    return nil
  end,
})

--=============================================================================
-- Extraction
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

-- "LCtrl+LShift+L" : reformers dans l'ordre déclaré, puis la touche.
local function comboToString(combo)
  if not combo or not combo.key then return nil end
  local parts = {}
  if combo.reformers then
    for _, r in ipairs(combo.reformers) do parts[#parts + 1] = r end
  end
  parts[#parts + 1] = combo.key
  return table.concat(parts, "+")
end

-- Une commande peut avoir plusieurs combos (rare) : on les joint par " ou ".
local function combosToString(combos)
  if not combos or #combos == 0 then return nil end
  local parts = {}
  for _, c in ipairs(combos) do
    local s = comboToString(c)
    if s then parts[#parts + 1] = s end
  end
  if #parts == 0 then return nil end
  return table.concat(parts, " ou ")
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

--=============================================================================
-- Exécution
--=============================================================================

local profilePath = CONFIG.dcsRoot .. CONFIG.profile
local profile = withFolder(profilePath, function()
  return assert(loadfile(profilePath))()
end)

-- Indexé par nom : un nom de commande est unique dans la liste finale fusionnée
-- (join_override fusionne justement là-dessus), donc pas d'ambiguïté ici —
-- contrairement au hash des .diff.lua, on n'a pas besoin de la catégorie pour
-- désambiguïser une commande touche d'une commande axe.
local withKey, withoutKey = 0, 0
local lines = {}
lines[#lines + 1] = "{"
lines[#lines + 1] = '"aircraft":' .. jsonString("F-14B(U) Pilot") .. ","
lines[#lines + 1] = '"source":' .. jsonString(CONFIG.profile) .. ","
lines[#lines + 1] = '"binds":{'

local first = true
for _, cmd in ipairs(profile.keyCommands or {}) do
  if cmd.name then
    local combo = combosToString(cmd.combos)
    if combo then withKey = withKey + 1 else withoutKey = withoutKey + 1 end
    if not first then lines[#lines + 1] = "," end
    first = false
    lines[#lines + 1] = jsonString(cmd.name) .. ":" .. (combo and jsonString(combo) or "null")
  end
end

lines[#lines + 1] = "}}"

local out = assert(io.open(CONFIG.outputJson, "w"))
out:write(table.concat(lines, "\n"))
out:close()

print(string.format("%d commandes clavier (cascade F14BU -> F14 -> communes avion -> communes jeu)", withKey + withoutKey))
print(string.format("  avec touche par defaut : %d", withKey))
print(string.format("  sans touche assignee   : %d", withoutKey))
print("ecrit dans " .. CONFIG.outputJson)
