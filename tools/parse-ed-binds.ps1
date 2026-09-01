<#
    parse-ed-binds.ps1 — Elite Dangerous : fichier .binds -> JSON

    Lit le fichier de bindings ecrit par le jeu
    (%LOCALAPPDATA%\Frontier Developments\Elite Dangerous\Options\Bindings\
    Custom.4.x.binds) et produit deux fichiers JSON consommes par les pages du
    dossier ED\ :

      ED\data\ed-bindings.json  binds du preset courant (peripheriques, axes,
                                boutons, modificateurs, appui long, inversion,
                                zones mortes, reglages Value=)
      ED\data\ed-actions.json   catalogue de TOUTES les actions du schema du
                                jeu, avec leur nature et leur contexte

    Particularite d'Elite Dangerous : le .binds contient l'integralite du
    schema, y compris les actions non assignees (Device="{NoDevice}"). Le
    catalogue est donc complet des la premiere lecture, contrairement a Star
    Citizen ou seul le modifie est exporte.

    Les deux fichiers sont REGENERES a chaque execution : ne jamais les editer
    a la main. Les libelles francais vivent dans ED\data\ed-labels-fr.json,
    qui n'est pas touche par ce script.

    Usage :
      powershell -ExecutionPolicy Bypass -File tools\parse-ed-binds.ps1
      powershell ... -Binds "Custom.4.2.binds"
      powershell ... -Binds "D:\sauvegarde\Custom.4.2.binds" -OutDir .\ED\data

    NOTE ENVIRONNEMENT : ecrit pour rester compatible PowerShell 5.1 (aucun
    operateur ternaire, aucune List[T] passee a @(...)).
#>

