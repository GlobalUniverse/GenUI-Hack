import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../main.dart';
import '../../models/financial_snapshot.dart';

class GoalProgressWidget extends StatelessWidget {
  final Map<String, dynamic> data;
  final List<Goal> goals;

  const GoalProgressWidget({super.key, required this.data, required this.goals});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final displayGoals = goals.isNotEmpty ? goals : _fromData();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: displayGoals.toList().asMap().entries.map((entry) {
          final i = entry.key;
          final g = entry.value;
          final pct = g.progress.clamp(0.0, 1.0);
          final daysLeft = g.targetDate.difference(DateTime.now()).inDays;

          return Column(
            children: [
              if (i > 0) const Divider(height: 1, color: AppColors.border, indent: 16, endIndent: 16),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(g.name, style: const TextStyle(color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.w600)),
                    Text('${fmt.format(g.currentAmount)} / ${fmt.format(g.targetAmount)}',
                        style: const TextStyle(color: AppColors.inkMid, fontSize: 12)),
                  ]),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 5,
                      backgroundColor: AppColors.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(pct >= 1 ? AppColors.green : AppColors.ink),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${(pct * 100).toStringAsFixed(0)}% · $daysLeft days left',
                    style: const TextStyle(color: AppColors.inkLight, fontSize: 11),
                  ),
                ]),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  List<Goal> _fromData() {
    if (data.isEmpty) return [];
    return [Goal(
      name: data['name'] as String? ?? 'Goal',
      targetAmount: (data['target'] as num?)?.toDouble() ?? 1000,
      currentAmount: (data['current'] as num?)?.toDouble() ?? 0,
      targetDate: DateTime.now().add(Duration(days: (data['days_left'] as int?) ?? 60)),
    )];
  }
}
