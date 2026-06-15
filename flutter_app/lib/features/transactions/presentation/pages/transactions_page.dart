import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/core/widgets/empty_state.dart';
import 'package:flutter_app/core/widgets/error_retry.dart';
import 'package:flutter_app/features/transactions/presentation/pages/add_transaction_page.dart';
import 'package:flutter_app/features/transactions/presentation/providers/transactions_provider.dart';
import 'package:flutter_app/features/transactions/presentation/widgets/transaction_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TransactionsPage extends ConsumerWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(transactionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Movimientos')),
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
                  onTap: () => Navigator.of(context).push(
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
