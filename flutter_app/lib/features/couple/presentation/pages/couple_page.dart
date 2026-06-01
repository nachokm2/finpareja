import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/core/utils/currency_formatter.dart';
import 'package:flutter_app/core/widgets/animated_count.dart';
import 'package:flutter_app/core/widgets/error_retry.dart';
import 'package:flutter_app/features/couple/domain/entities/couple_summary.dart';
import 'package:flutter_app/features/couple/presentation/providers/couple_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CouplePage extends ConsumerWidget {
  const CouplePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coupleAsync = ref.watch(coupleProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Vista Pareja')),
      body: coupleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(
          message: '$e',
          onRetry: () => ref.read(coupleProvider.notifier).refresh(),
        ),
        data: (state) {
          if (!state.hasCouple) {
            return _CoupleOnboarding(ref: ref);
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(coupleProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (state.summary != null)
                  _CombinedWorthCard(summary: state.summary!),
                const SizedBox(height: 16),
                if (state.summary != null)
                  _MembersBreakdown(summary: state.summary!),
                const SizedBox(height: 16),
                _InviteCard(ref: ref),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Patrimonio combinado ────────────────────────────────────────────────────

class _CombinedWorthCard extends StatelessWidget {
  const _CombinedWorthCard({required this.summary});
  final CoupleSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
              color: AppColors.cardShadow, blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.favorite_rounded, color: Colors.white, size: 18),
              SizedBox(width: 6),
              Text('Patrimonio combinado',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          // Contador animado: da el efecto "wow" que pedía el wireframe UX-04.
          AnimatedCount(
            value: summary.patrimonioCombinado,
            style: const TextStyle(
                color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

// ─── Desglose por miembro ────────────────────────────────────────────────────

class _MembersBreakdown extends StatelessWidget {
  const _MembersBreakdown({required this.summary});
  final CoupleSummary summary;

  static const _memberColors = [AppColors.primary, Color(0xFFEC4899)];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Aporte de cada uno',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 16),
          for (var i = 0; i < summary.miembros.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _MemberRow(
                member: summary.miembros[i],
                color: _memberColors[i % _memberColors.length],
              ),
            ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.color});
  final CoupleMemberSummary member;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pct = (member.porcentaje / 100).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: color.withAlpha(40),
                  child: Text(
                    member.nombre.isNotEmpty
                        ? member.nombre[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                Text(member.nombre,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            Text(
              CurrencyFormatter.format(member.patrimonio),
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: color.withAlpha(25),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 4),
        Text('${member.porcentaje.toStringAsFixed(0)}% del total',
            style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }
}

// ─── Invitar pareja ──────────────────────────────────────────────────────────

class _InviteCard extends StatelessWidget {
  const _InviteCard({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Invitar a tu pareja',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 4),
          const Text(
            'Comparte el código de invitación para unir sus finanzas.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _showInvite(context),
            icon: const Icon(Icons.person_add_alt, size: 18),
            label: const Text('Generar invitación'),
            style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(40)),
          ),
        ],
      ),
    );
  }

  void _showInvite(BuildContext context) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Invitar pareja',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.emailAddress,
              decoration:
                  const InputDecoration(labelText: 'Correo de tu pareja'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final email = ctrl.text.trim();
                  if (email.isEmpty) return;
                  final token =
                      await ref.read(coupleProvider.notifier).invite(email);
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  if (token != null) {
                    await showDialog<void>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Código de invitación'),
                        content: SelectableText(
                          token,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Listo'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                child: const Text('Generar código'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Onboarding (sin pareja) ─────────────────────────────────────────────────

class _CoupleOnboarding extends StatelessWidget {
  const _CoupleOnboarding({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💑', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text(
              'Finanzas en pareja',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
            ),
            const SizedBox(height: 8),
            const Text(
              'Crea un espacio compartido para ver el patrimonio combinado, '
              'objetivos comunes y gastos de ambos.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _createCouple(context),
                icon: const Icon(Icons.add),
                label: const Text('Crear pareja'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _joinCouple(context),
                icon: const Icon(Icons.login),
                label: const Text('Tengo un código de invitación'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createCouple(BuildContext context) async {
    final ok = await ref.read(coupleProvider.notifier).createCouple(null);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo crear la pareja')),
      );
    }
  }

  void _joinCouple(BuildContext context) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Unirse a una pareja',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              decoration:
                  const InputDecoration(labelText: 'Código de invitación'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final token = ctrl.text.trim();
                  if (token.isEmpty) return;
                  final ok =
                      await ref.read(coupleProvider.notifier).accept(token);
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Código inválido o expirado')),
                    );
                  }
                },
                child: const Text('Unirme'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
