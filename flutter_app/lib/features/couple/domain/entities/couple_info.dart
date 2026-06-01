/// Información básica de la pareja a la que pertenece el usuario.
class CoupleInfo {
  const CoupleInfo({
    required this.id,
    required this.currency,
    required this.memberCount,
    this.nombre,
  });

  final int id;
  final String? nombre;
  final String currency;
  final int memberCount;
}
