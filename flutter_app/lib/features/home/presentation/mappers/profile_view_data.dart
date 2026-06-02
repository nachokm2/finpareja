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

    final avatar = user.avatarUrl.trim().isNotEmpty
        ? user.avatarUrl
        : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(displayName)}&background=4C4DDC&color=fff&bold=true';

    return ProfileViewData(
      name: displayName,
      email: user.email,
      phone: user.phoneNumber.trim(),
      avatarUrl: avatar,
      isActive: user.isActive,
    );
  }
}
