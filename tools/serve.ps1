# Petit serveur statique pour prévisualiser le site en HTTP (les pages qui
# font des fetch() de JSON/SVG ne fonctionnent pas en file://).
# Usage : powershell -ExecutionPolicy Bypass -File tools\serve.ps1 [-Port 8014]
#
# Sert aussi un point d'entrée POST `/__save` utilisé par tools/pdf-extract.html
# pour écrire sur disque les planches rendues depuis un PDF (le navigateur ne
# peut pas écrire de fichier lui-même). Volontairement restreint : uniquement
# sous la racine du dépôt, uniquement des extensions image, uniquement en
# localhost. Ça reste un serveur de développement, à ne pas exposer au réseau.
param([int]$Port = 8014)

$root = Split-Path -Parent $PSScriptRoot
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()
Write-Host "Sert $root sur http://localhost:$Port/ (Ctrl+C pour arrêter)"

$mime = @{
  ".html"="text/html; charset=utf-8"; ".css"="text/css; charset=utf-8"
  ".js"="text/javascript; charset=utf-8"; ".json"="application/json; charset=utf-8"
  ".svg"="image/svg+xml"; ".png"="image/png"; ".jpg"="image/jpeg"; ".jpeg"="image/jpeg"
  ".webp"="image/webp"; ".gif"="image/gif"; ".ico"="image/x-icon"; ".pdf"="application/pdf"
  ".woff"="font/woff"; ".woff2"="font/woff2"; ".lua"="text/plain; charset=utf-8"
  ".md"="text/plain; charset=utf-8"; ".txt"="text/plain; charset=utf-8"
}

$okExt = @('.png', '.jpg', '.jpeg', '.webp')

while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  $path = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath)

  # ---- POST /__save : écriture d'une image rendue par le navigateur ----
  # Corps attendu : JSON { "path": "F4E/img/chuck/p149.jpg", "data": "<base64>" }
  if ($ctx.Request.HttpMethod -eq 'POST' -and $path -eq '/__save') {
    try {
      $reader = New-Object IO.StreamReader($ctx.Request.InputStream, [Text.Encoding]::UTF8)
      $body = $reader.ReadToEnd(); $reader.Close()
      $req = $body | ConvertFrom-Json
      $dest = [IO.Path]::GetFullPath((Join-Path $root ($req.path -replace '/', '\')))
      if (-not $dest.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) { throw "hors racine" }
      if ($okExt -notcontains [IO.Path]::GetExtension($dest).ToLower()) { throw "extension refusee" }
      $dir = Split-Path -Parent $dest
      if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
      [IO.File]::WriteAllBytes($dest, [Convert]::FromBase64String($req.data))
      $ctx.Response.ContentType = 'text/plain; charset=utf-8'
      $msg = [Text.Encoding]::UTF8.GetBytes("ok $($req.path)")
      $ctx.Response.OutputStream.Write($msg, 0, $msg.Length)
      Write-Host "  ecrit $($req.path)"
    } catch {
      $ctx.Response.StatusCode = 400
      $msg = [Text.Encoding]::UTF8.GetBytes("erreur : $_")
      $ctx.Response.OutputStream.Write($msg, 0, $msg.Length)
    }
    $ctx.Response.Close()
    continue
  }

  if ($path.EndsWith("/")) { $path += "index.html" }
  $full = Join-Path $root ($path.TrimStart("/") -replace "/", "\")
  try {
    $fullResolved = [IO.Path]::GetFullPath($full)
    if (-not $fullResolved.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) { throw "hors racine" }
    $bytes = [IO.File]::ReadAllBytes($fullResolved)
    $ext = [IO.Path]::GetExtension($fullResolved).ToLower()
    $ctx.Response.ContentType = if ($mime.ContainsKey($ext)) { $mime[$ext] } else { "application/octet-stream" }
    $ctx.Response.ContentLength64 = $bytes.Length
    $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
  } catch {
    $ctx.Response.StatusCode = 404
    $msg = [Text.Encoding]::UTF8.GetBytes("404 - $path")
    $ctx.Response.OutputStream.Write($msg, 0, $msg.Length)
  }
  $ctx.Response.Close()
}
