# Corre FinPareja en modo desarrollo apuntando al backend elegido.
#
# Uso:
#   .\run_dev.ps1                                  # emulador Android → 10.0.2.2:8000
#   .\run_dev.ps1 -ApiUrl "http://192.168.1.5:8000" # dispositivo físico (tu IP local)
#   .\run_dev.ps1 -ApiUrl "https://tu-api.railway.app" # contra Railway

param(
    [string]$ApiUrl = "http://10.0.2.2:8000"
)

Write-Host "==> Ejecutando FinPareja (dev) contra $ApiUrl" -ForegroundColor Cyan

flutter run `
    --dart-define=API_BASE_URL=$ApiUrl `
    --dart-define=APP_ENV=development
