$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
Push-Location $project
try {
    $env:GRADLE_USER_HOME = Join-Path $env:USERPROFILE '.gradle'
    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed' }
    flutter build apk --release
    if ($LASTEXITCODE -ne 0) { throw 'APK build failed; no new package copied.' }
    $destination = Join-Path $project 'dist'
    New-Item -ItemType Directory -Force $destination | Out-Null
    Copy-Item -LiteralPath (Join-Path $project 'build/app/outputs/flutter-apk/app-release.apk') -Destination (Join-Path $destination 'StylO-1.1.0-beta.apk') -Force
    Get-FileHash -LiteralPath (Join-Path $destination 'StylO-1.1.0-beta.apk') -Algorithm SHA256
    Write-Host "APK: $destination\StylO-1.1.0-beta.apk"
} finally { Pop-Location }
