<#
    parse-sc-layout.ps1 — Star Citizen : layout XML -> JSON

    Lit les profils de touches exportes par le jeu
    (Options > Keybindings > Export, fichiers layout_*.xml) et produit deux
    fichiers JSON consommes par les pages du dossier SC\ :

      SC\data\sc-bindings.json  binds du layout courant (peripheriques, axes,
                                boutons, couches de modificateur, courbes)
      SC\data\sc-actions.json   catalogue des noms d'action rencontres, avec
                                leur actionmap et les fichiers ou ils figurent

    Les deux fichiers sont REGENERES a chaque execution : ne jamais les editer
    a la main. Les libelles francais vivent dans SC\data\sc-labels-fr.json,
    qui n'est pas touche par ce script.

    Usage :
      powershell -ExecutionPolicy Bypass -File tools\parse-sc-layout.ps1
      powershell ... -Layout "layout_BK_TriplePrime_4-8_exported.xml"
      powershell ... -ScRoot "J:\Robert space\StarCitizen" -Channel LIVE

    NOTE ENVIRONNEMENT : sur ce poste, PowerShell 5.1 leve
    "Les types des arguments ne correspondent pas" sur @($liste) quand la
    liste est une System.Collections.Generic.List[T]. Ce script n'utilise donc
    que des tableaux natifs PowerShell.
#>

[CmdletBinding()]
param(
    # Racine de l'installation Star Citizen (contient LIVE\ et PTU\).
    [string]$ScRoot = 'J:\Robert space\StarCitizen',

    # Canal a lire : LIVE, PTU, EPTU...
    [string]$Channel = 'LIVE',

    # Nom (ou chemin complet) du layout a traiter. Par defaut : le plus recent
    # du dossier Mappings.
    [string]$Layout,

    # Dossiers supplementaires balayes pour enrichir le catalogue d'actions
    # (anciens exports : ils contiennent souvent des actions absentes du
    # profil courant, utiles pour concevoir un mapping).
    [string[]]$ExtraDirs = @("$env:USERPROFILE\Documents\Star Citizen Keybind Backups"),

    # Dossier de sortie des JSON.
    [string]$OutDir
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
if (-not $OutDir) { $OutDir = Join-Path $repoRoot 'SC\data' }

# ---------------------------------------------------------------- utilitaires

# "RIGHT VPC Stick WarBRD-D  {43F53344-...}" -> nom + GUID
function Split-Product([string]$product) {
    $name = $product
    $guid = ''
    $i = $product.LastIndexOf('{')
    if ($i -ge 0) {
        $guid = $product.Substring($i).Trim()
        $name = $product.Substring(0, $i)
    }
    [pscustomobject]@{ name = $name.Trim(); guid = $guid }
}

# "js2_rctrl+button31" -> device js2, modificateur rctrl, bouton 31
function Split-Input([string]$raw) {
    $res = [ordered]@{
        raw        = $raw
        deviceTag  = ''      # js1, kb1, mo1...
        deviceType = ''      # joystick, keyboard, mouse
        instance   = 0
        modifiers  = @()
        control    = ''      # button31, x, rotz, slider1, hat1_up
        kind       = ''      # button / axis / hat / key / cleared
        number     = $null   # numero de bouton, si bouton
    }

    if ([string]::IsNullOrWhiteSpace($raw)) { $res.kind = 'cleared'; return $res }

    $body = $raw
    if ($raw -match '^(js|kb|mo|gp)(\d+)_(.*)$') {
        $res.deviceTag  = "$($Matches[1])$($Matches[2])"
        $res.instance   = [int]$Matches[2]
        $res.deviceType = switch ($Matches[1]) {
            'js' { 'joystick' } 'kb' { 'keyboard' } 'mo' { 'mouse' } 'gp' { 'gamepad' }
        }
        $body = $Matches[3]
    }

    # "mo1_ " (une espace) = bind efface dans le jeu, pas un vrai bind
    if ([string]::IsNullOrWhiteSpace($body)) { $res.kind = 'cleared'; return $res }

    $parts = @($body -split '\+')
    $res.control = $parts[$parts.Count - 1]
    if ($parts.Count -gt 1) { $res.modifiers = @($parts[0..($parts.Count - 2)]) }

    $res.kind = switch -Regex ($res.control) {
        '^button\d+$'              { 'button' }
        '^(x|y|z|rotx|roty|rotz)$' { 'axis'   }
        '^slider\d+$'              { 'axis'   }
        '^hat\d+'                  { 'hat'    }
        default                    { 'key'    }
    }
    if ($res.control -match '^button(\d+)$') { $res.number = [int]$Matches[1] }

    return $res
}

# Attributs d'un noeud -> table (sert aux <options> et <deviceoptions>)
function Get-Attrs($node) {
    $t = [ordered]@{}
    foreach ($a in $node.Attributes) { $t[$a.Name] = $a.Value }
    $t
}

function Read-LayoutXml([string]$path) {
    $doc = New-Object System.Xml.XmlDocument
    $doc.PreserveWhitespace = $false
    $doc.Load($path)
    $doc
}

# ------------------------------------------------------- choix des fichiers

$mapDir = Join-Path $ScRoot "$Channel\user\client\0\Controls\Mappings"

if ($Layout) {
    $layoutPath = if (Test-Path $Layout) { (Resolve-Path $Layout).Path } else { Join-Path $mapDir $Layout }
} else {
    if (-not (Test-Path $mapDir)) {
        throw "Dossier Mappings introuvable : $mapDir. Verifier -ScRoot / -Channel."
    }
    $newest = Get-ChildItem -Path $mapDir -Filter '*.xml' |
              Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $newest) { throw "Aucun layout_*.xml dans $mapDir. Exporter un profil depuis le jeu d'abord." }
    $layoutPath = $newest.FullName
}
if (-not (Test-Path $layoutPath)) { throw "Layout introuvable : $layoutPath" }

