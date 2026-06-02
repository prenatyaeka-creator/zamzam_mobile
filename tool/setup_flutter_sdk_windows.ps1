param(
    [string]$Version = "3.41.6"
)
$RootDir = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$SdkDir = Join-Path $RootDir ".flutter_sdk"
$ArchiveName = "flutter_windows_$Version-stable.zip"
$ArchivePath = Join-Path $SdkDir $ArchiveName
$Url = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/$ArchiveName"
New-Item -ItemType Directory -Force -Path $SdkDir | Out-Null
Write-Host "Downloading Flutter SDK $Version from official storage..."
Invoke-WebRequest -Uri $Url -OutFile $ArchivePath
Expand-Archive -Path $ArchivePath -DestinationPath $SdkDir -Force
Remove-Item $ArchivePath -Force
& (Join-Path $SdkDir "flutter\bin\flutter.bat") --version
