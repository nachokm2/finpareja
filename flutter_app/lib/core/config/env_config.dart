/// Configuración de entorno inyectada en tiempo de compilación.
///
/// Para correr la app en distintos entornos:
///
///   Desarrollo (emulador Android):
///     flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
///
///   Desarrollo (dispositivo físico, reemplaza <TU_IP>):
///     flutter run --dart-define=API_BASE_URL=http://192.168.1.X:8000
///
///   Producción:
///     flutter run \
///       --dart-define=API_BASE_URL=https://api.finpareja.cl \
///       --dart-define=APP_ENV=production
///
///   Build release:
///     flutter build apk \
///       --dart-define=API_BASE_URL=https://api.finpareja.cl \
///       --dart-define=APP_ENV=production
class EnvConfig {
  const EnvConfig._();

  /// URL base de la API REST. Usa 10.0.2.2 para emulador Android
  /// (apunta al localhost del host), o la IP real del dispositivo de desarrollo.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  /// Entorno activo: 'development' | 'staging' | 'production'
  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static bool get isProduction => appEnv == 'production';
  static bool get isStaging => appEnv == 'staging';
  static bool get isDevelopment => appEnv == 'development';
}
