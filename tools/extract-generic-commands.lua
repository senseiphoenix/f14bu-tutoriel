--[[
  extract-generic-commands.lua — Catalogue des commandes de vol génériques

  DCS définit dans Config/Input/Aircrafts/base_joystick_binding.lua (et sa
  base common_joystick_binding.lua) les commandes communes à tous les avions :
  tangage, roulis, lacet, gaz, trims, vues… Ce sont toutes des commandes
  moteur (iCommand*), donc leur hash est incalculable statiquement — mais il
  est PARTAGÉ entre tous les modules, ce qui les rend exportables une fois
  pour toutes.

  Ce script :
  1. charge le profil générique pour obtenir la liste officielle
     (nom, catégorie, touche ou axe) ;
  2. balaie tous les .diff.lua du joueur EN GROUPANT PAR AVION, et vérifie
     que chaque nom générique correspond au même hash partout — c'est la
     preuve demandée que « roulis, tangage, etc. » sont bien attribués
     uniformément ;
  3. écrit data/dcs-generic-commands.json avec, pour chaque commande, son
     hash vérifié et la liste des avions où il a été observé.

  Usage :
    "<DCS>\bin\luae.exe" tools\extract-generic-commands.lua
]]

local CONFIG = {
  dcsRoot    = os.getenv("DCS_ROOT") or "J:/DCS World/",
  profile    = "Config/Input/Aircrafts/base_joystick_binding.lua",
  savedGames = (os.getenv("USERPROFILE") or "C:/Users/Default"):gsub("\\", "/") .. "/Saved Games/",
  instances  = {"DCS", "DCS.openbeta", "DCS_F4E"},
  locales    = {"fr", "en"},
  output     = "data/dcs-generic-commands.json",
}

--=============================================================================
-- Environnement DCS simulé (même socle que extract-commands.lua)
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

function defaultDeviceAssignmentFor() return nil end
function MultiEngineDefaultDeviceAssignmentForThrust() return nil, nil, nil end

