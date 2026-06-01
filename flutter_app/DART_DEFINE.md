# Variables de compilación (--dart-define)

FinPareja **no usa un archivo .env**. La configuración se inyecta en tiempo de
compilación con `--dart-define`, leída por `lib/core/config/env_config.dart`.

| Variable | Valores | Default |
|---|---|---|
| `API_BASE_URL` | URL del backend | `http://10.0.2.2:8000` |
| `APP_ENV` | `development` \| `staging` \| `production` | `development` |

## Ejemplos rápidos

```powershell
# Emulador Android (10.0.2.2 = localhost del host)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000

# Dispositivo físico (reemplaza con la IP de tu PC en la red local)
flutter run --dart-define=API_BASE_URL=http://192.168.1.5:8000

# Contra el backend en Railway
flutter run --dart-define=API_BASE_URL=https://tu-api.railway.app --dart-define=APP_ENV=production
```

## Scripts incluidos

- `run_dev.ps1` — desarrollo (acepta `-ApiUrl`)
- `build_release.ps1` — release APK/AAB (requiere `-ApiUrl`, fija `APP_ENV=production`)

## Notas

- `10.0.2.2` solo funciona en el **emulador** de Android (mapea al localhost del host).
- En iOS Simulator usa `http://localhost:8000`.
- En dispositivo físico, PC y teléfono deben estar en la **misma red** y el backend
  debe escuchar en `0.0.0.0`.
- Para release contra Railway, usa siempre `https://` (no `http://`).
