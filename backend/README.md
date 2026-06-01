# FinPareja — Backend API

FastAPI + PostgreSQL + Railway

---

## Desarrollo local

### Requisitos

- Python 3.12+
- Docker Desktop

### 1. Variables de entorno

```bash
cp .env.example .env
```

Edita `.env` y genera un `SECRET_KEY` seguro:

```bash
python -c "import secrets; print(secrets.token_hex(64))"
```

### 2. Levantar PostgreSQL con Docker

```bash
docker-compose up db -d
```

### 3. Instalar dependencias

```bash
pip install -r requirements.txt
```

### 4. Ejecutar migraciones + seed

```bash
alembic upgrade head
python -m app.seeds
```

### 5. Iniciar la API

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Documentación interactiva: http://localhost:8000/docs

---

## Despliegue en Railway — Paso a paso

### Paso 1 — Crear cuenta y proyecto

1. Ir a railway.app y crear cuenta (plan gratuito disponible).
2. Crear **New Project**.

### Paso 2 — Agregar PostgreSQL

1. En el proyecto, click **+ New → Database → Add PostgreSQL**.
2. Railway crea la instancia y expone `DATABASE_URL` automáticamente.

### Paso 3 — Agregar el servicio de la API

1. Click **+ New → GitHub Repo**.
2. Seleccionar el repositorio.
3. Si es monorepo, configurar **Root Directory** = `backend`.
4. Railway detecta el `Dockerfile` y `railway.toml` automáticamente.

### Paso 4 — Variables de entorno en Railway

En el servicio de la API, ir a **Variables** y agregar:

| Variable | Valor | Notas |
|---|---|---|
| `DATABASE_URL` | (auto-inyectada por Railway) | No configurar manualmente |
| `SECRET_KEY` | valor del comando abajo | Generar con Python |
| `APP_ENV` | `production` | |
| `DEBUG` | `false` | Desactiva logs SQL y /docs |
| `ALLOWED_ORIGINS` | `["https://tu-app.com"]` | Restringir CORS |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | `15` | |
| `REFRESH_TOKEN_EXPIRE_DAYS` | `30` | |

Generar SECRET_KEY:
```bash
python -c "import secrets; print(secrets.token_hex(64))"
```

### Paso 5 — Deploy automático

Al hacer push a `main`, Railway:
1. Construye la imagen Docker.
2. Ejecuta `start.sh` que aplica migraciones, seed e inicia el servidor.
3. Healthcheck en `/health` cada 30 segundos.

### Paso 6 — Dominio

En **Settings → Networking → Generate Domain** para obtener URL pública.

### Paso 7 — Actualizar Flutter

```bash
flutter run \
  --dart-define=API_BASE_URL=https://tu-api.railway.app \
  --dart-define=APP_ENV=production
```

Build release (o usa el script `flutter_app/build_release.ps1`):
```bash
flutter build apk \
  --dart-define=API_BASE_URL=https://tu-api.railway.app \
  --dart-define=APP_ENV=production
```

---

## Verificación post-deploy

Una vez Railway termine el deploy, valida en este orden:

```bash
# 1. Health (debe responder 200 con database: "up")
curl https://tu-api.railway.app/health
# → {"status":"ok","env":"production","database":"up"}

# 2. Registro de usuario de prueba
curl -X POST https://tu-api.railway.app/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@finpareja.cl","password":"Test1234","full_name":"Test"}'

# 3. Login (guarda el access_token de la respuesta)
curl -X POST https://tu-api.railway.app/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@finpareja.cl","password":"Test1234"}'

# 4. Categorías del seed (deben ser 23, requiere token del paso 3)
curl https://tu-api.railway.app/categorias \
  -H "Authorization: Bearer <ACCESS_TOKEN>"
```

Si los 4 pasos responden OK, el backend está operativo y la app Flutter
puede apuntar a esa URL.

---

## Checklist de producción

- [ ] `SECRET_KEY` configurado con valor aleatorio (no el default)
- [ ] `DEBUG=false` (oculta `/docs` y stacktraces)
- [ ] `APP_ENV=production`
- [ ] `ALLOWED_ORIGINS` restringido a dominios reales (no `*`)
- [ ] `DATABASE_URL` inyectada por Railway (servicio PostgreSQL vinculado)
- [ ] `/health` responde `database: "up"`
- [ ] Backups automáticos activados en el servicio PostgreSQL de Railway

> **Nota CORS:** `ALLOWED_ORIGINS` acepta tres formatos: `*`, lista separada por
> comas (`https://a.com,https://b.com`) o JSON (`["https://a.com"]`). Para apps
> móviles nativas el origen no aplica, pero restringe igual si expones la API a web.

---

## Troubleshooting

| Síntoma | Causa probable | Solución |
|---|---|---|
| Deploy queda en "building" y falla | Falta `libpq-dev`/`gcc` | Ya incluidos en el Dockerfile; revisa logs de build |
| `/health` responde 503 `database: down` | `DATABASE_URL` mal o DB caída | Verifica que el servicio PostgreSQL esté vinculado y activo |
| 500 en todos los endpoints autenticados | `SECRET_KEY` cambió entre deploys | Los tokens viejos quedan inválidos; vuelve a iniciar sesión |
| App Flutter no conecta | URL `http://` en release o IP local | Usa `https://` del dominio Railway |
| Migración falla en startup | Conflicto de revisión Alembic | Revisa `alembic current` vs `alembic/versions/` |
| CORS bloquea peticiones web | `ALLOWED_ORIGINS` no incluye el dominio | Agrégalo a la env var (CSV o JSON) |

Los logs de `start.sh` (migraciones, seed, arranque) aparecen en
**Railway → servicio → Deployments → View Logs**.

---

## CI (GitHub Actions)

El workflow `.github/workflows/ci.yml` corre en cada push/PR a `main`:
- **backend**: instala deps, compila y verifica que `app.main` importe.
- **flutter**: `flutter pub get` + `flutter analyze --no-fatal-infos`.

Railway hace el deploy automático tras el merge; el CI actúa como puerta previa.

---

## Endpoints principales

| Método | Ruta | Auth | Descripción |
|---|---|---|---|
| GET | /health | No | Health check |
| POST | /auth/login | No | Iniciar sesión |
| POST | /auth/register | No | Registrar usuario |
| POST | /auth/refresh | No | Renovar tokens |
| POST | /auth/logout | No | Cerrar sesión |
| GET | /auth/me | Sí | Perfil actual |
| GET/POST | /transacciones | Sí | Listar / crear |
| GET/POST | /categorias | Sí | Listar / crear |
| GET/POST | /presupuestos | Sí | Listar / crear |
| GET/POST | /metas | Sí | Listar / crear |
| GET/POST | /deudas | Sí | Listar / crear |
| GET/POST | /inversiones | Sí | Listar / crear |
| POST | /parejas | Sí | Crear pareja |
| GET | /parejas/me | Sí | Mi pareja |
| GET | /parejas/resumen | Sí | Patrimonio combinado por miembro |
| POST | /parejas/invite | Sí | Invitar pareja (genera token) |
| POST | /parejas/accept | Sí | Aceptar invitación |
| GET | /reportes/resumen-mensual | Sí | Balance del mes |
| GET | /reportes/por-categoria | Sí | Gastos por categoría |
| GET | /reportes/evolucion | Sí | Serie temporal |
| GET | /reportes/patrimonio | Sí | Patrimonio neto |

---

## Migraciones

```bash
alembic upgrade head       # aplicar pendientes
alembic current            # ver estado
alembic downgrade -1       # revertir última
alembic revision --autogenerate -m "descripcion"  # nueva migración
```
