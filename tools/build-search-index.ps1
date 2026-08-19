# Régénère data/search-index.json à partir des pages HTML du dépôt.
#
# Port PowerShell de build-search-index.py, pour les machines où Python n'est
# pas installé (c'est le cas de la machine de dev : `python` n'y est que le
# raccourci Microsoft Store). Les deux scripts produisent le même fichier ;
# corriger l'un implique de corriger l'autre.
#
#     powershell -ExecutionPolicy Bypass -File tools/build-search-index.ps1
#
# Trois familles d'entrées :
#   "page"     : une par fichier HTML, titre = balise <title>.
#   "leçon"    : tableaux JS `id:"xx", title:"..."` / `id:"xx", ... nm:"..."`
#                des pages section-*.html (chaque avion a son format, d'où les
#                deux expressions régulières).
#   "fonction" : commandes non vides de chaque data/*-bindings.json au format
#                device/n/commands.

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$aircraftByFolder = @{
  'F14BU' = 'F-14B(U)'
  'F4U1D' = 'F4U-1D Corsair'
  'F4E'   = 'F-4E Phantom II'
  'SC'    = 'Star Citizen'
}

function Get-CleanText([string]$raw) {
  [System.Net.WebUtility]::HtmlDecode(($raw -replace '\s+', ' ')).Trim()
}

function Get-NormKey([string]$s) {
  $d = $s.ToLowerInvariant().Normalize([Text.NormalizationForm]::FormD)
  $sb = New-Object Text.StringBuilder
  foreach ($ch in $d.ToCharArray()) {
    if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($ch) -ne [Globalization.UnicodeCategory]::NonSpacingMark) {
      [void]$sb.Append($ch)
    }
  }
  $sb.ToString().Trim()
}

function Get-RelPath([string]$full) {
  $full.Substring($root.Length + 1) -replace '\\', '/'
}

function Get-AircraftFor([string]$rel) {
  $top = ($rel -split '/', 2)[0]
  if ($aircraftByFolder.ContainsKey($top)) { $aircraftByFolder[$top] } else { $null }
}

$entries = New-Object Collections.ArrayList

# ---------- pages ----------
Get-ChildItem -Path $root -Filter *.html -Recurse -File | Sort-Object FullName | ForEach-Object {
  $rel = Get-RelPath $_.FullName
  if ($rel -like 'SC/profile exemple/*') { return }
  $text = [IO.File]::ReadAllText($_.FullName, [Text.Encoding]::UTF8)
  $m = [regex]::Match($text, '<title>(.*?)</title>', 'IgnoreCase, Singleline')
  if (-not $m.Success) { return }
  $title = Get-CleanText $m.Groups[1].Value
  if (-not $title) { return }
  [void]$entries.Add([pscustomobject]@{
    title = $title; path = $rel; aircraft = (Get-AircraftFor $rel); type = 'page'
  })
}

# ---------- leçons ----------
$lessonPatterns = @(
  '\bid:\s*"([a-zA-Z0-9_-]+)"\s*,\s*title:\s*"([^"]*)"',
  '\bid:\s*"([a-zA-Z0-9_-]+)"\s*,[^}]{0,200}?\bnm:\s*"([^"]*)"'
)
Get-ChildItem -Path $root -Directory | Sort-Object Name | ForEach-Object {
  Get-ChildItem -Path $_.FullName -Filter 'section-*.html' -File -ErrorAction SilentlyContinue | Sort-Object Name | ForEach-Object {
    $rel = Get-RelPath $_.FullName
    $aircraft = Get-AircraftFor $rel
    if (-not $aircraft) { return }
    $text = [IO.File]::ReadAllText($_.FullName, [Text.Encoding]::UTF8)
    $seenIds = @{}
    foreach ($pattern in $lessonPatterns) {
      foreach ($m in [regex]::Matches($text, $pattern)) {
        $lessonId = $m.Groups[1].Value
        $title = Get-CleanText $m.Groups[2].Value
        if ($seenIds.ContainsKey($lessonId) -or -not $title) { continue }
        $seenIds[$lessonId] = $true
        [void]$entries.Add([pscustomobject]@{
          title = $title; path = "$rel#$lessonId"; aircraft = $aircraft; type = 'leçon'
        })
      }
    }
  }
}