Write-Host "Layout courant : $layoutPath" -ForegroundColor Cyan

# Fichiers balayes pour le catalogue : le layout courant + ses voisins + archives
$catalogFiles = @($layoutPath)
if (Test-Path $mapDir) {
    $catalogFiles += @(Get-ChildItem $mapDir -Filter '*.xml' | ForEach-Object { $_.FullName })
}
foreach ($d in $ExtraDirs) {
    if (Test-Path $d) {
        $catalogFiles += @(Get-ChildItem $d -Filter '*.xml' -Recurse | ForEach-Object { $_.FullName })
    }
}
$catalogFiles = @($catalogFiles | Select-Object -Unique)

# --------------------------------------------- 1. binds du layout courant

$doc  = Read-LayoutXml $layoutPath
$root = $doc.DocumentElement

$devices = [ordered]@{}
foreach ($o in $root.SelectNodes('options')) {
    $type = $o.GetAttribute('type')
    $inst = $o.GetAttribute('instance')
    if (-not $type -or -not $inst) { continue }
    $tagPrefix = switch ($type) { 'joystick' { 'js' } 'keyboard' { 'kb' } 'mouse' { 'mo' } default { $type } }
    $tag = "$tagPrefix$inst"
    $p = Split-Product $o.GetAttribute('Product')

    # Reglages par action : <flight_move_pitch exponent="1.2"/>
    $tuning = [ordered]@{}
    foreach ($c in $o.ChildNodes) {
        if ($c.NodeType -ne 'Element') { continue }
        $tuning[$c.Name] = Get-Attrs $c
    }

    $devices[$tag] = [ordered]@{
        tag       = $tag
        type      = $type
        instance  = [int]$inst
        product   = $o.GetAttribute('Product')
        name      = $p.name
        guid      = $p.guid
        tuning    = $tuning
        deadzones = [ordered]@{}
        binds     = 0
    }
}

# <deviceoptions name="..."><option input="rotx" deadzone="0.19"/></deviceoptions>
foreach ($d in $root.SelectNodes('deviceoptions')) {
    $p = Split-Product $d.GetAttribute('name')
    $target = $null
    foreach ($k in $devices.Keys) {
        if ($p.guid -and $devices[$k].guid -eq $p.guid) { $target = $devices[$k]; break }
    }
    if (-not $target) {
        foreach ($k in $devices.Keys) {
            if ($devices[$k].name -eq $p.name) { $target = $devices[$k]; break }
        }
    }
    if (-not $target) { continue }
    foreach ($opt in $d.SelectNodes('option')) {
        $target.deadzones[$opt.GetAttribute('input')] = Get-Attrs $opt
    }
}

$binds   = @()
$cleared = @()

foreach ($am in $root.SelectNodes('actionmap')) {
    $mapName = $am.GetAttribute('name')
    foreach ($ac in $am.SelectNodes('action')) {
        $acName = $ac.GetAttribute('name')
        foreach ($rb in $ac.SelectNodes('rebind')) {
            $inp = Split-Input $rb.GetAttribute('input')
            $layer = 'base'
            if (@($inp.modifiers).Count) { $layer = (@($inp.modifiers) -join '+') }
            $entry = [ordered]@{
                actionmap      = $mapName
                action         = $acName
                device         = $inp.deviceTag
                deviceType     = $inp.deviceType
                control        = $inp.control
                kind           = $inp.kind
                number         = $inp.number
                modifiers      = @($inp.modifiers)
                layer          = $layer
                activationMode = $rb.GetAttribute('activationMode')
                multiTap       = $rb.GetAttribute('multiTap')
                input          = $inp.raw
            }
            if ($inp.kind -eq 'cleared') { $cleared += $entry } else { $binds += $entry }
            if ($inp.deviceTag -and $devices.Contains($inp.deviceTag)) { $devices[$inp.deviceTag].binds++ }
        }
    }
}

# Entrees partagees : meme bouton/axe portant plusieurs actions dans la meme
# actionmap. Pas forcement un conflit : Star Citizen definit les modes
# d'activation (appui court / long / double) dans son profil par defaut, que
# l'export ne reproduit que s'ils ont ete modifies. A relire au cas par cas.
$dupes = @()
$groups = $binds | Where-Object { $_.deviceType -eq 'joystick' } |
          Group-Object { "$($_.actionmap)|$($_.input)" } | Where-Object { $_.Count -gt 1 }
