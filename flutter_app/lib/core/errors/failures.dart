/// Jerarquía de errores de dominio.
///
/// Las capas de dominio y presentación solo conocen [Failure].
/// Las capas de datos convierten excepciones de infraestructura (Dio, SQL, etc.)
/// a subclases de [Failure] antes de exponerlas hacia arriba.
sealed class Failure {
  const Failure(this.message);
  final String message;
}

/// Sin conexión a internet o timeout de red.
final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sin conexión a internet']);
}

/// Credenciales inválidas o sesión expirada sin posibilidad de refresh.
final class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Credenciales incorrectas']);
}

/// El servidor respondió con un error (4xx distinto a 401, 5xx).
final class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Error del servidor']);
}

/// Error no clasificado. Usar como último recurso.
final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Error inesperado']);
}