# ---------- fonctions HOTAS ----------
$seenFn = @{}
Get-ChildItem -Path $root -Directory | Sort-Object Name | ForEach-Object {
  $folder = $_.Name
  $aircraft = if ($aircraftByFolder.ContainsKey($folder)) { $aircraftByFolder[$folder] } else { $null }
  if (-not $aircraft) { return }
  $dataDir = Join-Path $_.FullName 'data'
  if (-not (Test-Path $dataDir)) { return }
  Get-ChildItem -Path $dataDir -Filter '*-bindings.json' -File | Sort-Object Name | ForEach-Object {
    try { $data = [IO.File]::ReadAllText($_.FullName) | ConvertFrom-Json }
    catch { Write-Host "! $($_.Name) : JSON invalide, ignoré"; return }
    if (-not $data.bindings -or $data.bindings -isnot [Array]) { return }
    foreach ($b in $data.bindings) {
      foreach ($cmd in @($b.commands)) {
        if (-not $cmd) { continue }
        $cmd = Get-CleanText $cmd
        if (-not $cmd) { continue }
        $key = "$folder|$($b.device)|$($b.n)|$cmd"
        if ($seenFn.ContainsKey($key)) { continue }
        $seenFn[$key] = $true
        [void]$entries.Add([pscustomobject]@{
          title = $cmd
          path = "$folder/mapping-hotas.html?dev=$($b.device)&n=$($b.n)"
          aircraft = $aircraft
          type = 'fonction'
        })
      }
    }
  }
}

# ---------- dédoublonnage et tri ----------
$dedup = [ordered]@{}
foreach ($e in $entries) {
  $k = "$($e.type)|$(Get-NormKey $e.title)|$($e.aircraft)|$($e.path)"
  $dedup[$k] = $e
}
$final = @($dedup.Values)
# tri ordinal, comme le `sorted()` de Python : (type, avion, titre normalisé)
$cmp = [Comparison[object]]{
  param($a, $b)
  $r = [string]::CompareOrdinal($a.type, $b.type); if ($r -ne 0) { return $r }
  $aa = if ($a.aircraft) { $a.aircraft } else { '' }
  $bb = if ($b.aircraft) { $b.aircraft } else { '' }
  $r = [string]::CompareOrdinal($aa, $bb); if ($r -ne 0) { return $r }
  return [string]::CompareOrdinal((Get-NormKey $a.title), (Get-NormKey $b.title))
}
[Array]::Sort($final, $cmp)

# ---------- écriture ----------
# JSON écrit à la main : ConvertTo-Json de PowerShell 5.1 échappe les
# non-ASCII et n'indente pas comme json.dumps(indent=1), ce qui rendrait le
# fichier illisible en diff face à la sortie du script Python.
function ConvertTo-JsonString([string]$s) {
  $sb = New-Object Text.StringBuilder
  foreach ($ch in $s.ToCharArray()) {
    switch ($ch) {
      '"'  { [void]$sb.Append('\"'); continue }
      '\'  { [void]$sb.Append('\\'); continue }
      "`n" { [void]$sb.Append('\n'); continue }
      "`r" { [void]$sb.Append('\r'); continue }
      "`t" { [void]$sb.Append('\t'); continue }
      default {
        if ([int]$ch -lt 32) { [void]$sb.Append(('\u{0:x4}' -f [int]$ch)) }
        else { [void]$sb.Append($ch) }
      }
    }
  }
  $sb.ToString()
}

$out = New-Object Text.StringBuilder
[void]$out.Append("[`n")
for ($i = 0; $i -lt $final.Count; $i++) {
  $e = $final[$i]
  $air = if ($e.aircraft) { '"' + (ConvertTo-JsonString $e.aircraft) + '"' } else { 'null' }
  [void]$out.Append(" {`n")
  [void]$out.Append('  "title": "' + (ConvertTo-JsonString $e.title) + "`",`n")
  [void]$out.Append('  "path": "' + (ConvertTo-JsonString $e.path) + "`",`n")
  [void]$out.Append('  "aircraft": ' + $air + ",`n")
  [void]$out.Append('  "type": "' + (ConvertTo-JsonString $e.type) + "`"`n")
  [void]$out.Append(' }')
  if ($i -lt $final.Count - 1) { [void]$out.Append(',') }
  [void]$out.Append("`n")
}
[void]$out.Append("]")

$outPath = Join-Path $root 'data/search-index.json'
# sans BOM : c'est un JSON lu par fetch() côté navigateur
[IO.File]::WriteAllText($outPath, $out.ToString(), (New-Object Text.UTF8Encoding $false))

$byType = $final | Group-Object type | ForEach-Object { "$($_.Name)=$($_.Count)" }
Write-Host "$($final.Count) entrées écrites dans data/search-index.json : $($byType -join ', ')"
