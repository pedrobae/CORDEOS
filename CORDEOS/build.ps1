
# build.ps1 - Auto-increment version and build APK
# Usage:
#   ./build.ps1 [-IncrementType <build|patch|minor|major>]

# Accept parameter for increment type
param(
    [ValidateSet('build','patch','minor','major')]
    [string]$IncrementType = 'build'
)

# Read current version from pubspec.yaml
$pubspec = Get-Content "pubspec.yaml" -Raw
# Parse version
$versionMatch = $pubspec -match 'version: (\d+)\.(\d+)\.(\d+)\+(\d+)'

if ($versionMatch) {
    $major = [int]$matches[1]
    $minor = [int]$matches[2]
    $patch = [int]$matches[3]
    $buildNumber = [int]$matches[4]

    switch ($IncrementType) {
        'major' {
            $major++
            $minor = 0
            $patch = 0
            $buildNumber++
        }
        'minor' {
            $minor++
            $patch = 0
            $buildNumber++
        }
        'patch' {
            $patch++
            $buildNumber++
        }
        default {
            $buildNumber++
        }
    }

    $newVersion = "$major.$minor.$patch+$buildNumber"
    Write-Host "Incrementing version to: $newVersion" -ForegroundColor Green

    # Update pubspec.yaml
    $newPubspec = $pubspec -replace "version: \d+\.\d+\.\d+\+\d+", "version: $newVersion"
    Set-Content "pubspec.yaml" $newPubspec

    Write-Host "Updated pubspec.yaml" -ForegroundColor Green
    Write-Host "Building APK..." -ForegroundColor Cyan

    # Build APK
    flutter build apk --debug

    # Rename APK to CORDEOS_vX.Y.Z+A.apk (using newVersion)
    $apkSource = "build/app/outputs/flutter-apk/app-debug.apk"
    $apkDest = "build/app/outputs/flutter-apk/CORDEOS_v$($newVersion).apk"
    if (Test-Path $apkSource) {
        Move-Item -Force $apkSource $apkDest
        Write-Host "Renamed APK to: $apkDest" -ForegroundColor Green
    } else {
        Write-Host "APK not found at $apkSource" -ForegroundColor Red
        exit 1
    }

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Build completed successfully!" -ForegroundColor Green
    } else {
        Write-Host "Build failed!" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "Could not parse version from pubspec.yaml" -ForegroundColor Red
    exit 1
}
