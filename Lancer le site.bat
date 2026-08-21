@echo off
rem Demarre le serveur local (tools\serve.ps1) et ouvre le site dans le
rem navigateur par defaut. Necessaire car les pages font des fetch() de
rem fichiers JSON (bindings, index de recherche) : ca ne marche pas si on
rem ouvre un .html directement (file://), seulement servi en http://.
rem Fermer la fenetre "Serveur local" arrete le serveur.

cd /d "%~dp0"
start "Serveur local - fermer cette fenetre pour arreter" powershell -NoProfile -ExecutionPolicy Bypass -File "tools\serve.ps1"
timeout /t 2 /nobreak >nul
start "" "http://localhost:8014/index.html"
