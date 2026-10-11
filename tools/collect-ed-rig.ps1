<#
    collect-ed-rig.ps1 - Elite Dangerous : releve du rig en une seule passe

    A lancer AVANT la session de travail sur le mapping. Le script rassemble
    tout ce qu'il faut pour ecrire des binds sans poser une seule question :

      1. sauvegarde le dossier Bindings du jeu (zip horodate) ;
      2. liste les presets .binds et designe le preset ACTIF ;
      3. releve les peripheriques vus par le JEU dans ce preset, avec pour
         chacun le plus grand numero de bouton et la liste des axes utilises ;
      4. enumere les manettes branchees cote Windows pour reperer deux
         peripheriques qui partagent la meme chaine VID+PID -- la panne
         bloquante du HOSAS ;
      5. compare au releve precedent et affiche les binds APPARUS depuis :
         c'est la boucle de sondage ("assigner une commande jetable dans
         l'ecran Controles, quitter proprement, relancer le script").

    Sortie : ED\data\releve-rig.json  (+ resume lisible en console)

    AUTORITE DES DONNEES. Le fichier .binds ecrit par le jeu fait foi : c'est
    lui qui dit comment le jeu nomme un peripherique et jusqu'a quel numero de
    bouton il le lit. L'enumeration Windows (section "windows" du JSON) est
    INDICATIVE et ne sert qu'a une chose : voir les paires VID+PID en double
    avant de lancer le jeu, et confirmer qu'un changement de PID a bien pris.
    Ne jamais en deduire un nom de peripherique a ecrire dans un bind.

    Pourquoi VID+PID et pas un GUID : Elite Dangerous designe un peripherique
    par Device="33440 12F" (sans espace) = fabricant 3344 + produit 012F, pas
    par un GUID DirectInput comme DCS. Deux Alpha Prime sortis d'usine portent
    donc la meme chaine et le jeu les confond.

    Usage :
      powershell -ExecutionPolicy Bypass -File tools\collect-ed-rig.ps1
      powershell ... -BindsDir "D:\autre\Bindings"
      powershell ... -NoBackup          (ne pas zipper le dossier Bindings)

    NOTE ENVIRONNEMENT : compatible PowerShell 5.1 (aucun operateur ternaire,
    aucun operateur de coalescence, aucune List[T] passee a @(...)).
#>

