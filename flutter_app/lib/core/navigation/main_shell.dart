import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

/// Shell principal con bottom navigation bar y botón central flotante.
///
/// Envuelve las 4 pestañas principales (Dashboard, Movimientos,
/// Presupuestos, Metas) y expone un FAB central que navega a la
/// pantalla de agregar transacción — el patrón de las apps fintech
/// modernas (Fintonic, Monarch, Copilot).
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _goToBranch(int index) {
    navigationShell.goBranch(
      index,
      // Volver a la raíz de la rama si ya estamos en ella
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      extendBody: true,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/transacciones/nueva'),
        backgroundColor: AppColors.primary,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        height: 64,
        color: Colors.white,
        elevation: 8,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_rounded,
              label: 'Inicio',
              selected: navigationShell.currentIndex == 0,
              onTap: () => _goToBranch(0),
            ),
            _NavItem(
              icon: Icons.receipt_long_rounded,
              label: 'Movimientos',
              selected: navigationShell.currentIndex == 1,
              onTap: () => _goToBranch(1),
            ),
            const SizedBox(width: 48), // espacio para el FAB
            _NavItem(
              icon: Icons.pie_chart_rounded,
              label: 'Presupuestos',
              selected: navigationShell.currentIndex == 2,
              onTap: () => _goToBranch(2),
            ),
            _NavItem(
              icon: Icons.savings_rounded,
              label: 'Metas',
              selected: navigationShell.currentIndex == 3,
              onTap: () => _goToBranch(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : Colors.grey;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
