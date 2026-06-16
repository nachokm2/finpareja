import 'package:flutter_app/features/auth/domain/entities/user.dart';

/// ViewModel que transforma [User] en datos listos para mostrar en UI.
/// Toda la lógica de presentación del perfil vive aquí, no en los widgets.
class ProfileViewData {
  const ProfileViewData({
    required this.name,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    required this.isActive,
  });

  final String name;
  final String email;
  final String phone;
  final String avatarUrl;
  final bool isActive;

  factory ProfileViewData.fromUser(User user) {
    final displayName = user.fullName.trim().isEmpty
        ? user.email.split('@').first
        : user.fullName.trim();

    // avatarUrl se entrega crudo (puede ser data URI base64, URL o vacío);
    // el widget UserAvatar resuelve el fallback con la inicial del nombre.
    return ProfileViewData(
      name: displayName,
      email: user.email,
      phone: user.phoneNumber.trim(),
      avatarUrl: user.avatarUrl.trim(),
      isActive: user.isActive,
    );
  }
}
