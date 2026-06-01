import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

enum UserRole { marketing, coordinador, director }

extension UserRoleX on UserRole {
  String get label => switch (this) {
        UserRole.marketing => 'Marketing',
        UserRole.coordinador => 'Coordinador',
        UserRole.director => 'Director',
      };

  String get description => switch (this) {
        UserRole.marketing => 'Acceso a captación y campañas digitales',
        UserRole.coordinador => 'Supervisa asesores y seguimiento académico',
        UserRole.director =>
          'Visor de reportes estratégicos de los programas académicos',
      };

  IconData get icon => switch (this) {
        UserRole.marketing => Symbols.campaign,
        UserRole.coordinador => Symbols.group,
        UserRole.director => Symbols.school,
      };

  Color get accentColor => const Color(0xFF4C4DDC);
}

UserRole userRoleFromString(String value) => switch (value.toLowerCase()) {
      'marketing' => UserRole.marketing,
      'coordinador' || 'coordinator' => UserRole.coordinador,
      _ => UserRole.director,
    };
