--[[
  extract-hotas-labels.lua — Extrait les étiquettes HOTAS de la page mapping

  F14BU/mapping-hotas.html reste la source de vérité des étiquettes : cette page
  fonctionne, y compris ouverte en local, et on n'y touche pas. Ce script en
  dérive un JSON que la page d'export peut charger.

  À relancer après toute modification des tables LABELS ou DETAILS.

  Usage :
    "<DCS>\bin\luae.exe" tools\extract-hotas-labels.lua
]]

local CONFIG = {
  source = "F14BU/mapping-hotas.html",
  output = "F14BU/data/f14bu-hotas.json",
}

--=============================================================================
-- Lecture de la page
--=============================================================================

local file = assert(io.open(CONFIG.source, "r"))
local html = file:read("*a")
file:close()

-- Isole le corps d'une déclaration « const NOM = <valeur>; » en suivant
-- l'imbrication des accolades : les valeurs contiennent elles-mêmes des { }.
local function extractDeclaration(name)
  local startPos = html:find("const%s+" .. name .. "%s*=%s*{")
  assert(startPos, "déclaration introuvable : " .. name)
  local braceStart = html:find("{", startPos)
  local depth, pos, inString, escape = 0, braceStart, nil, false

  while pos <= #html do
    local ch = html:sub(pos, pos)
    if inString then
      if escape then escape = false
      elseif ch == "\\" then escape = true
      elseif ch == inString then inString = nil end
    elseif ch == '"' or ch == "'" then
      inString = ch
    elseif ch == "{" then
      depth = depth + 1
    elseif ch == "}" then
      depth = depth - 1
      if depth == 0 then return html:sub(braceStart, pos) end
    end
    pos = pos + 1
  end
  error("accolade non refermée dans " .. name)
end

--=============================================================================
-- Conversion JavaScript -> Lua
--=============================================================================

-- Un tableau JS s'écrit [a,b], une table Lua {a,b}. On échange les crochets
-- en parcourant caractère par caractère, pour ne pas toucher à ceux qui se
-- trouvent à l'intérieur d'une chaîne (les libellés en contiennent).
local function swapBrackets(source)
  local out, inString, escape = {}, nil, false
  for i = 1, #source do
    local ch = source:sub(i, i)
    if inString then
      if escape then escape = false
      elseif ch == "\\" then escape = true
      elseif ch == inString then inString = nil end
    elseif ch == '"' or ch == "'" then
      inString = ch
    elseif ch == "[" then ch = "{"
    elseif ch == "]" then ch = "}" end
    out[#out + 1] = ch
  end
  return table.concat(out)
end

-- Les clés s'écrivent soit nues (n:"rY"), soit entre guillemets ("stick|rY":).
-- Lua veut = et [".."]. On ne réécrit que ce qui suit une accolade ou une
-- virgule, pour ne pas toucher au contenu des chaînes.
local function jsToLua(source)
  return (swapBrackets(source)
    :gsub('([{,]%s*)"([^"]-)"%s*:', '%1["%2"]=')
    :gsub("([{,]%s*)([%a_][%w_]*)%s*:", "%1%2="))
end

local function loadTable(name)
  local luaSource = jsToLua(extractDeclaration(name))
  local chunk = assert(loadstring("return " .. luaSource), "syntaxe invalide : " .. name)
  return chunk()
end

local LABELS  = loadTable("LABELS")
local DETAILS = loadTable("DETAILS")

--=============================================================================
-- Sérialisation JSON
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

--=============================================================================
-- Écriture
--=============================================================================

local DEVICE_ORDER = {"stick", "throttle", "pto2", "pedals"}

local lines = {"{", '"device":['}
local total = 0

for deviceIndex, device in ipairs(DEVICE_ORDER) do
  local labels = LABELS[device]
  assert(labels, "périphérique absent de LABELS : " .. device)

  lines[#lines + 1] = '{"id":' .. jsonString(device) .. ',"labels":['
  for i, label in ipairs(labels) do
    total = total + 1
    local detail = DETAILS[device .. "|" .. label.n] or {}
    local fields = {
      '"n":'     .. jsonString(label.n),
      '"cat":'   .. jsonString(label.cat),
      '"text":'  .. jsonString(label.t),
      '"detail":' .. jsonString(detail.det or ""),
      '"lesson":' .. jsonString(detail.lec or ""),
      -- Le drapeau v de la planche affiche un « ? » : l'étiquette elle-même
      -- est incertaine, indépendamment de la commande qu'on lui associe.
      '"verify":' .. tostring(label.v and true or false),
    }
    lines[#lines + 1] = "  {" .. table.concat(fields, ",") .. "}"
                        .. (i < #labels and "," or "")
  end
  lines[#lines + 1] = "]}" .. (deviceIndex < #DEVICE_ORDER and "," or "")
end

lines[#lines + 1] = "]"
lines[#lines + 1] = "}"

local out = assert(io.open(CONFIG.output, "w"))
out:write(table.concat(lines, "\n"))
out:close()

print(string.format("%d étiquettes extraites de %s", total, CONFIG.source))
for _, device in ipairs(DEVICE_ORDER) do
  print(string.format("  %-9s %d", device, #LABELS[device]))
end
print("écrit dans " .. CONFIG.output)
