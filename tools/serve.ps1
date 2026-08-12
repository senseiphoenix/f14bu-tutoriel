# Petit serveur statique pour prévisualiser le site en HTTP (les pages qui
# font des fetch() de JSON/SVG ne fonctionnent pas en file://).
# Usage : powershell -ExecutionPolicy Bypass -File tools\serve.ps1 [-Port 8014]
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

while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  $path = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath)
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
