import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../main.dart';
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
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: snap == null
            ? const Center(child: CircularProgressIndicator(color: AppColors.ink, strokeWidth: 2))
            : RefreshIndicator(
                color: AppColors.ink,
                backgroundColor: AppColors.card,
                onRefresh: () => context.read<ChatProvider>().refreshSnapshot(),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _header(),
                            const SizedBox(height: 24),
                            _balanceRow(fmt, snap.checkingBalance, snap.savingsBalance),
                            const SizedBox(height: 10),
                            _cashflowBanner(fmt, snap.monthlyIncome, snap.monthlySpending),
                            if (snap.upcomingBills.any((b) => b.dueDate.difference(DateTime.now()).inDays <= 2)) ...[
                              const SizedBox(height: 10),
                              _alertBanner(snap.upcomingBills.firstWhere((b) => b.dueDate.difference(DateTime.now()).inDays <= 2), fmt),
                            ],
                            const SizedBox(height: 24),
                            _sectionLabel('Spending'),
                            const SizedBox(height: 10),
                            SpendingChartWidget(categories: snap.topCategories),
                            const SizedBox(height: 24),
                            _sectionLabel('Goals'),
                            const SizedBox(height: 10),
                            GoalProgressWidget(data: const {}, goals: snap.goals),
                            const SizedBox(height: 24),
                            _sectionLabel('Upcoming Bills'),
                            const SizedBox(height: 10),
                            UpcomingBillsWidget(bills: snap.upcomingBills),
                            const SizedBox(height: 24),
                            _sectionLabel('Recent Transactions'),
                            const SizedBox(height: 10),
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

  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Good morning', style: TextStyle(color: AppColors.inkMid, fontSize: 13, fontWeight: FontWeight.w400)),
          const SizedBox(height: 2),
          const Text("Here's your money.", style: TextStyle(color: AppColors.ink, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
        ]),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text('Live', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        ),
      ],
    );
  }

  Widget _sectionLabel(String label) {
    return Text(label.toUpperCase(), style: const TextStyle(color: AppColors.inkLight, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8));
  }

  Widget _balanceRow(NumberFormat fmt, double checking, double savings) {
    return Row(children: [
      Expanded(child: _balanceTile('Checking', checking, fmt)),
      const SizedBox(width: 8),
      Expanded(child: _balanceTile('Savings', savings, fmt)),
    ]);
  }

  Widget _balanceTile(String label, double value, NumberFormat fmt) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(), style: const TextStyle(color: AppColors.inkLight, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.6)),
        const SizedBox(height: 8),
        Text(fmt.format(value), style: const TextStyle(color: AppColors.ink, fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
      ]),
    );
  }

  Widget _cashflowBanner(NumberFormat fmt, double income, double spending) {
    final net = income - spending;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _cfItem('Income', fmt.format(income), AppColors.green),
        _cfDivider(),
        _cfItem('Spent', fmt.format(spending), AppColors.inkMid),
        _cfDivider(),
        _cfItem('Net', (net >= 0 ? '+' : '') + fmt.format(net), net >= 0 ? AppColors.green : AppColors.red),
      ]),
    );
  }

  Widget _cfItem(String label, String value, Color color) {
    return Column(children: [
      Text(label.toUpperCase(), style: const TextStyle(color: AppColors.inkLight, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      const SizedBox(height: 5),
      Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w700)),
    ]);
  }

  Widget _cfDivider() => Container(height: 28, width: 1, color: AppColors.border);

  Widget _alertBanner(bill, NumberFormat fmt) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.amber.withOpacity(0.4)),
      ),
      child: Row(children: [
        const Icon(Icons.warning_amber_rounded, color: AppColors.amber, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(
          '${bill.name} (${fmt.format(bill.amount)}) due ${bill.dueDate.difference(DateTime.now()).inDays <= 0 ? "today" : "tomorrow"}.',
          style: const TextStyle(color: Color(0xFF92400E), fontSize: 13, fontWeight: FontWeight.w500),
        )),
      ]),
    );
  }
}