foreach ($g in $groups) {
    $dupes += [ordered]@{
        actionmap = $g.Group[0].actionmap
        input     = $g.Group[0].input
        actions   = @($g.Group | ForEach-Object { $_.action })
    }
}

$bindingsOut = [ordered]@{
    generatedBy = 'tools/parse-sc-layout.ps1'
    source      = [ordered]@{
        file          = Split-Path -Leaf $layoutPath
        path          = $layoutPath
        modified      = (Get-Item $layoutPath).LastWriteTime.ToString('yyyy-MM-dd HH:mm')
        profileName   = $root.GetAttribute('profileName')
        version       = $root.GetAttribute('version')
        rebindVersion = $root.GetAttribute('rebindVersion')
    }
    devices    = $devices
    layers     = @($binds | ForEach-Object { $_.layer } | Sort-Object -Unique)
    counts     = [ordered]@{
        binds        = $binds.Count
        cleared      = $cleared.Count
        sharedInputs = $dupes.Count
    }
    sharedNote   = 'Entrees portant plusieurs actions. Souvent legitime (appui court / long defini par le profil par defaut du jeu), a verifier au cas par cas.'
    sharedInputs = $dupes
    cleared    = @($cleared | ForEach-Object { "$($_.actionmap)/$($_.action)" })
    binds      = $binds
}

# ------------------------------------------------- 2. catalogue des actions

$catalog = [ordered]@{}
foreach ($f in $catalogFiles) {
    try { $d = Read-LayoutXml $f } catch { Write-Warning "Illisible, ignore : $f"; continue }
    $leaf = Split-Path -Leaf $f
    foreach ($am in $d.DocumentElement.SelectNodes('actionmap')) {
        $mapName = $am.GetAttribute('name')
        foreach ($ac in $am.SelectNodes('action')) {
            $n = $ac.GetAttribute('name')
            if (-not $catalog.Contains($n)) {
                $catalog[$n] = [ordered]@{ actionmaps = @(); sources = @(); current = $false }
            }
            if ($catalog[$n].actionmaps -notcontains $mapName) { $catalog[$n].actionmaps += $mapName }
            if ($catalog[$n].sources    -notcontains $leaf)    { $catalog[$n].sources    += $leaf }
            if ($f -eq $layoutPath) { $catalog[$n].current = $true }
        }
    }
}

$sortedCatalog = [ordered]@{}
$currentCount = 0
foreach ($k in ($catalog.Keys | Sort-Object)) {
    $sortedCatalog[$k] = $catalog[$k]
    if ($catalog[$k].current) { $currentCount++ }
}

$actionsOut = [ordered]@{
    generatedBy  = 'tools/parse-sc-layout.ps1'
    note         = 'Catalogue brut, regenere a chaque execution. Les libelles francais sont dans sc-labels-fr.json.'
    scannedFiles = @($catalogFiles | ForEach-Object { Split-Path -Leaf $_ } | Sort-Object -Unique)
    counts       = [ordered]@{ total = $sortedCatalog.Count; current = $currentCount }
    actions      = $sortedCatalog
}

# ------------------------------------------------------------- ecriture

if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }

$bindingsPath = Join-Path $OutDir 'sc-bindings.json'
$actionsPath  = Join-Path $OutDir 'sc-actions.json'

$bindingsOut | ConvertTo-Json -Depth 12 | Out-File -FilePath $bindingsPath -Encoding utf8
$actionsOut  | ConvertTo-Json -Depth 12 | Out-File -FilePath $actionsPath  -Encoding utf8

Write-Host ''
Write-Host 'Peripheriques du layout courant :' -ForegroundColor Cyan
foreach ($k in $devices.Keys) {
    $d = $devices[$k]
    '{0,-4} {1,-9} {2,-32} {3,-42} {4,4} binds' -f $d.tag, $d.type, $d.name, $d.guid, $d.binds | Write-Host
}
Write-Host ''
Write-Host ('Couches       : ' + ($bindingsOut.layers -join ', '))
Write-Host ('Binds         : {0}   (efface : {1})' -f $binds.Count, $cleared.Count)
if ($dupes.Count) {
    Write-Host ('Entrees partagees : {0}  (appui court/long ? a verifier)' -f $dupes.Count) -ForegroundColor Yellow
    foreach ($x in $dupes) { '   {0} {1} -> {2}' -f $x.actionmap, $x.input, ($x.actions -join ', ') | Write-Host }
} else {
    Write-Host 'Entrees partagees : aucune'
}
Write-Host ('Catalogue     : {0} actions ({1} dans le layout courant), {2} fichiers balayes' -f `
    $actionsOut.counts.total, $actionsOut.counts.current, $actionsOut.scannedFiles.Count)
Write-Host ''
Write-Host "Ecrit : $bindingsPath" -ForegroundColor Green
Write-Host "Ecrit : $actionsPath"  -ForegroundColor Green
