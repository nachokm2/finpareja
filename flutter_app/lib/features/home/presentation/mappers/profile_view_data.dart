import 'package:flutter_app/features/auth/domain/entities/user.dart';
import 'package:flutter_app/features/home/domain/entities/user_role.dart';

/// ViewModel que transforma [User] en datos listos para mostrar en UI.
/// Toda la lógica de presentación del perfil vive aquí, no en los widgets.
class ProfileViewData {
  const ProfileViewData({
    required this.name,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    required this.bio,
    required this.isActive,
    required this.availableRoles,
    required this.primaryRole,
  });

  final String name;
  final String email;
  final String phone;
  final String avatarUrl;
  final String bio;
  final bool isActive;
  final List<UserRole> availableRoles;
  final UserRole primaryRole;

  factory ProfileViewData.fromUser(User user) {
    final displayName = user.fullName.trim().isEmpty
        ? user.email.split('@').first
        : user.fullName.trim();

    final avatar = user.avatarUrl.trim().isNotEmpty
        ? user.avatarUrl
        : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(displayName)}&background=4C4DDC&color=fff&bold=true';

    final mappedRoles =
        user.roles.map(userRoleFromString).toSet().toList(growable: false);
    final roles = mappedRoles.isEmpty ? [UserRole.director] : mappedRoles;

    return ProfileViewData(
      name: displayName,
      email: user.email,
      phone: user.phoneNumber.trim(),
      avatarUrl: avatar,
      bio: '',
      isActive: user.isActive,
      availableRoles: roles,
      primaryRole: roles.first,
    );
  }
}
