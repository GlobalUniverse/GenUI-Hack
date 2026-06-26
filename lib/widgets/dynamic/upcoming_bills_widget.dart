import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../main.dart';
import '../../models/financial_snapshot.dart';

class UpcomingBillsWidget extends StatelessWidget {
  final List<UpcomingBill> bills;

  const UpcomingBillsWidget({super.key, required this.bills});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '\$');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: bills.toList().asMap().entries.map((entry) {
          final i = entry.key;
          final b = entry.value;
          final daysLeft = b.dueDate.difference(DateTime.now()).inDays;
          final urgent = daysLeft <= 2;
          final dueLabel = daysLeft == 0 ? 'Today' : daysLeft == 1 ? 'Tomorrow' : 'In $daysLeft days';

          return Column(
            children: [
              if (i > 0) const Divider(height: 1, color: AppColors.border, indent: 16, endIndent: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: urgent ? const Color(0xFFFFF7ED) : AppColors.divider,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.calendar_today_outlined, size: 15, color: urgent ? AppColors.amber : AppColors.inkMid),
                      ),
                      const SizedBox(width: 12),
                      Text(b.name, style: const TextStyle(color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.w500)),
                    ]),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(fmt.format(b.amount), style: const TextStyle(color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.w600)),
                      Text(dueLabel, style: TextStyle(color: urgent ? AppColors.amber : AppColors.inkLight, fontSize: 11, fontWeight: urgent ? FontWeight.w500 : FontWeight.w400)),
                    ]),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
