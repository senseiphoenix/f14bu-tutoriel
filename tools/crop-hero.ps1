# Recadre une image (webp/jpg/png, y compris WebP via WIC) en JPEG, pour les
# cartes hero de la page d'accueil (fond de carte height:260px, ratio ~1.3-1.4:1).
# Usage : powershell -ExecutionPolicy Bypass -File tools\crop-hero.ps1 -Source in.webp -Dest out.jpg -X 0 -Y 550 -W 1080 -H 800
param(
  [Parameter(Mandatory=$true)][string]$Source,
  [Parameter(Mandatory=$true)][string]$Dest,
  [Parameter(Mandatory=$true)][int]$X,
  [Parameter(Mandatory=$true)][int]$Y,
  [Parameter(Mandatory=$true)][int]$W,
  [Parameter(Mandatory=$true)][int]$H,
  [int]$Quality = 88
)

Add-Type -AssemblyName PresentationCore

$uri = New-Object System.Uri($Source)
$decoder = [System.Windows.Media.Imaging.BitmapDecoder]::Create($uri, [System.Windows.Media.Imaging.BitmapCreateOptions]::None, [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad)
$frame = $decoder.Frames[0]

$rect = New-Object System.Windows.Int32Rect($X, $Y, $W, $H)
$cropped = New-Object System.Windows.Media.Imaging.CroppedBitmap($frame, $rect)

$encoder = New-Object System.Windows.Media.Imaging.JpegBitmapEncoder
$encoder.QualityLevel = $Quality
$encoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($cropped))

$destDir = Split-Path -Parent $Dest
if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
$stream = [System.IO.File]::Open($Dest, [System.IO.FileMode]::Create)
$encoder.Save($stream)
$stream.Close()

Write-Output "OK -> $Dest ($W x $H from $X,$Y)"
