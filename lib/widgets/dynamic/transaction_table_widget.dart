import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../main.dart';
import '../../models/financial_snapshot.dart';

class TransactionTableWidget extends StatelessWidget {
  final List<Transaction> transactions;

  const TransactionTableWidget({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '\$');
    final dateFmt = DateFormat('MMM d');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...transactions.take(5).toList().asMap().entries.map((entry) {
            final i = entry.key;
            final t = entry.value;
            return Column(
              children: [
                if (i > 0) const Divider(height: 1, color: AppColors.border, indent: 16, endIndent: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(_iconFor(t.category), color: AppColors.inkMid, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(t.name, style: const TextStyle(color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.w500)),
                          Text(t.category, style: const TextStyle(color: AppColors.inkLight, fontSize: 11)),
                        ]),
                      ),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(
                          t.amount >= 0 ? '+${fmt.format(t.amount)}' : fmt.format(t.amount),
                          style: TextStyle(
                            color: t.amount >= 0 ? AppColors.green : AppColors.ink,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(dateFmt.format(t.date), style: const TextStyle(color: AppColors.inkLight, fontSize: 11)),
                      ]),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  IconData _iconFor(String category) {
    switch (category.toLowerCase()) {
      case 'dining': return Icons.restaurant_outlined;
      case 'rideshare': return Icons.directions_car_outlined;
      case 'groceries': return Icons.local_grocery_store_outlined;
      case 'entertainment': return Icons.movie_outlined;
      case 'income': return Icons.account_balance_outlined;
      default: return Icons.receipt_long_outlined;
    }
  }
}
