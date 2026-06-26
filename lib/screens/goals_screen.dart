import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/financial_snapshot.dart';
import '../services/chat_provider.dart';
import '../widgets/skeleton.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final snap = context.watch<ChatProvider>().snapshot;
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1923),
      body: SafeArea(
        child: snap == null
            ? SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                    SkeletonBox(width: 120, height: 28, radius: 6),
                    SizedBox(height: 8),
                    SkeletonBox(width: 180, height: 14),
                    SizedBox(height: 24),
                    CardSkeleton(height: 160),
                    SizedBox(height: 16),
                    CardSkeleton(height: 160),
                    SizedBox(height: 16),
                    CardSkeleton(height: 120),
                  ]),
                ),
              )
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Goals', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          const Text('Track your savings targets', style: TextStyle(color: Colors.white38, fontSize: 14)),
                          const SizedBox(height: 24),
                          ...snap.goals.map((g) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _GoalCard(goal: g, fmt: fmt),
                          )),
                          const SizedBox(height: 16),
                          const Text('Suggested Goals', style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          ..._suggested().map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
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
        color: const Color(0xFF1E2A3A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(goal.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (pct >= 1 ? Colors.greenAccent : const Color(0xFF4FC3F7)).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${(pct * 100).toStringAsFixed(0)}%',
              style: TextStyle(color: pct >= 1 ? Colors.greenAccent : const Color(0xFF4FC3F7), fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ]),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 10,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(pct >= 1 ? Colors.greenAccent : const Color(0xFF4FC3F7)),
          ),
        ),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _stat('Saved', fmt.format(goal.currentAmount)),
          _stat('Target', fmt.format(goal.targetAmount)),
          _stat('Days Left', '$daysLeft'),
        ]),
        if (daysLeft > 0 && pct < 1) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(8)),
            child: Text(
              'Save ${fmt.format(weeklyNeeded)}/week to hit this goal on time.',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _stat(String label, String value) {
    return Column(children: [
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
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
        color: const Color(0xFF1E2A3A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(children: [
        const Icon(Icons.add_circle_outline, color: Color(0xFF4FC3F7), size: 22),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(description, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ])),
      ]),
    );
  }
}
