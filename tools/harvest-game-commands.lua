--[[
  harvest-game-commands.lua — Résout les commandes « jeu » du catalogue

  Les constantes iCommandXxx / ICommandXxx sont injectées par le moteur C++ et
  n'apparaissent dans aucun fichier .lua : impossible de calculer leur hash par
  lecture statique. On le récupère donc dans les .diff.lua déjà écrits par DCS,
  où chaque entrée porte à la fois sa clé de hash et son libellé.

  DCS écrit ces libellés dans la langue de l'interface. Pour retrouver le nom
  anglais du catalogue, on lit le dictionnaire gettext du jeu.

  Sortie : tools/game-commands-cache.lua, consommé par extract-commands.lua.

  Usage :
    "<DCS>\bin\luae.exe" tools\harvest-game-commands.lua
]]

local CONFIG = {
  dcsRoot    = os.getenv("DCS_ROOT") or "J:/DCS World/",
  savedGames = (os.getenv("USERPROFILE") or "C:/Users/Default"):gsub("\\", "/") .. "/Saved Games/",
  instances  = {"DCS", "DCS.openbeta", "DCS_F4E"},
  -- Dictionnaires à charger : langue de l'interface DCS du joueur
  locales    = {"fr", "en"},
  output     = "tools/game-commands-cache.lua",
}

--=============================================================================
-- Lecture des catalogues gettext (.mo)
--=============================================================================

local function uint32(data, pos)
  local a, b, c, d = data:byte(pos, pos + 3)
  return a + b * 256 + c * 65536 + d * 16777216
end

-- Renvoie une table traduction -> original, ou nil si le fichier est absent
-- ou n'est pas un .mo petit-boutiste.
local function readMoReversed(path)
  local file = io.open(path, "rb")
  if not file then return nil end
  local data = file:read("*a")
  file:close()
  if not data or #data < 28 then return nil end
  if uint32(data, 1) ~= 0x950412de then return nil end

  local count         = uint32(data, 9)
  local originalsAt   = uint32(data, 13)
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
      -- Une entrée peut porter plusieurs formes séparées par \0 : on ignore.
      if not original:find("\0") and not translation:find("\0") then
        reversed[translation] = original
      end
    end
  end
  return reversed
end

local toEnglish = {}
local dictCount = 0
for _, locale in ipairs(CONFIG.locales) do
  for _, domain in ipairs({"input", "inputEvents", "dcs"}) do
    local path = CONFIG.dcsRoot .. "l10n/" .. locale .. "/LC_MESSAGES/" .. domain .. ".mo"
    local reversed = readMoReversed(path)
    if reversed then
      for translated, original in pairs(reversed) do
        toEnglish[translated] = original
        dictCount = dictCount + 1
      end
    end
  end
end

--=============================================================================
-- Balayage des diff.lua existants
--=============================================================================

-- On balaie toute l'instance, pas seulement Config\Input : les sauvegardes de
-- profils (Config\JP_Backup) contiennent dix fois plus de couples nom/hash.
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

-- Une commande jeu n'a pas de cockpit device : son hash contient « cdnil ».
local function isGameHash(hash)
  return hash:find("cdnil", 1, true) ~= nil
end

local files = listDiffFiles()
local byName, entries = {}, 0

for _, path in ipairs(files) do
  local chunk = loadfile(path)
  if chunk then
    local ok, diff = pcall(chunk)
    if ok and type(diff) == "table" then
      for _, section in ipairs({"keyDiffs", "axisDiffs"}) do
        for hash, entry in pairs(diff[section] or {}) do
          if entry.name and isGameHash(hash) then
            entries = entries + 1
            -- On enregistre le libellé tel quel et, si c'est une traduction,
            -- son original anglais : le catalogue est en anglais.
            byName[entry.name] = hash
            local english = toEnglish[entry.name]
            if english then byName[english] = hash end
          end
        end
      end
    end
  end
end

--=============================================================================
-- Écriture du cache
--=============================================================================

local names = {}
for name in pairs(byName) do names[#names + 1] = name end
table.sort(names)

local out = assert(io.open(CONFIG.output, "w"))
out:write("-- Généré par tools/harvest-game-commands.lua — ne pas éditer à la main.\n")
out:write("-- Nom de commande (anglais et libellé local) -> hash DCS.\n")
out:write("return {\n")
for _, name in ipairs(names) do
  out:write(string.format("  [%q] = %q,\n", name, byName[name]))
end
out:write("}\n")
out:close()

print(string.format("%d fichiers diff.lua balayés, %d entrées de commande jeu", #files, entries))
print(string.format("%d traductions chargées depuis les catalogues gettext", dictCount))
print(string.format("%d noms distincts écrits dans %s", #names, CONFIG.output))
