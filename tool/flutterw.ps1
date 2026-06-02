$RootDir = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$FlutterBin = Join-Path $RootDir ".flutter_sdk\flutter\bin\flutter.bat"
if (!(Test-Path $FlutterBin)) {
    Write-Host "Flutter SDK lokal belum ditemukan di $FlutterBin"
    Write-Host "Jalankan: .\tool\setup_flutter_sdk_windows.ps1"
    exit 1
}
& $FlutterBin @args
