import 'package:flutter/material.dart';
import 'package:flutter_app/core/utils/color_parser.dart';
import 'package:flutter_app/core/utils/currency_formatter.dart';
import 'package:flutter_app/features/cards/domain/entities/card_entities.dart';

/// Representación visual de una tarjeta, estilo billetera digital (wallet).
class WalletCard extends StatelessWidget {
  const WalletCard({super.key, required this.card});

  final CreditCardEntity card;

  @override
  Widget build(BuildContext context) {
    final base = ColorParser.fromHex(card.color);
    final dark = Color.lerp(base, Colors.black, 0.38)!;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [base, dark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: dark.withAlpha(120),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                card.nombre,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const Icon(Icons.contactless, color: Colors.white70, size: 22),
            ],
          ),
          const SizedBox(height: 6),
          if (card.emisor != null)
            Text(
              card.emisor!,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          const Spacer(),
          // Chip + número enmascarado
          Row(
            children: [
              Container(
                width: 34,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8C766),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                '••••  ${card.ultimosDigitos ?? '••••'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Saldo pendiente',
                      style: TextStyle(color: Colors.white70, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatter.format(card.saldoPendiente),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              if (card.cupoDisponible != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Disponible',
                        style: TextStyle(color: Colors.white70, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(card.cupoDisponible!),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
