import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/chat_provider.dart';
import '../widgets/dynamic/spending_chart_widget.dart';
import '../widgets/dynamic/transaction_table_widget.dart';
import '../widgets/dynamic/goal_progress_widget.dart';
import '../widgets/dynamic/upcoming_bills_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final snap = provider.snapshot;
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1923),
      body: SafeArea(
        child: snap == null
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF4FC3F7)))
            : RefreshIndicator(
                color: const Color(0xFF4FC3F7),
                backgroundColor: const Color(0xFF1E2A3A),
                onRefresh: () => context.read<ChatProvider>().refreshSnapshot(),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Good morning', style: TextStyle(color: Colors.white54, fontSize: 14)),
                            const SizedBox(height: 4),
                            const Text('Here\'s your money.', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 24),
                            _balanceRow(fmt, snap.checkingBalance, snap.savingsBalance),
                            const SizedBox(height: 12),
                            _cashflowBanner(fmt, snap.monthlyIncome, snap.monthlySpending),
                            const SizedBox(height: 20),
                            if (snap.upcomingBills.any((b) => b.dueDate.difference(DateTime.now()).inDays <= 2))
                              _alertBanner(snap.upcomingBills.firstWhere((b) => b.dueDate.difference(DateTime.now()).inDays <= 2), fmt),
                            const SizedBox(height: 20),
                            SpendingChartWidget(categories: snap.topCategories),
                            const SizedBox(height: 16),
                            GoalProgressWidget(data: const {}, goals: snap.goals),
                            const SizedBox(height: 16),
                            UpcomingBillsWidget(bills: snap.upcomingBills),
                            const SizedBox(height: 16),
                            TransactionTableWidget(transactions: snap.recentTransactions),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _balanceRow(NumberFormat fmt, double checking, double savings) {
    return Row(children: [
      Expanded(child: _balanceTile('Checking', checking, fmt, const Color(0xFF4FC3F7))),
      const SizedBox(width: 12),
      Expanded(child: _balanceTile('Savings', savings, fmt, Colors.greenAccent)),
    ]);
  }

  Widget _balanceTile(String label, double value, NumberFormat fmt, Color accent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2A3A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        const SizedBox(height: 6),
        Text(fmt.format(value), style: TextStyle(color: accent, fontSize: 22, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _cashflowBanner(NumberFormat fmt, double income, double spending) {
    final net = income - spending;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2A3A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _cfItem('Income', fmt.format(income), Colors.greenAccent),
        _cfDivider(),
        _cfItem('Spent', fmt.format(spending), Colors.white70),
        _cfDivider(),
        _cfItem('Net', (net >= 0 ? '+' : '') + fmt.format(net), net >= 0 ? Colors.greenAccent : Colors.redAccent),
      ]),
    );
  }

  Widget _cfItem(String label, String value, Color color) {
    return Column(children: [
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _cfDivider() => Container(height: 30, width: 1, color: Colors.white10);

  Widget _alertBanner(bill, NumberFormat fmt) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1E0F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.5)),
      ),
      child: Row(children: [
        const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(
          '${bill.name} (${fmt.format(bill.amount)}) is due ${bill.dueDate.difference(DateTime.now()).inDays <= 0 ? "today" : "tomorrow"}. Check your buffer.',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        )),
      ]),
    );
  }
}
