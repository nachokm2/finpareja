import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/features/home/presentation/mappers/profile_view_data.dart';

class ContactCard extends StatelessWidget {
  const ContactCard({super.key, required this.data});

  final ProfileViewData data;

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
            'Información de contacto',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
          ),
          const SizedBox(height: 16),
          _ContactRow(
            icon: Symbols.mail,
            label: 'Correo',
            value: data.email,
          ),
          const SizedBox(height: 8),
          _ContactRow(
            icon: Symbols.phone,
            label: 'Teléfono',
            value: data.phone.isEmpty ? 'No registrado' : data.phone,
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.accent,
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textGrey,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
