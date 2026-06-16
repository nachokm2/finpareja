import 'package:flutter/material.dart';
import 'package:flutter_app/core/router/app_router.dart';
import 'package:flutter_app/core/security/biometric_service.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:flutter_app/features/home/presentation/mappers/profile_view_data.dart';
import 'package:flutter_app/features/home/presentation/pages/edit_profile_page.dart';
import 'package:flutter_app/features/home/presentation/providers/profile_provider.dart';
import 'package:flutter_app/features/home/presentation/widgets/contact_card.dart';
import 'package:flutter_app/features/home/presentation/widgets/profile_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  // GoRouter redirige automáticamente a /login cuando auth state
  // cambia a unauthenticated — no hace falta context.go() aquí.
  Future<void> _logout(WidgetRef ref) async {
    await ref.read(authNotifierProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar perfil',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const EditProfilePage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => _logout(ref),
          ),
        ],
      ),
      body: SafeArea(
        child: profileAsync.when(
          data: (user) => _ProfileBody(data: ProfileViewData.fromUser(user)),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ProfileError(message: error.toString()),
        ),
      ),
    );
  }
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              'No pudimos cargar tu perfil',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.data});

  final ProfileViewData data;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileCard(data: data),
          const SizedBox(height: 16),
          ContactCard(data: data),
          const SizedBox(height: 16),
          const _SettingsCard(),
        ],
      ),
    );
  }
}

/// Sección de seguridad y privacidad del perfil.
class _SettingsCard extends ConsumerStatefulWidget {
  const _SettingsCard();

  @override
  ConsumerState<_SettingsCard> createState() => _SettingsCardState();
}

class _SettingsCardState extends ConsumerState<_SettingsCard> {
  bool _bioEnabled = false;
  bool _bioAvailable = false;
  bool _bioBusy = false;

  @override
  void initState() {
    super.initState();
    _loadBiometric();
  }

  Future<void> _loadBiometric() async {
    final service = ref.read(biometricServiceProvider);
    final available = await service.isAvailable();
    final enabled = await service.isEnabled();
    if (!mounted) return;
    setState(() {
      _bioAvailable = available;
      _bioEnabled = enabled;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    final service = ref.read(biometricServiceProvider);
    setState(() => _bioBusy = true);
    if (value) {
      // Confirma que la biometría funciona antes de activarla (evita lockout).
      final ok = await service.authenticate('Confirma tu identidad para activar el bloqueo');
      if (ok) await service.setEnabled(true);
      if (!mounted) return;
      setState(() {
        _bioEnabled = ok;
        _bioBusy = false;
      });
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo activar el bloqueo biométrico')),
        );
      }
    } else {
      await service.setEnabled(false);
      if (!mounted) return;
      setState(() {
        _bioEnabled = false;
        _bioBusy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 8)],
      ),
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint, color: AppColors.primary),
            title: const Text('Bloqueo biométrico'),
            subtitle: Text(
              _bioAvailable
                  ? 'Pide huella o rostro al abrir la app'
                  : 'No disponible en este dispositivo',
            ),
            value: _bioEnabled,
            onChanged: (_bioAvailable && !_bioBusy) ? _toggleBiometric : null,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined,
                color: AppColors.primary),
            title: const Text('Política de privacidad'),
            subtitle: const Text('Cómo cuidamos tus datos (Ley 19.628)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.privacy),
          ),
        ],
      ),
    );
  }
}
