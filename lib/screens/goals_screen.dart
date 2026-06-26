import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../models/financial_snapshot.dart';
import '../services/chat_provider.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final snap = context.watch<ChatProvider>().snapshot;
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: snap == null
            ? const Center(child: CircularProgressIndicator(color: AppColors.ink, strokeWidth: 2))
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Goals', style: TextStyle(color: AppColors.ink, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                          const SizedBox(height: 2),
                          const Text('Track your savings targets', style: TextStyle(color: AppColors.inkMid, fontSize: 13)),
                          const SizedBox(height: 24),
                          ...snap.goals.map((g) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _GoalCard(goal: g, fmt: fmt),
                          )),
                          const SizedBox(height: 24),
                          const Text('SUGGESTED', style: TextStyle(color: AppColors.inkLight, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                          const SizedBox(height: 10),
                          ..._suggested().map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _SuggestedGoalTile(name: s['name']!, description: s['description']!),
                          )),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  List<Map<String, String>> _suggested() => [
    {'name': 'Rent Buffer', 'description': 'Keep 2 months rent in checking at all times'},
    {'name': '3-Month Emergency Fund', 'description': 'Build \$12,000 over 12 months'},
    {'name': 'Vacation Fund', 'description': 'Save \$2,000 for summer travel'},
  ];
}

class _GoalCard extends StatelessWidget {
  final Goal goal;
  final NumberFormat fmt;

  const _GoalCard({required this.goal, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final pct = goal.progress.clamp(0.0, 1.0);
    final daysLeft = goal.targetDate.difference(DateTime.now()).inDays;
    final remaining = goal.targetAmount - goal.currentAmount;
    final weeklyNeeded = daysLeft > 0 ? remaining / (daysLeft / 7) : 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(goal.name, style: const TextStyle(color: AppColors.ink, fontSize: 16, fontWeight: FontWeight.w600)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: pct >= 1 ? AppColors.green : AppColors.ink,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${(pct * 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(pct >= 1 ? AppColors.green : AppColors.ink),
          ),
        ),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _stat('Saved', fmt.format(goal.currentAmount)),
          _stat('Target', fmt.format(goal.targetAmount)),
          _stat('Days Left', '$daysLeft'),
        ]),
        if (daysLeft > 0 && pct < 1) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(8)),
            child: Text(
              'Save ${fmt.format(weeklyNeeded)}/week to hit this goal on time.',
              style: const TextStyle(color: AppColors.inkMid, fontSize: 12),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _stat(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: const TextStyle(color: AppColors.inkLight, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.w600)),
    ]);
  }
}

class _SuggestedGoalTile extends StatelessWidget {
  final String name;
  final String description;

  const _SuggestedGoalTile({required this.name, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.add, color: AppColors.inkMid, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(description, style: const TextStyle(color: AppColors.inkMid, fontSize: 12)),
        ])),
        const Icon(Icons.arrow_forward_ios, color: AppColors.inkLight, size: 12),
      ]),
    );
  }
}
