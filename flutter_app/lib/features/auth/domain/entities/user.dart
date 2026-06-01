class User {
  final int id;
  final String email;
  final bool isActive;
  final String fullName;
  final String phoneNumber;
  final String avatarUrl;
  final List<String> roles;

  const User({
    required this.id,
    required this.email,
    required this.isActive,
    required this.fullName,
    required this.phoneNumber,
    required this.avatarUrl,
    required this.roles,
  });
}
