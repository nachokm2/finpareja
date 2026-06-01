import 'package:flutter/material.dart';

import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/features/home/domain/entities/user_role.dart';

class RoleToggle extends StatelessWidget {
  const RoleToggle({
    super.key,
    required this.roles,
    required this.selectedRole,
    required this.onRoleSelected,
  });

  final List<UserRole> roles;
  final UserRole selectedRole;
  final ValueChanged<UserRole> onRoleSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Roles disponibles',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: roles
                .map(
                  (role) => ChoiceChip(
                    label: Text(role.label),
                    avatar: Icon(role.icon, size: 18),
                    selectedColor: role.accentColor.withAlpha(38),
                    labelStyle: TextStyle(
                      color: selectedRole == role
                          ? role.accentColor
                          : Colors.black87,
                      fontWeight: selectedRole == role
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                    selected: selectedRole == role,
                    onSelected: (_) => onRoleSelected(role),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
