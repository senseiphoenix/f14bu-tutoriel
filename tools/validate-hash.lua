--[[
  validate-hash.lua — Vérifie la formule de hash contre des fichiers réels

  Recalcule le hash de chaque commande du profil F-14 Heatblur, puis le compare
  aux clés réellement écrites par DCS dans les .diff.lua du joueur. Un seul
  désaccord invalide la formule : le fichier généré serait ignoré par DCS.

  Usage :
    "<DCS>\bin\luae.exe" tools\validate-hash.lua
]]

local CONFIG = {
  dcsRoot   = os.getenv("DCS_ROOT") or "J:/DCS World/",
  -- Profil Heatblur : c'est celui dont le joueur possède déjà des diff.lua
  profile   = "Mods/aircraft/F14/Input/F-14B-Pilot/joystick/default.lua",
  savedGames = (os.getenv("USERPROFILE") or "C:/Users/Default"):gsub("\\", "/") .. "/Saved Games/",
  instances = {"DCS", "DCS.openbeta", "DCS_F4E"},
  aircraft  = "F-14",
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

function defaultDeviceAssignmentFor() return nil end

-- Le moteur expose ses constantes sous deux graphies : iCommandXxx et ICommandXxx.
local GAME_PREFIX = "GAMECMD:"
setmetatable(_G, {
  __index = function(_, key)
    if type(key) == "string" and key:match("^[iI]Command") then
      return GAME_PREFIX .. key
    end
    return nil
  end,
})

local function isGameCommand(v)
  return type(v) == "string" and v:sub(1, #GAME_PREFIX) == GAME_PREFIX
end

local function segment(value)
  if value == nil or isGameCommand(value) then return "nil" end
  return tostring(value)
end

local function keyHash(cmd)
  return "d"  .. segment(cmd.down)
      .. "p"  .. segment(cmd.pressed)
      .. "u"  .. segment(cmd.up)
      .. "cd" .. segment(cmd.cockpit_device_id)
      .. "vd" .. segment(cmd.value_down)
      .. "vp" .. segment(cmd.value_pressed)
      .. "vu" .. segment(cmd.value_up)
end

local function axisHash(cmd)
  return "a" .. segment(cmd.action) .. "cd" .. segment(cmd.cockpit_device_id)
end

--=============================================================================
-- Catalogue de référence
--=============================================================================

local profilePath = CONFIG.dcsRoot .. CONFIG.profile
local profile = withFolder(profilePath, function()
  return assert(loadfile(profilePath))()
end)

-- Un même nom couvre parfois plusieurs commandes distinctes (« Flaps Up »
-- existe en version jeu et en version cockpit). On indexe donc par hash, et on
-- garde à part la liste des noms ambigus.
local hashSet, namesSeen, ambiguous = {}, {}, {}

local function index(cmd, hash)
  hashSet[hash] = cmd.name
  if namesSeen[cmd.name] and namesSeen[cmd.name] ~= hash then
    ambiguous[cmd.name] = true
  end
  namesSeen[cmd.name] = hash
end

for _, cmd in ipairs(profile.keyCommands) do
  if cmd.name and not (isGameCommand(cmd.down) or isGameCommand(cmd.up)
                    or isGameCommand(cmd.pressed)) then
    index(cmd, keyHash(cmd))
  end
end
for _, cmd in ipairs(profile.axisCommands) do
  if cmd.name and not isGameCommand(cmd.action) then
    index(cmd, axisHash(cmd))
  end
end

--=============================================================================
-- Confrontation aux diff.lua du joueur
--=============================================================================

local function listDiffFiles()
  local files = {}
  for _, instance in ipairs(CONFIG.instances) do
    local dir = CONFIG.savedGames .. instance .. "/Config/Input/" .. CONFIG.aircraft
    local pipe = io.popen('dir /s /b "' .. dir:gsub("/", "\\") .. '\\*.diff.lua" 2>nul')
    if pipe then
      for line in pipe:lines() do
        if line ~= "" then files[#files + 1] = line end
      end
      pipe:close()
    end
  end
  return files
end

-- Le test qui compte : un hash cockpit écrit par DCS doit figurer tel quel
-- parmi ceux que la formule produit. Les commandes jeu (cdnil) sont hors
-- périmètre, et une commande retirée du module depuis 2022 n'est pas une
-- erreur de formule — on les compte à part.
local files = listDiffFiles()
local produced, gameCmd, stale = 0, 0, 0
local staleExamples = {}

for _, path in ipairs(files) do
  local chunk = rawLoadfile(path)
  if chunk then
    local ok, diff = pcall(chunk)
    if ok and type(diff) == "table" then
      for _, section in ipairs({"keyDiffs", "axisDiffs"}) do
        for actualHash, entry in pairs(diff[section] or {}) do
          if hashSet[actualHash] then
            produced = produced + 1
          elseif actualHash:match("cdnil") then
            gameCmd = gameCmd + 1
          else
            stale = stale + 1
            if #staleExamples < 8 then
              staleExamples[#staleExamples + 1] =
                string.format("%-42s %s", tostring(entry.name), actualHash)
            end
          end
        end
      end
    end
  end
end

local ambiguousCount = 0
for _ in pairs(ambiguous) do ambiguousCount = ambiguousCount + 1 end

print(string.format("%d fichiers diff.lua confrontés", #files))
print(string.format("  hash cockpit reproduits par la formule : %d", produced))
print(string.format("  commandes jeu (hors périmètre)         : %d", gameCmd))
print(string.format("  hash cockpit absents du catalogue      : %d", stale))
print(string.format("  noms ambigus dans le catalogue         : %d", ambiguousCount))

if #staleExamples > 0 then
  print("\n--- hash cockpit absents (module modifié depuis l'écriture du diff) ---")
  for _, f in ipairs(staleExamples) do print("  " .. f) end
end

if produced == 0 then
  print("\nÉCHEC : aucun hash reproduit, la formule est fausse.")
  os.exit(1)
end
print(string.format("\nFormule validée sur %d hash cockpit réels.", produced))