[CmdletBinding()]
param(
    # Dossier des bindings du jeu.
    [string]$BindsDir = "$env:LOCALAPPDATA\Frontier Developments\Elite Dangerous\Options\Bindings",

    # Nom (ou chemin complet) du .binds a lire. Par defaut : le preset actif
    # declare dans StartPreset.*.start, sinon le .binds le plus recent.
    [string]$Binds,

    # Dossier de sortie des JSON.
    [string]$OutDir
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
if (-not $OutDir) { $OutDir = Join-Path $repoRoot 'ED\data' }

# ---------------------------------------------------------------- utilitaires

# Contexte de jeu deduit du nom d'action. Elite Dangerous n'a pas d'actionmap
# declaree dans le fichier : c'est le NOM qui porte le contexte, par prefixe ou
# par suffixe. Un meme bouton physique peut donc porter une action differente
# dans chaque contexte sans aucun modificateur.
function Get-EdContext([string]$name) {
    switch -Regex ($name) {
        '_Buggy$'                                   { return 'srv' }
        '^Buggy'                                    { return 'srv' }
        '^(Steer|DriveSpeedAxis|AutoBreak|ToggleDriveAssist|HeadlightsBuggy|EjectAllCargo_Buggy)' { return 'srv' }
        '^Humanoid'                                 { return 'apied' }
        '_Humanoid$'                                { return 'apied' }
        'OnFoot$'                                   { return 'apied' }
        '^MultiCrew'                                { return 'equipage' }
        '^Order'                                    { return 'equipage' }
        '^(ExplorationFSS|FSS)'                     { return 'fss' }
        'SAA'                                       { return 'dss' }
        '^(MovePlacementCam|PitchPlacementCam|YawPlacementCam|PlacementCam|PlaceSettlement|RotateSettlement|ChangeConstructionOption|TriggerColonisationModule|ExitSettlementPlacementCamera)' { return 'colonisation' }
        '^(Cam|FreeCam|MoveFreeCam|VanityCamera|PhotoCameraToggle|QuitCamera|FStop|FixCamera|ToggleFreeCam|StoreCam|StorePitch|StoreYaw|StoreEnableRotation|StoreToggle|CommanderCreator)' { return 'camera' }
        '^(UI_|Focus|CycleNextPanel|CyclePreviousPanel|CycleNextPage|CyclePreviousPage|GalaxyMap|SystemMap|QuickCommsPanel|OpenCodex|OpenOrders|FriendsMenu|Pause|ShowPGScore)' { return 'interface' }
        '^(HeadLook|Headlook|yawRotateHeadlook|MotionHeadlook|HMDReset)' { return 'vue' }
        '^Mouse'                                    { return 'souris' }
        default                                     { return 'vaisseau' }
    }
}

# Couche d'axes de vol. Elite Dangerous fournit nativement trois jeux d'axes
# pilote : normal, "atterrissage" (bascule automatique train sorti) et
# "alternatif" (bascule manuelle par UseAlternateFlightValuesToggle).
function Get-EdLayer([string]$name) {
    if ($name -match '_Landing$')  { return 'atterrissage' }
    if ($name -match 'Alternate$') { return 'alternatif' }
    if ($name -match '_FAOff$')    { return 'fa-off' }
    return 'normal'
}

# "Joy_31" -> numero 31 ; "Joy_POV1Up" -> POV ; "Pos_Joy_UAxis" -> demi-axe
function Split-EdKey([string]$key) {
    $res = [ordered]@{ raw = $key; kind = ''; number = $null; axis = ''; pov = '' }
    if ([string]::IsNullOrWhiteSpace($key)) { $res.kind = 'vide'; return $res }
    switch -Regex ($key) {
        '^Joy_(\d+)$'                     { $res.kind = 'bouton'; $res.number = [int]$Matches[1] }
        '^Joy_POV(\d+)(Up|Down|Left|Right)$' { $res.kind = 'pov'; $res.pov = $Matches[0] }
        '^(Pos|Neg)_Joy_([A-Z]+)Axis$'    { $res.kind = 'demi-axe'; $res.axis = $Matches[2] }
        '^Joy_([A-Z]+)Axis$'              { $res.kind = 'axe'; $res.axis = $Matches[1] }
        '^Key_'                           { $res.kind = 'clavier' }
        '^Mouse'                          { $res.kind = 'souris' }
        default                           { $res.kind = 'autre' }
    }
    return $res
}

# ------------------------------------------------------- choix du fichier

if ($Binds) {
    if (Test-Path $Binds) { $bindsPath = (Resolve-Path $Binds).Path }
    else { $bindsPath = Join-Path $BindsDir $Binds }
} else {
    if (-not (Test-Path $BindsDir)) {
        throw "Dossier Bindings introuvable : $BindsDir. Verifier -BindsDir."
    }
    $bindsPath = $null

    # StartPreset.*.start : une ligne par groupe de controles, toutes egales au
    # nom du preset actif tant qu'on n'a pas melange les presets.
    $startFile = Get-ChildItem -Path $BindsDir -Filter 'StartPreset*.start' |
                 Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($startFile) {
        $presetNames = @(Get-Content $startFile.FullName |
                         ForEach-Object { $_.Trim() } |
                         Where-Object { $_ } | Select-Object -Unique)
        foreach ($p in $presetNames) {
            $cand = @(Get-ChildItem -Path $BindsDir -Filter "$p.*.binds" |
                      Sort-Object LastWriteTime -Descending)
            if ($cand.Count) { $bindsPath = $cand[0].FullName; break }
        }
        if ($presetNames.Count -gt 1) {
            Write-Warning ("StartPreset melange plusieurs presets : " + ($presetNames -join ', '))
        }
    }
    if (-not $bindsPath) {
        $newest = Get-ChildItem -Path $BindsDir -Filter '*.binds' |
                  Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if (-not $newest) { throw "Aucun .binds dans $BindsDir. Sauvegarder un preset depuis le jeu d'abord." }
        $bindsPath = $newest.FullName
    }
}
if (-not (Test-Path $bindsPath)) { throw "Fichier .binds introuvable : $bindsPath" }

Write-Host "Preset courant : $bindsPath" -ForegroundColor Cyan

$doc = New-Object System.Xml.XmlDocument
$doc.PreserveWhitespace = $false
$doc.Load($bindsPath)
$root = $doc.DocumentElement

# ------------------------------------------------- lecture des actions

$devices  = [ordered]@{}
$bindList    = @()
$settings = [ordered]@{}
$catalog  = [ordered]@{}

function Add-Device([string]$dev) {
    if (-not $dev -or $dev -eq '{NoDevice}') { return }
    if (-not $devices.Contains($dev)) {
        $vendorId  = ''
        $productId = ''
        if ($dev -match '^([0-9A-Fa-f]{4})([0-9A-Fa-f]{4})$') {
            $vendorId  = $Matches[1].ToUpper()
            $productId = $Matches[2].ToUpper()
        }
        $devices[$dev] = [ordered]@{
            device  = $dev
            vid     = $vendorId
            pid     = $productId
            axes    = 0
            buttons = 0
            binds   = 0
        }
    }
}

foreach ($node in $root.ChildNodes) {
    if ($node.NodeType -ne 'Element') { continue }
    $name = $node.Name

    # <KeyboardLayout>en-GB</KeyboardLayout> et <XxxMode Value="..." />
    $hasValue = $node.HasAttribute('Value')
    $childElems = @($node.ChildNodes | Where-Object { $_.NodeType -eq 'Element' })

    if ($hasValue -and -not $childElems.Count) {
        $settings[$name] = $node.GetAttribute('Value')
        $catalog[$name] = [ordered]@{
            kind = 'reglage'; context = (Get-EdContext $name); layer = (Get-EdLayer $name); toggleable = $false
        }
        continue
    }
    if (-not $childElems.Count) {
        $settings[$name] = $node.InnerText
        $catalog[$name] = [ordered]@{
            kind = 'reglage'; context = (Get-EdContext $name); layer = (Get-EdLayer $name); toggleable = $false
        }
        continue
    }

    $isAxis = $false
    $toggleable = $false
    foreach ($c in $childElems) {
        if ($c.Name -eq 'Binding')  { $isAxis = $true }
        if ($c.Name -eq 'ToggleOn') { $toggleable = $true }
    }

    $kind = 'bouton'
    if ($isAxis) { $kind = 'axe' }

    $catalog[$name] = [ordered]@{
        kind       = $kind
        context    = (Get-EdContext $name)
        layer      = (Get-EdLayer $name)
        toggleable = $toggleable
    }

    $inverted = $null
    $deadzone = $null
    $toggleOn = $null
    foreach ($c in $childElems) {
        if ($c.Name -eq 'Inverted') { $inverted = $c.GetAttribute('Value') }
        if ($c.Name -eq 'Deadzone') { $deadzone = $c.GetAttribute('Value') }
        if ($c.Name -eq 'ToggleOn') { $toggleOn = $c.GetAttribute('Value') }
    }

    foreach ($c in $childElems) {
        if ($c.Name -ne 'Binding' -and $c.Name -ne 'Primary' -and $c.Name -ne 'Secondary') { continue }
        $dev = $c.GetAttribute('Device')
        $key = $c.GetAttribute('Key')
        if (-not $dev -or $dev -eq '{NoDevice}' -or [string]::IsNullOrWhiteSpace($key)) { continue }

        Add-Device $dev
        $k = Split-EdKey $key

        # <Modifier Device="..." Key="..."/> : le modificateur peut vivre sur un
        # AUTRE peripherique que la touche modifiee (maintenir un bouton du
        # manche gauche pour changer le sens d'un bouton du manche droit).
        $mods = @()
        foreach ($m in $c.ChildNodes) {
            if ($m.NodeType -ne 'Element' -or $m.Name -ne 'Modifier') { continue }
            Add-Device $m.GetAttribute('Device')
            $mods += ('{0}/{1}' -f $m.GetAttribute('Device'), $m.GetAttribute('Key'))
        }
        $hold = $false
        foreach ($m in $c.ChildNodes) {
            if ($m.NodeType -eq 'Element' -and $m.Name -eq 'Hold' -and $m.GetAttribute('Value') -eq '1') { $hold = $true }
        }

        $layerName = 'base'
        if ($mods.Count) { $layerName = ($mods -join '+') }

        $bindList += [ordered]@{
            action    = $name
            kind      = $kind
            context   = (Get-EdContext $name)
            flightLayer = (Get-EdLayer $name)
            slot      = $c.Name          # Binding (axe) / Primary / Secondary
            device    = $dev
            key       = $key
            keyKind   = $k.kind
            number    = $k.number
            axis      = $k.axis
            modifiers = @($mods)
            layer     = $layerName
            hold      = $hold
            toggleOn  = $toggleOn
            inverted  = $inverted
            deadzone  = $deadzone
        }

        $devices[$dev].binds++
        if ($k.kind -eq 'axe')    { $devices[$dev].axes++ }
        if ($k.kind -eq 'bouton') { $devices[$dev].buttons++ }
    }
}

# ------------------------------------------------- conflits reels

# Deux actions du MEME contexte sur la meme entree physique et la meme couche
# de modificateur : conflit que le jeu signale en rouge. Le meme bouton dans
# deux contextes differents (vaisseau et SRV) est legitime et attendu.
$dupes = @()
$joyBinds = @($bindList | Where-Object { $_.keyKind -eq 'bouton' -or $_.keyKind -eq 'pov' -or $_.keyKind -eq 'demi-axe' })
$groups = $joyBinds | Group-Object { '{0}|{1}|{2}|{3}' -f $_.context, $_.device, $_.key, $_.layer } |
          Where-Object { $_.Count -gt 1 }
foreach ($g in $groups) {
    $acts = @($g.Group | ForEach-Object { $_.action } | Sort-Object -Unique)
    if ($acts.Count -lt 2) { continue }
    $dupes += [ordered]@{
        context = $g.Group[0].context
        device  = $g.Group[0].device
        key     = $g.Group[0].key
        layer   = $g.Group[0].layer
        actions = $acts
    }
}

# ------------------------------------------------- comptages par contexte

$byContext = [ordered]@{}
foreach ($c in ($catalog.Keys | ForEach-Object { $catalog[$_].context } | Sort-Object -Unique)) {
    $total = @($catalog.Keys | Where-Object { $catalog[$_].context -eq $c }).Count
    $bound = @($bindList | Where-Object { $_.context -eq $c } | ForEach-Object { $_.action } | Sort-Object -Unique).Count
    $byContext[$c] = [ordered]@{ actions = $total; assignees = $bound }
}

$bindingsOut = [ordered]@{
    generatedBy = 'tools/parse-ed-binds.ps1'
    source      = [ordered]@{
        file         = Split-Path -Leaf $bindsPath
        path         = $bindsPath
        modified     = (Get-Item $bindsPath).LastWriteTime.ToString('yyyy-MM-dd HH:mm')
        presetName   = $root.GetAttribute('PresetName')
        majorVersion = $root.GetAttribute('MajorVersion')
        minorVersion = $root.GetAttribute('MinorVersion')
    }
    deviceNote = "Elite Dangerous designe un peripherique par une chaine VID+PID hexadecimale (3344012F = VID 3344 Virpil, PID 012F) ou par un nom convivial declare dans ControlSchemes\DeviceMappings.xml. Deux exemplaires du meme modele portent le meme VID+PID : leur donner deux PID distincts dans l'outil Virpil est la seule facon fiable de les distinguer."
    devices    = $devices
    layers     = @($bindList | ForEach-Object { $_.layer } | Sort-Object -Unique)
    counts     = [ordered]@{
        actions   = $catalog.Count
        binds     = $bindList.Count
        conflits  = $dupes.Count
    }
    byContext  = $byContext
    conflitNote = 'Deux actions du meme contexte sur la meme entree et la meme couche : conflit signale en rouge par le jeu. Le meme bouton dans deux contextes differents est normal.'
    conflits   = $dupes
    settings   = $settings
    binds      = $bindList
}

$actionsOut = [ordered]@{
    generatedBy = 'tools/parse-ed-binds.ps1'
    note        = "Catalogue brut du schema de bindings du jeu, regenere a chaque execution. Elite Dangerous ecrit TOUTES les actions dans le .binds, y compris non assignees : le catalogue est donc exhaustif. Les libelles francais sont dans ed-labels-fr.json."
    source      = [ordered]@{
        file         = Split-Path -Leaf $bindsPath
        presetName   = $root.GetAttribute('PresetName')
        majorVersion = $root.GetAttribute('MajorVersion')
        minorVersion = $root.GetAttribute('MinorVersion')
    }
    counts      = [ordered]@{
        total    = $catalog.Count
        axes     = @($catalog.Keys | Where-Object { $catalog[$_].kind -eq 'axe' }).Count
        boutons  = @($catalog.Keys | Where-Object { $catalog[$_].kind -eq 'bouton' }).Count
        reglages = @($catalog.Keys | Where-Object { $catalog[$_].kind -eq 'reglage' }).Count
        maintien = @($catalog.Keys | Where-Object { $catalog[$_].toggleable }).Count
    }
    maintienNote = "Les actions marquees toggleable portent un <ToggleOn> : elles seules acceptent le choix bascule / maintien. Toutes les autres commandes 'Toggle' du jeu (train, feux, points durs) sont des bascules pures, sans commande ON et OFF separees : un inverseur physique maintenu se desynchronise des que le jeu change l'etat tout seul."
    actions      = $catalog
}

# ------------------------------------------------------------- ecriture

if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }

