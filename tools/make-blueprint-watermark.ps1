# Convertit le plan technique F-14 (traits blancs sur fond gris uni, sans vraie
# transparence malgre l'extension) en PNG transparent : traits blancs a faible
# opacite, fond totalement transparent. Le fond source (~RGB 137,137,137) est
# ecarte via un seuil de luminance ; seuls les traits proches du blanc pur
# ressortent, avec un fondu pour garder l'antialiasing des traits.
# Usage : powershell -ExecutionPolicy Bypass -File tools\make-blueprint-watermark.ps1
param(
  [string]$Source   = "C:\Users\Scifo\Desktop\IA\DCS\img\bbbGemini_Generated_Image_1zn3lk1zn3lk1zn3.jfif",
  [string]$Dest     = "C:\Users\Scifo\Desktop\IA\DCS\F14BU\img\tomcat-blueprint-watermark.png",
  [int]$ThresholdLo = 150,  # en dessous : fond, totalement transparent
  [int]$ThresholdHi = 250,  # au dessus : trait plein, alpha max
  [int]$MaxAlpha    = 46    # ~18% d'opacite maximale sur les traits les plus blancs
)

Add-Type -AssemblyName System.Drawing

$src = [System.Drawing.Image]::FromFile($Source)
$bmp = New-Object System.Drawing.Bitmap($src.Width, $src.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.DrawImage($src, 0, 0, $src.Width, $src.Height)
$g.Dispose()
$src.Dispose()

$rect = New-Object System.Drawing.Rectangle(0, 0, $bmp.Width, $bmp.Height)
$data = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadWrite, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)

$bytes = $data.Stride * $bmp.Height
$buf = New-Object byte[] $bytes
[System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $buf, 0, $bytes)

$range = $ThresholdHi - $ThresholdLo
for ($i = 0; $i -lt $bytes; $i += 4) {
  $b = $buf[$i]; $gCh = $buf[$i+1]; $r = $buf[$i+2]
  $lum = (0.299 * $r + 0.587 * $gCh + 0.114 * $b)
  $t = ($lum - $ThresholdLo) / $range
  if ($t -lt 0) { $t = 0 } elseif ($t -gt 1) { $t = 1 }
  $alpha = [byte]([Math]::Round($t * $MaxAlpha))
  $buf[$i]   = 255   # B
  $buf[$i+1] = 255   # G
  $buf[$i+2] = 255   # R
  $buf[$i+3] = $alpha
}

[System.Runtime.InteropServices.Marshal]::Copy($buf, 0, $data.Scan0, $bytes)
$bmp.UnlockBits($data)

$destDir = Split-Path -Parent $Dest
if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
$bmp.Save($Dest, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

Write-Output "OK -> $Dest"