-- Le profil générique utilise join() là où les modules utilisent join_override.
function join(t1, t2)
  for _, v in ipairs(t2) do t1[#t1 + 1] = v end
  return t1
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

--=============================================================================
-- 1. Liste officielle des commandes génériques
--=============================================================================

local profilePath = CONFIG.dcsRoot .. CONFIG.profile
local profile = withFolder(profilePath, function()
  return assert(loadfile(profilePath))()
end)

local function categoryList(category)
  if category == nil then return {} end
  if type(category) == "string" then return {category} end
  local out = {}
  for _, c in ipairs(category) do
    if type(c) == "string" then out[#out + 1] = c end
  end
  return out
end

-- nom -> {kind, categories}. Les doublons de nom au sein du générique gardent
-- la première occurrence : le fichier en contient quelques-uns (variantes).
local generic, order = {}, {}
local function register(cmd, kind)
  if cmd.name and not generic[cmd.name] then
    generic[cmd.name] = {kind = kind, categories = categoryList(cmd.category)}
    order[#order + 1] = cmd.name
  end
end
for _, cmd in ipairs(profile.keyCommands or {})  do register(cmd, "key")  end
for _, cmd in ipairs(profile.axisCommands or {}) do register(cmd, "axis") end

--=============================================================================
-- 2. Dictionnaires gettext : libellé traduit -> nom anglais
--=============================================================================

local function uint32(data, pos)
  local a, b, c, d = data:byte(pos, pos + 3)
  return a + b * 256 + c * 65536 + d * 16777216
end

local function readMoReversed(path)
  local file = io.open(path, "rb")
  if not file then return nil end
  local data = file:read("*a")
  file:close()
  if not data or #data < 28 or uint32(data, 1) ~= 0x950412de then return nil end
  local count          = uint32(data, 9)
  local originalsAt    = uint32(data, 13)
  local translationsAt = uint32(data, 17)
  local reversed = {}
  for i = 0, count - 1 do
    local oLen = uint32(data, originalsAt + i * 8 + 1)
    local oOff = uint32(data, originalsAt + i * 8 + 5)
    local tLen = uint32(data, translationsAt + i * 8 + 1)
    local tOff = uint32(data, translationsAt + i * 8 + 5)
    if oLen > 0 and tLen > 0 then
      local original    = data:sub(oOff + 1, oOff + oLen)
      local translation = data:sub(tOff + 1, tOff + tLen)
      if not original:find("\0") and not translation:find("\0") then
        reversed[translation] = original
      end
    end
  end
  return reversed
end

local toEnglish = {}
for _, locale in ipairs(CONFIG.locales) do
  for _, domain in ipairs({"input", "inputEvents", "dcs"}) do
    local reversed = readMoReversed(CONFIG.dcsRoot .. "l10n/" .. locale .. "/LC_MESSAGES/" .. domain .. ".mo")
    if reversed then
      for translated, original in pairs(reversed) do toEnglish[translated] = original end
    end
  end
end

--=============================================================================
-- 3. Balayage par avion et contrôle d'uniformité
--=============================================================================

local function listDiffFiles()
  local files = {}
  for _, instance in ipairs(CONFIG.instances) do
    local dir = (CONFIG.savedGames .. instance):gsub("/", "\\")
    local pipe = io.popen('dir /s /b "' .. dir .. '\\*.diff.lua" 2>nul')
    if pipe then
      for line in pipe:lines() do
        if line ~= "" then files[#files + 1] = line end
      end
      pipe:close()
    end
  end
  return files
end

-- L'avion est le nom de dossier sous Config\Input, ou sous
-- Config\JP_Backup\<horodatage>\Input pour les sauvegardes de profils.
local function aircraftOf(path)
  local p = path:gsub("\\", "/")
  return p:match("/JP_Backup/[^/]+/Input/([^/]+)/")
      or p:match("/Config/Input/([^/]+)/")
end

local function isGameHash(hash)
  return hash:find("cdnil", 1, true) ~= nil
end

-- clé "kind|nom EN" -> { hash -> { avion -> true } }
local observed = {}

for _, path in ipairs(listDiffFiles()) do
  local aircraft = aircraftOf(path)
  local chunk = rawLoadfile(path)
  if aircraft and chunk then
    local ok, diff = pcall(chunk)
    if ok and type(diff) == "table" then
      for _, section in ipairs({"keyDiffs", "axisDiffs"}) do
        local kind = (section == "axisDiffs") and "axis" or "key"
        for hash, entry in pairs(diff[section] or {}) do
          if entry.name and isGameHash(hash) then
            local english = toEnglish[entry.name] or entry.name
            local key = kind .. "|" .. english
            observed[key] = observed[key] or {}
            observed[key][hash] = observed[key][hash] or {}
            observed[key][hash][aircraft] = true
          end
        end
      end
    end
  end
end

--=============================================================================
-- 4. Confrontation et écriture
--=============================================================================

local ESCAPES = {
  ['"'] = '\\"', ['\\'] = '\\\\', ['\b'] = '\\b', ['\f'] = '\\f',
  ['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t',
}
local function jsonString(s)
  return '"' .. tostring(s):gsub('[%c"\\]', function(c)
    return ESCAPES[c] or string.format('\\u%04x', c:byte())
  end) .. '"'
end
local function jsonStringArray(list)
  local parts = {}
  for i, v in ipairs(list) do parts[i] = jsonString(v) end
  return "[" .. table.concat(parts, ",") .. "]"
end

local verified, unseen, conflicts = 0, 0, 0
local conflictReport = {}
local lines = {"{", '"source":' .. jsonString(CONFIG.profile) .. ",", '"commands":['}
local entryLines = {}

for _, name in ipairs(order) do
  local info = generic[name]
  local key = info.kind .. "|" .. name
  local seen = observed[key]

  local hash, aircraftList, excluded, status = nil, {}, {}, "unseen"
  if seen then
    local hashes = {}
    for h in pairs(seen) do hashes[#hashes + 1] = h end
    if #hashes == 1 then
      hash = hashes[1]
      for aircraft in pairs(seen[hash]) do aircraftList[#aircraftList + 1] = aircraft end
      table.sort(aircraftList)
      status = "verified"
      verified = verified + 1
    else
      -- Divergence réelle : quelques modules tiers (C-101, Mirage F1, F-86…)
      -- redéclarent la commande sous leur propre ID. On garde le hash
      -- majoritaire — le standard moteur — et on liste les avions exclus.
      status = "majority"
      conflicts = conflicts + 1
      local best, bestCount = nil, -1
      for h, planes in pairs(seen) do
        local n = 0
        for _ in pairs(planes) do n = n + 1 end
        if n > bestCount then best, bestCount = h, n end
      end
      hash = best
      for h, planes in pairs(seen) do
        for aircraft in pairs(planes) do
          if h == best then aircraftList[#aircraftList + 1] = aircraft
          else excluded[#excluded + 1] = aircraft end
        end
      end
      table.sort(aircraftList); table.sort(excluded)
      conflictReport[#conflictReport + 1] =
        name .. " — hors standard : " .. table.concat(excluded, ", ")
    end
  else
    unseen = unseen + 1
  end

  local fields = {
    '"name":'       .. jsonString(name),
    '"kind":'       .. jsonString(info.kind),
    '"categories":' .. jsonStringArray(info.categories),
    '"status":'     .. jsonString(status),
  }
  if hash then
    fields[#fields + 1] = '"hash":' .. jsonString(hash)
    fields[#fields + 1] = '"aircraft":' .. jsonStringArray(aircraftList)
    if #excluded > 0 then
      fields[#fields + 1] = '"excluded":' .. jsonStringArray(excluded)
    end
  end
  entryLines[#entryLines + 1] = "{" .. table.concat(fields, ",") .. "}"
end

for i, e in ipairs(entryLines) do
  lines[#lines + 1] = e .. (i < #entryLines and "," or "")
end
lines[#lines + 1] = "]"
lines[#lines + 1] = "}"

local out = assert(io.open(CONFIG.output, "w"))
out:write(table.concat(lines, "\n"))
out:close()

print(string.format("%d commandes génériques dans %s", #order, CONFIG.profile))
print(string.format("  vérifiées (hash identique sur tous les avions) : %d", verified))
print(string.format("  jamais bindées chez vous (hash inconnu)        : %d", unseen))
print(string.format("  CONFLITS (hash divergents selon l'avion)       : %d", conflicts))
for _, c in ipairs(conflictReport) do print("    ! " .. c) end
print("écrit dans " .. CONFIG.output)