$bindingsPath = Join-Path $OutDir 'ed-bindings.json'
$actionsPath  = Join-Path $OutDir 'ed-actions.json'

$bindingsOut | ConvertTo-Json -Depth 12 | Out-File -FilePath $bindingsPath -Encoding utf8
$actionsOut  | ConvertTo-Json -Depth 12 | Out-File -FilePath $actionsPath  -Encoding utf8

Write-Host ''
Write-Host 'Peripheriques vus dans le preset :' -ForegroundColor Cyan
foreach ($k in $devices.Keys) {
    $d = $devices[$k]
    $ident = $d.device
    if ($d.vid) { $ident = '{0}  (VID {1} / PID {2})' -f $d.device, $d.vid, $d.pid }
    '{0,-40} {1,3} axes {2,4} boutons {3,4} binds' -f $ident, $d.axes, $d.buttons, $d.binds | Write-Host
}
Write-Host ''
Write-Host ('Actions du schema : {0}   ({1} axes, {2} boutons, {3} reglages)' -f `
    $actionsOut.counts.total, $actionsOut.counts.axes, $actionsOut.counts.boutons, $actionsOut.counts.reglages)
Write-Host ('Binds assignes    : {0}' -f $bindList.Count)
Write-Host ('Couches           : ' + ($bindingsOut.layers -join ', '))
Write-Host ''
Write-Host 'Par contexte :' -ForegroundColor Cyan
foreach ($c in $byContext.Keys) {
    '  {0,-14} {1,4} actions, {2,4} assignees' -f $c, $byContext[$c].actions, $byContext[$c].assignees | Write-Host
}
Write-Host ''
if ($dupes.Count) {
    Write-Host ('Conflits reels : {0}' -f $dupes.Count) -ForegroundColor Yellow
    foreach ($x in $dupes) {
        '   [{0}] {1} {2} ({3}) -> {4}' -f $x.context, $x.device, $x.key, $x.layer, ($x.actions -join ', ') | Write-Host
    }
} else {
    Write-Host 'Conflits reels : aucun' -ForegroundColor Green
}
Write-Host ''
Write-Host "Ecrit : $bindingsPath" -ForegroundColor Green
Write-Host "Ecrit : $actionsPath"  -ForegroundColor Green
