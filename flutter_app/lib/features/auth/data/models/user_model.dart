import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.isActive,
    required super.fullName,
    required super.phoneNumber,
    required super.avatarUrl,
    required super.roles,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawRoles = json['roles'];
    final fallbackRole = json['role'];
    final parsedRoles = rawRoles is List
        ? rawRoles.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : fallbackRole != null
            ? [fallbackRole.toString()]
            : <String>[];
    final roles = parsedRoles.isEmpty ? <String>['director'] : parsedRoles;
    return UserModel(
      id: json['id'] as int,
      email: json['email'] as String,
      isActive: json['is_active'] as bool? ?? true,
      fullName: json['full_name'] as String? ?? '',
      // phone_number y avatar_url son null en el backend si no se registraron;
      // la entidad User los espera como String no-nulo → fallback a ''.
      phoneNumber: json['phone_number'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String? ?? '',
      roles: roles,
    );
  }
}