[CmdletBinding()]
param(
    # Dossier des bindings du jeu.
    [string]$BindsDir = "$env:LOCALAPPDATA\Frontier Developments\Elite Dangerous\Options\Bindings",

    # Dossier de sortie du JSON de releve.
    [string]$OutDir,

    # Ou deposer le zip de sauvegarde du dossier Bindings.
    [string]$BackupDir = "$env:USERPROFILE\Documents\Claude\ED-sauvegardes",

    # Ne pas sauvegarder (deconseille).
    [switch]$NoBackup
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
if (-not $OutDir) { $OutDir = Join-Path $repoRoot 'ED\data' }
$outPath = Join-Path $OutDir 'releve-rig.json'

function Say($msg, $color) {
    if ($color) { Write-Host $msg -ForegroundColor $color } else { Write-Host $msg }
}

Say "" ; Say "=== Releve du rig Elite Dangerous ===" 'Cyan' ; Say ""

if (-not (Test-Path $BindsDir)) {
    throw "Dossier des bindings introuvable : $BindsDir`nLancer le jeu une fois et sauvegarder un preset depuis l'ecran Controles."
}
Say "Dossier des bindings : $BindsDir"

# ------------------------------------------------------------- 1. sauvegarde

$backup = $null
if (-not $NoBackup) {
    if (-not (Test-Path $BackupDir)) { New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null }
    $stamp = Get-Date -Format 'yyyy-MM-dd_HHmmss'
    $backup = Join-Path $BackupDir "Bindings_$stamp.zip"
    Compress-Archive -Path (Join-Path $BindsDir '*') -DestinationPath $backup -Force
    Say "Sauvegarde : $backup" 'Green'
} else {
    Say "Sauvegarde ignoree (-NoBackup)" 'Yellow'
}

# ---------------------------------------------------- 2. presets et preset actif

$presetFiles = @(Get-ChildItem -Path $BindsDir -Filter '*.binds' | Sort-Object LastWriteTime -Descending)
if (-not $presetFiles.Count) {
    throw "Aucun .binds dans $BindsDir. Sauvegarder un preset depuis le jeu d'abord."
}

$presets = @()
foreach ($f in $presetFiles) {
    $major = '' ; $minor = '' ; $name = ''
    try {
        $x = New-Object System.Xml.XmlDocument
        $x.Load($f.FullName)
        $name  = $x.DocumentElement.GetAttribute('PresetName')
        $major = $x.DocumentElement.GetAttribute('MajorVersion')
        $minor = $x.DocumentElement.GetAttribute('MinorVersion')
    } catch {
        Write-Warning ("XML illisible : " + $f.Name)
    }
    $presets += [pscustomobject]@{
        fichier  = $f.Name
        preset   = $name
        schema   = "$major.$minor"
        modifie  = $f.LastWriteTime.ToString('s')
        tailleKo = [math]::Round($f.Length / 1024, 1)
    }
}

# StartPreset.*.start : une ligne par groupe de controles, toutes egales au nom
# du preset actif tant qu'on n'a pas melange les presets.
$activePath = $null
$startNames = @()
$startFile = Get-ChildItem -Path $BindsDir -Filter 'StartPreset*.start' -ErrorAction SilentlyContinue |
             Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($startFile) {
    $startNames = @(Get-Content $startFile.FullName |
                    ForEach-Object { $_.Trim() } |
                    Where-Object { $_ } | Select-Object -Unique)
    foreach ($p in $startNames) {
        $cand = @(Get-ChildItem -Path $BindsDir -Filter "$p.*.binds" -ErrorAction SilentlyContinue |
                  Sort-Object LastWriteTime -Descending)
        if ($cand.Count) { $activePath = $cand[0].FullName ; break }
    }
    if ($startNames.Count -gt 1) {
        Write-Warning ("StartPreset melange plusieurs presets : " + ($startNames -join ', '))
    }
}
if (-not $activePath) {
    $activePath = $presetFiles[0].FullName
    Write-Warning "Preset actif non declare : on prend le .binds le plus recent."
}

$activeName = Split-Path -Leaf $activePath
Say "" ; Say "Presets trouves : $($presets.Count)"
foreach ($p in $presets) {
    $mark = '   '
    if ($p.fichier -eq $activeName) { $mark = ' > ' }
    Say ("{0}{1,-28} preset={2,-18} schema={3,-6} {4}" -f $mark, $p.fichier, $p.preset, $p.schema, $p.modifie)
}
Say "Preset actif : $activeName" 'Cyan'

# ------------------------------------- 3. peripheriques vus par le jeu

$doc = New-Object System.Xml.XmlDocument
$doc.Load($activePath)

$schemaMajor = $doc.DocumentElement.GetAttribute('MajorVersion')
$schemaMinor = $doc.DocumentElement.GetAttribute('MinorVersion')

# Un dictionnaire par peripherique : nb d'entrees, plus grand bouton, axes,
# POV, et les actions portees (utile pour reperer un bind de sondage).
$devices = @{}

function Touch-Device([string]$dev) {
    if (-not $devices.ContainsKey($dev)) {
        $devices[$dev] = [pscustomobject]@{
            device        = $dev
            vid           = ''
            pid           = ''
            entrees       = 0
            boutonMax     = 0
            boutons       = @()
            axes          = @()
            pov           = @()
            autresTouches = @()
            actions       = @()
        }
        if ($dev -match '^([0-9A-Fa-f]{4})([0-9A-Fa-f]{4})$') {
            $devices[$dev].vid = $Matches[1].ToUpper()
            $devices[$dev].pid = $Matches[2].ToUpper()
        }
    }
    return $devices[$dev]
}

# Toutes les entrees assignees du fichier, a plat : un objet par couple
# (action, slot) reellement lie a un peripherique.
$entries = @()

foreach ($action in $doc.DocumentElement.ChildNodes) {
    if ($action.NodeType -ne 'Element') { continue }
    foreach ($slot in $action.ChildNodes) {
        if ($slot.NodeType -ne 'Element') { continue }
        if ($slot.Name -notin @('Binding', 'Primary', 'Secondary')) { continue }

        $dev = $slot.GetAttribute('Device')
        $key = $slot.GetAttribute('Key')
        if (-not $dev -or $dev -eq '{NoDevice}' -or -not $key) { continue }

        $d = Touch-Device $dev
        $d.entrees++
        if ($d.actions -notcontains $action.Name) { $d.actions += $action.Name }

        if ($key -match '^Joy_(\d+)$') {
            $n = [int]$Matches[1]
            if ($n -gt $d.boutonMax) { $d.boutonMax = $n }
            if ($d.boutons -notcontains $n) { $d.boutons += $n }
        }
        elseif ($key -match '^Joy_POV\d+(Up|Down|Left|Right)$') {
            if ($d.pov -notcontains $key) { $d.pov += $key }
        }
        elseif ($key -match '^(Pos_|Neg_)?Joy_[A-Z]+Axis$') {
            if ($d.axes -notcontains $key) { $d.axes += $key }
        }
        else {
            if ($d.autresTouches -notcontains $key) { $d.autresTouches += $key }
        }

        # Modificateur(s) eventuel(s) : peuvent venir d'un AUTRE peripherique.
        $mods = @()
        foreach ($m in $slot.ChildNodes) {
            if ($m.NodeType -eq 'Element' -and $m.Name -eq 'Modifier') {
                $md = $m.GetAttribute('Device')
                $mk = $m.GetAttribute('Key')
                $mods += "$md/$mk"
                if ($md -and $md -ne '{NoDevice}') { (Touch-Device $md) | Out-Null }
            }
        }

        $entries += [pscustomobject]@{
            action = $action.Name
            slot   = $slot.Name
            device = $dev
            key    = $key
            mods   = ($mods -join '+')
        }
    }
}

$devList = @($devices.Values | Sort-Object -Property @{Expression = 'entrees'; Descending = $true})
foreach ($d in $devList) {
    $d.boutons = @($d.boutons | Sort-Object)
    $d.axes    = @($d.axes    | Sort-Object)
    $d.pov     = @($d.pov     | Sort-Object)
}

Say "" ; Say "Peripheriques vus par le jeu dans ce preset : $($devList.Count)" 'Cyan'
foreach ($d in $devList) {
    Say ("  {0,-14} entrees={1,-4} boutonMax={2,-4} axes={3}" -f $d.device, $d.entrees, $d.boutonMax, ($d.axes -join ','))
}
if ($devList.Count -lt 4) {
    Say "" ; Say "  Moins de 4 peripheriques : assigner une commande sur CHAQUE" 'Yellow'
    Say "  peripherique depuis l'ecran Controles, quitter proprement, relancer." 'Yellow'
}

# --------------------------- 4. enumeration Windows (INDICATIVE) et doublons

$windows = @()
$dupWarn = @()
$winOk = $false
try {
    $hid = @(Get-CimInstance -ClassName Win32_PNPEntity -ErrorAction Stop |
             Where-Object { $_.PNPDeviceID -match 'VID_([0-9A-Fa-f]{4})&PID_([0-9A-Fa-f]{4})' } |
             Where-Object { $_.PNPClass -eq 'HIDClass' -or $_.Service -eq 'HidUsb' -or $_.Name -match 'joystick|game|HID-compliant' })

    $seen = @{}
    foreach ($h in $hid) {
        if ($h.PNPDeviceID -notmatch 'VID_([0-9A-Fa-f]{4})&PID_([0-9A-Fa-f]{4})') { continue }
        $vendorId  = $Matches[1].ToUpper()
        $productId = $Matches[2].ToUpper()
        $edDevice  = "$vendorId$productId"
        $key = $h.PNPDeviceID
        if ($seen.ContainsKey($key)) { continue }
        $seen[$key] = $true
        $windows += [pscustomobject]@{
            nom        = $h.Name
            vid        = $vendorId
            pid        = $productId
            edDevice   = $edDevice
            instance   = $h.PNPDeviceID
        }
    }

    # Deux instances physiques differentes sous la meme chaine VID+PID = le jeu
    # ne pourra pas les distinguer. C'est LA panne bloquante du HOSAS.
    $groups = $windows | Group-Object -Property edDevice | Where-Object { $_.Count -gt 1 }
    foreach ($g in $groups) { $dupWarn += $g.Name }
    $winOk = $true
} catch {
    Write-Warning "Enumeration Windows indisponible : $($_.Exception.Message)"
}

Say "" ; Say "Manettes vues par Windows (indicatif) : $($windows.Count)"
foreach ($w in $windows) {
    Say ("  {0,-10} {1}" -f $w.edDevice, $w.nom)
}

Say ""
if (-not $winOk) {
    Say "Doublon VID+PID : INDETERMINE (enumeration Windows indisponible)." 'Yellow'
    Say "A verifier a la main : si les deux Alpha Prime portent la meme chaine," 'Yellow'
    Say "le jeu les confondra. Les peripheriques listes plus haut par le JEU" 'Yellow'
    Say "font foi : s'il n'en voit que trois alors que quatre sont branches et" 'Yellow'
    Say "assignes, c'est exactement ce symptome." 'Yellow'
}
elseif ($dupWarn.Count) {
    Say "BLOQUANT : chaine VID+PID en double -> $($dupWarn -join ', ')" 'Red'
    Say "Elite Dangerous ne pourra pas distinguer ces peripheriques : un bind" 'Red'
    Say "pose sur l'un vaudra pour l'autre. Ouvrir le VPC Configuration Tool," 'Red'
    Say "onglet Profile, changer le PID de l'un des deux manches, ecrire le" 'Red'
    Say "firmware, rebrancher, puis relancer ce script." 'Red'
} else {
    Say "Aucune chaine VID+PID en double : le jeu peut distinguer les manches." 'Green'
}

# --------------------------------- 5. DeviceMappings.xml cote installation

$mappingFiles = @()
$roots = @(
    "${env:ProgramFiles(x86)}\Steam\steamapps\common\Elite Dangerous",
    "$env:ProgramFiles\Steam\steamapps\common\Elite Dangerous",
    "${env:ProgramFiles(x86)}\Frontier\EDLaunch",
    "$env:ProgramFiles\Frontier\EDLaunch",
    "${env:ProgramFiles(x86)}\Epic Games\EliteDangerous",
    "$env:ProgramFiles\Epic Games\EliteDangerous"
)
foreach ($r in $roots) {
    if ($r -and (Test-Path $r)) {
        $found = @(Get-ChildItem -Path $r -Filter 'DeviceMappings.xml' -Recurse -ErrorAction SilentlyContinue |
                   Select-Object -First 3)
        foreach ($f in $found) { $mappingFiles += $f.FullName }
    }
}
if ($mappingFiles.Count) {
    Say "" ; Say "DeviceMappings.xml : $($mappingFiles.Count) trouve(s)"
    foreach ($m in $mappingFiles) { Say "  $m" }
    Say "  (noms conviviaux de peripheriques, ECRASE a chaque mise a jour du jeu)"
}

# ------------------------------- 6. diff avec le releve precedent (sondage)

$apparus = @()
$disparus = @()
if (Test-Path $outPath) {
    try {
        $old = Get-Content $outPath -Raw | ConvertFrom-Json
        $oldSet = @{}
        foreach ($e in @($old.entrees)) { $oldSet["$($e.action)|$($e.slot)|$($e.device)|$($e.key)"] = $true }
        $newSet = @{}
        foreach ($e in $entries) { $newSet["$($e.action)|$($e.slot)|$($e.device)|$($e.key)"] = $true }
        foreach ($e in $entries) {
            if (-not $oldSet.ContainsKey("$($e.action)|$($e.slot)|$($e.device)|$($e.key)")) { $apparus += $e }
        }
        foreach ($e in @($old.entrees)) {
            if (-not $newSet.ContainsKey("$($e.action)|$($e.slot)|$($e.device)|$($e.key)")) { $disparus += $e }
        }
    } catch {
        Write-Warning "Releve precedent illisible, diff ignore."
    }
}

if ($apparus.Count) {
    Say "" ; Say "Binds APPARUS depuis le releve precedent : $($apparus.Count)" 'Green'
    foreach ($e in $apparus) {
        Say ("  {0,-14} {1,-16} {2}" -f $e.device, $e.key, $e.action)
    }
    Say "  (c'est le numero que le JEU a lu : il fait foi)" 'Green'
}
if ($disparus.Count) {
    Say "" ; Say "Binds DISPARUS depuis le releve precedent : $($disparus.Count)" 'Yellow'
    foreach ($e in $disparus) {
        Say ("  {0,-14} {1,-16} {2}" -f $e.device, $e.key, $e.action)
    }
}

# ----------------------------------------------------------- 7. ecriture JSON

if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }

