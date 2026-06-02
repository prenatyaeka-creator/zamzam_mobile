$AppDir = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $AppDir
& .\tool\flutterw.ps1 create . --platforms=android,ios,web
& .\tool\flutterw.ps1 pub get
Write-Host "Project Flutter siap. Jalankan .\tool\flutterw.ps1 run"
