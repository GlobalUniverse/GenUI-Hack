import 'package:flutter/material.dart';
import '../../models/advisor_response.dart';
import '../../models/financial_snapshot.dart';
import 'summary_card.dart';
import 'spending_chart_widget.dart';
import 'transaction_table_widget.dart';
import 'goal_progress_widget.dart';
import 'recommendation_card.dart';
import 'upcoming_bills_widget.dart';

class DynamicWidgetRenderer extends StatelessWidget {
  final List<WidgetSpec> specs;
  final FinancialSnapshot? snapshot;

  const DynamicWidgetRenderer({super.key, required this.specs, this.snapshot});

  @override
  Widget build(BuildContext context) {
    if (specs.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: specs.map((spec) => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: _build(spec),
      )).toList(),
    );
  }

  Widget _build(WidgetSpec spec) {
    switch (spec.type) {
      case 'summary_card':
        return SummaryCardWidget(data: spec.data);
      case 'spending_chart':
        return SpendingChartWidget(categories: snapshot?.topCategories ?? []);
      case 'transaction_table':
        return TransactionTableWidget(transactions: snapshot?.recentTransactions ?? []);
      case 'goal_progress':
        return GoalProgressWidget(data: spec.data, goals: snapshot?.goals ?? []);
      case 'recommendation_card':
        return RecommendationCard(data: spec.data);
      case 'upcoming_bills':
        return UpcomingBillsWidget(bills: snapshot?.upcomingBills ?? []);
      default:
        return const SizedBox.shrink();
    }
  }
}
