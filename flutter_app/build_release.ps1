# Build de release de FinPareja para Android.
#
# Uso:
#   .\build_release.ps1 -ApiUrl "https://tu-api.railway.app"
#   .\build_release.ps1 -ApiUrl "https://tu-api.railway.app" -AppBundle   # .aab para Play Store
#
# Requiere que la URL de la API apunte al backend desplegado en Railway.

param(
    [Parameter(Mandatory = $true)]
    [string]$ApiUrl,

    [switch]$AppBundle  # genera .aab en vez de .apk
)

$ErrorActionPreference = "Stop"

Write-Host "==> FinPareja — build release" -ForegroundColor Cyan
Write-Host "    API: $ApiUrl"

$defines = @(
    "--dart-define=API_BASE_URL=$ApiUrl",
    "--dart-define=APP_ENV=production"
)

if ($AppBundle) {
    Write-Host "==> Generando App Bundle (.aab)..." -ForegroundColor Cyan
    flutter build appbundle --release @defines
    Write-Host "==> Listo: build\app\outputs\bundle\release\app-release.aab" -ForegroundColor Green
} else {
    Write-Host "==> Generando APK..." -ForegroundColor Cyan
    flutter build apk --release @defines
    Write-Host "==> Listo: build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Green
}
