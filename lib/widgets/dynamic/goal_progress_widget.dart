import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2A3A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Goals', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...displayGoals.map((g) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(g.name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                Text('${fmt.format(g.currentAmount)} / ${fmt.format(g.targetAmount)}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ]),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: g.progress.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    g.progress >= 1 ? Colors.greenAccent : const Color(0xFF4FC3F7),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(g.progress * 100).toStringAsFixed(0)}% · ${g.targetDate.difference(DateTime.now()).inDays} days left',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ]),
          )),
        ],
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
