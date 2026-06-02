import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:flutter_app/features/home/presentation/mappers/profile_view_data.dart';
import 'package:flutter_app/features/home/presentation/providers/profile_provider.dart';
import 'package:flutter_app/features/home/presentation/widgets/contact_card.dart';
import 'package:flutter_app/features/home/presentation/widgets/profile_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        ],
      ),
    );
  }
}
