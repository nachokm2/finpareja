# Etapa 4 — Diferenciación y escala

## Entregado (en producción)

| Funcionalidad | Backend | Flutter | Estado |
|---|---|---|---|
| Transacciones recurrentes | tabla `transacciones_recurrentes` (migración 007), CRUD `/recurrentes`, `POST /recurrentes/procesar` (materializa mensual/semanal, idempotente por día, catch-up de periodos atrasados) | Pantalla Recurrentes (lista + crear + activar/desactivar + eliminar), acceso desde Movimientos, materialización automática al cargar | ✅ |
| Exportación de datos | `GET /transacciones/export` → CSV UTF-8 (portabilidad, Ley 19.628) | Botón "Exportar CSV" en Movimientos (compartir/guardar vía share_plus) | ✅ |

Tests backend: 57 verdes. `flutter analyze`: 0 errores / 0 warnings.

## Diferido por decisión técnica

**Caché de reportes (Redis):** el fix N+1 de `/parejas/resumen` (Etapa 3) ya resolvió
el cuello de botella principal. Una caché en memoria por instancia introduce riesgo de
datos financieros obsoletos tras escrituras y no se comparte entre instancias. Se hará
cuando se aprovisione **Redis** en Railway, con invalidación en cada escritura.

## Bloqueado por terceros (requiere cuentas/credenciales del negocio)

Estas funciones están diseñadas pero no se pueden implementar sin accesos externos.

### 1. Sincronización bancaria (Fintoc / Belvo)
- **Necesita:** cuenta de Fintoc (recomendado para Chile) o Belvo, API keys (sandbox y
  producción), y aprobación del flujo de consentimiento del usuario.
- **Plan:** widget de conexión → webhook de transacciones → conciliación con
  categorías → deduplicación contra transacciones manuales.
- **Costo/legal:** Fintoc cobra por conexión; requiere contrato y cumplimiento CMF.

### 2. Notificaciones push (Firebase Cloud Messaging)
- **Necesita:** proyecto Firebase, `google-services.json`, credencial de servidor (FCM v1).
- **Plan:** token de dispositivo al backend → enviar push en alertas de presupuesto y
  liquidaciones de pareja. Hoy las alertas ya funcionan in-app (banner).

### 3. OCR de boletas
- **Opción sin cuentas:** Google ML Kit on-device (`google_mlkit_text_recognition`),
  pero requiere probar con cámara en dispositivo físico y aumenta el tamaño del APK.
- **Plan:** capturar foto → extraer monto/fecha/comercio → prellenar "Nueva transacción".

## Para avanzar
Indica cuál priorizar y comparte las credenciales/cuenta correspondiente:
Fintoc (sync), Firebase (push) u OCR (probamos ML Kit en tu teléfono).
