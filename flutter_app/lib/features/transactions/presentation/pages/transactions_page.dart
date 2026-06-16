import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_app/core/network/dio_provider.dart';
import 'package:flutter_app/core/router/app_router.dart';
import 'package:flutter_app/core/security/biometric_service.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/core/widgets/empty_state.dart';
import 'package:flutter_app/core/widgets/error_retry.dart';
import 'package:flutter_app/features/transactions/data/datasources/transaction_remote_datasource.dart';
import 'package:flutter_app/features/transactions/presentation/pages/add_transaction_page.dart';
import 'package:flutter_app/features/transactions/presentation/providers/transactions_provider.dart';
import 'package:flutter_app/features/transactions/presentation/widgets/transaction_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class TransactionsPage extends ConsumerWidget {
  const TransactionsPage({super.key});

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final dio = await ref.read(dioProvider.future);
      final csv = await TransactionRemoteDataSource(dio).exportCsv();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/finpareja_transacciones.csv');
      await file.writeAsString(csv);
      // Evita que el bloqueo biométrico se active al abrir el menú de compartir.
      await ref.read(biometricServiceProvider).duringExternalActivity(
            () => Share.shareXFiles(
              [XFile(file.path, mimeType: 'text/csv')],
              subject: 'Mis transacciones - FinPareja',
            ),
          );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo exportar')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(transactionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Movimientos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.repeat),
            tooltip: 'Recurrentes',
            onPressed: () => context.push(AppRoutes.recurring),
          ),
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Exportar CSV',
            onPressed: () => _export(context, ref),
          ),
        ],
      ),
      body: txAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(
          message: '$e',
          onRetry: () => ref.read(transactionsProvider.notifier).refresh(),
        ),
        data: (transactions) {
          if (transactions.isEmpty) {
            return const EmptyState(
              emoji: '💸',
              message: 'Sin movimientos este mes.\nRegistra el primero con el botón +',
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(transactionsProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final tx = transactions[index];
                return TransactionCard(
                  transaction: tx,
                  onTap: () => Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AddTransactionPage(transaction: tx),
                    ),
                  ),
                  onDelete: () async {
                    final deleted = await ref
                        .read(transactionsProvider.notifier)
                        .delete(tx.id);
                    if (!deleted && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No se pudo eliminar'),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
