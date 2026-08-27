<#
    check-sc-mapping.ps1 — verifie SC\data\sc-mapping.json

    Controles :
      1. tout nom d'action existe dans SC\data\sc-actions.json (catalogue issu
         d'exports reels du jeu) ;
      2. aucune commande physique n'est declaree deux fois ;
      3. aucun conflit : deux actions differentes sur la meme commande DANS LA
         MEME actionmap (le partage entre actionmaps differentes est voulu) ;
      4. aucune action n'est bindee a deux endroits ;
      5. tout libelle a une categorie connue ;
      6. couverture : ce qui est encore libre sur chaque peripherique.

    Usage : powershell -ExecutionPolicy Bypass -File tools\check-sc-mapping.ps1
#>

[CmdletBinding()]
param([string]$Root)

$ErrorActionPreference = 'Stop'
if (-not $Root) { $Root = Split-Path -Parent $PSScriptRoot }
$dataDir = Join-Path $Root 'SC\data'

$map     = Get-Content (Join-Path $dataDir 'sc-mapping.json')  -Raw -Encoding UTF8 | ConvertFrom-Json
$catalog = Get-Content (Join-Path $dataDir 'sc-actions.json')  -Raw -Encoding UTF8 | ConvertFrom-Json
$labels  = Get-Content (Join-Path $dataDir 'sc-labels-fr.json') -Raw -Encoding UTF8 | ConvertFrom-Json

$known    = $catalog.actions.PSObject.Properties.Name
$cats     = $labels.categories.PSObject.Properties.Name
$errors   = @()
$warnings = @()

# --- 1. noms d'action reels + 5. categories
foreach ($a in $map.assignments) {
    if ($a.cat -and $cats -notcontains $a.cat) {
        $errors += "categorie inconnue '$($a.cat)' sur $($a.device)/$($a.control)"
    }
    foreach ($b in $a.binds) {
        if ($known -notcontains $b.action) {
            $errors += "action inconnue '$($b.action)' sur $($a.device)/$($a.control)"
            continue
        }
        $maps = $catalog.actions.($b.action).actionmaps
        if ($maps -and $maps -notcontains $b.map) {
            $errors += "'$($b.action)' n'appartient pas a l'actionmap '$($b.map)' (vu dans : $($maps -join ', '))"
        }
    }
}

# --- 2. commandes declarees deux fois
$map.assignments | Group-Object { "$($_.device)|$($_.control)" } | Where-Object { $_.Count -gt 1 } | ForEach-Object {
    $errors += "commande declaree $($_.Count) fois : $($_.Name)"
}

# --- 3. conflits dans une meme actionmap
$flat = @()
foreach ($a in $map.assignments) {
    foreach ($b in $a.binds) {
        $layer = if ($a.layer) { $a.layer } else { 'base' }
        $flat += [pscustomobject]@{
            device = $a.device; control = $a.control; layer = $layer
            map = $b.map; action = $b.action
        }
    }
}
$flat | Group-Object { "$($_.device)|$($_.control)|$($_.layer)|$($_.map)" } | Where-Object { $_.Count -gt 1 } | ForEach-Object {
    $errors += "conflit : $($_.Name) porte $($_.Count) actions ($(($_.Group.action) -join ', '))"
}

# --- 4. action bindee a deux endroits
$flat | Group-Object action | Where-Object { $_.Count -gt 1 } | ForEach-Object {
    $where = ($_.Group | ForEach-Object { "$($_.device)/$($_.control)" }) -join ', '
    $warnings += "action '$($_.Name)' bindee $($_.Count) fois : $where"
}

# --- 6. couverture
$capacity = @{ stickR = 32; stickL = 32; throttle = 55; pto2 = 41 }
$report = @()
foreach ($dev in @('stickR','stickL','throttle','pto2')) {
    $used = @($map.assignments | Where-Object { $_.device -eq $dev -and $_.control -like 'button*' -and -not $_.reserve })
    $axes = @($map.assignments | Where-Object { $_.device -eq $dev -and $_.kind -eq 'axis' -and -not $_.reserve })
    $nums = @($used | ForEach-Object { [int]($_.control -replace 'button','') })
    $free = @(1..$capacity[$dev] | Where-Object { $nums -notcontains $_ })
    $report += [pscustomobject]@{
        Peripherique = $dev
        Boutons      = "$($used.Count)/$($capacity[$dev])"
        Axes         = $axes.Count
        Actions      = @($flat | Where-Object { $_.device -eq $dev }).Count
        Libres       = if ($free.Count -le 12) { $free -join ',' } else { "$($free.Count) libres" }
    }
}

Write-Host ''
$report | Format-Table -AutoSize | Out-String | Write-Host
Write-Host ("Commandes affectees : {0}   Binds generes : {1}" -f $map.assignments.Count, $flat.Count)
Write-Host ("Actionmaps couvertes : {0}" -f (@($flat.map | Sort-Object -Unique).Count))

if ($warnings.Count) {
    Write-Host ''
    Write-Host "Avertissements ($($warnings.Count)) :" -ForegroundColor Yellow
    $warnings | ForEach-Object { Write-Host "  $_" }
}
if ($errors.Count) {
    Write-Host ''
    Write-Host "ERREURS ($($errors.Count)) :" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host "  $_" }
    exit 1
}
Write-Host ''
Write-Host 'Aucune erreur.' -ForegroundColor Green