$out = [ordered]@{
    generatedBy = 'tools/collect-ed-rig.ps1'
    genereLe    = (Get-Date).ToString('s')
    note        = 'Releve du rig pour la session de mapping Elite Dangerous. Le .binds ecrit par le jeu fait foi pour les noms de peripherique et les numeros de bouton ; la section windows est INDICATIVE et ne sert qu a reperer les chaines VID+PID en double.'
    sauvegarde  = $backup
    bindsDir    = $BindsDir
    presetActif = @{
        fichier = $activeName
        chemin  = $activePath
        schema  = "$schemaMajor.$schemaMinor"
        major   = $schemaMajor
        minor   = $schemaMinor
        declare = $startNames
    }
    presets        = $presets
    peripheriques  = $devList
    windows        = $windows
    vidPidEnDouble = $dupWarn
    windowsEnumOk  = $winOk
    deviceMappings = $mappingFiles
    entrees        = $entries
    diff           = @{ apparus = $apparus ; disparus = $disparus }
    counts         = @{
        presets       = $presets.Count
        peripheriques = $devList.Count
        entrees       = $entries.Count
        manettesWindows = $windows.Count
    }
}

$json = $out | ConvertTo-Json -Depth 8
Set-Content -Path $outPath -Value $json -Encoding UTF8

Say "" ; Say "Releve ecrit : $outPath" 'Cyan'
Say ""
Say "A FAIRE ENSUITE" 'Cyan'
if ($dupWarn.Count) {
    Say "  1. Regler le PID en double (voir ci-dessus) -- rien d'autre n'est possible avant."
} elseif (-not $winOk) {
    Say "  1. Confirmer a la main que les deux manches portent des PID distincts."
} else {
    Say "  1. Verifier que les 4 peripheriques apparaissent bien ci-dessus."
}
Say "  2. Sonder les numeros hauts : dans l'ecran Controles, assigner une"
Say "     commande jetable sur chaque cran du rotacteur MODE du CM3 et sur les"
Say "     boutons au-dela de 32, quitter proprement, relancer ce script : la"
Say "     section 'Binds APPARUS' donnera les vrais numeros."
Say "  3. Commiter ED\data\releve-rig.json et ouvrir la session de mapping."
Say ""
