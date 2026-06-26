import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../main.dart';
import '../../models/financial_snapshot.dart';

class MerchantBreakdownWidget extends StatelessWidget {
  final List<MerchantSpend> merchants;

  const MerchantBreakdownWidget({super.key, required this.merchants});

  @override
  Widget build(BuildContext context) {
    if (merchants.isEmpty) return const SizedBox.shrink();
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final maxAmt = merchants.map((m) => m.amount).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('TOP MERCHANTS', style: TextStyle(color: AppColors.inkLight, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
            Text('This month', style: const TextStyle(color: AppColors.inkLight, fontSize: 11)),
          ]),
          const SizedBox(height: 14),
          ...merchants.map((m) {
            final bar = m.amount / maxAmt;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(m.name, style: const TextStyle(color: AppColors.ink, fontSize: 13, fontWeight: FontWeight.w500)),
                      Row(children: [
                        Text(fmt.format(m.amount), style: const TextStyle(color: AppColors.ink, fontSize: 13, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 6),
                        Text('${m.count}x', style: const TextStyle(color: AppColors.inkLight, fontSize: 11)),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: bar,
                      minHeight: 4,
                      backgroundColor: AppColors.divider,
                      valueColor: const AlwaysStoppedAnimation(AppColors.ink),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
