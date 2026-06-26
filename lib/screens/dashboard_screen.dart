import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../models/financial_snapshot.dart';
import '../services/chat_provider.dart';
import '../widgets/dynamic/spending_chart_widget.dart';
import '../widgets/dynamic/transaction_table_widget.dart';
import '../widgets/dynamic/goal_progress_widget.dart';
import '../widgets/dynamic/upcoming_bills_widget.dart';
import '../widgets/dashboard/critical_banner_widget.dart';
import '../widgets/dashboard/overdraft_forecast_widget.dart';
import '../widgets/dashboard/net_worth_widget.dart';
import '../widgets/dashboard/savings_rate_widget.dart';
import '../widgets/dashboard/merchant_breakdown_widget.dart';
import '../widgets/dashboard/weekly_spending_widget.dart';
import 'login_screen.dart';

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
                            _header(context, snap),
                            const SizedBox(height: 24),
                            ..._buildLayout(snap, fmt),
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

  List<Widget> _buildLayout(FinancialSnapshot snap, NumberFormat fmt) {
    final widgets = <Widget>[];
    final dailyBurn = snap.monthlySpending / 30;

    for (final key in snap.layout) {
      switch (key) {

        case 'critical_banner':
          if (snap.criticalMessage.isNotEmpty) {
            widgets.add(CriticalBannerWidget(message: snap.criticalMessage));
            widgets.add(const SizedBox(height: 10));
          }

        case 'overdraft_forecast':
          if (snap.overdraftDays > 0) {
            widgets.add(OverdraftForecastWidget(
              days: snap.overdraftDays,
              balance: snap.checkingBalance,
              dailyBurn: dailyBurn,
            ));
            widgets.add(const SizedBox(height: 10));
          }

        case 'balances':
          widgets.add(_balanceRow(fmt, snap.checkingBalance, snap.savingsBalance));
          widgets.add(const SizedBox(height: 10));

        case 'cashflow':
          widgets.add(_cashflowBanner(fmt, snap.monthlyIncome, snap.monthlySpending));
          widgets.add(const SizedBox(height: 10));

        case 'net_worth':
          if (snap.netWorth > 0) {
            widgets.add(const SizedBox(height: 14));
            widgets.add(NetWorthWidget(netWorth: snap.netWorth, monthlyChange: snap.netWorthChange));
          }

        case 'savings_rate':
          if (snap.savingsRate > 0) {
            widgets.add(const SizedBox(height: 10));
            widgets.add(SavingsRateWidget(rate: snap.savingsRate));
          }

        case 'merchant_breakdown':
          if (snap.topMerchants.isNotEmpty) {
            widgets.add(const SizedBox(height: 24));
            widgets.add(_sectionLabel('Top Merchants'));
            widgets.add(const SizedBox(height: 10));
            widgets.add(MerchantBreakdownWidget(merchants: snap.topMerchants));
          }

        case 'weekly_spending':
          if (snap.weeklySpending.length >= 7) {
            widgets.add(const SizedBox(height: 24));
            widgets.add(_sectionLabel('This Week'));
            widgets.add(const SizedBox(height: 10));
            widgets.add(WeeklySpendingWidget(daily: snap.weeklySpending));
          }

        case 'spending_chart':
          if (snap.topCategories.isNotEmpty) {
            widgets.add(const SizedBox(height: 24));
            widgets.add(_sectionLabel('Spending'));
            widgets.add(const SizedBox(height: 10));
            widgets.add(SpendingChartWidget(categories: snap.topCategories));
          }

        case 'goals':
          if (snap.goals.isNotEmpty) {
            widgets.add(const SizedBox(height: 24));
            widgets.add(_sectionLabel('Goals'));
            widgets.add(const SizedBox(height: 10));
            widgets.add(GoalProgressWidget(data: const {}, goals: snap.goals));
          }

        case 'upcoming_bills':
          if (snap.upcomingBills.isNotEmpty) {
            widgets.add(const SizedBox(height: 24));
            widgets.add(_sectionLabel('Upcoming Bills'));
            widgets.add(const SizedBox(height: 10));
            widgets.add(UpcomingBillsWidget(bills: snap.upcomingBills));
          }

        case 'transactions':
          if (snap.recentTransactions.isNotEmpty) {
            widgets.add(const SizedBox(height: 24));
            widgets.add(_sectionLabel('Recent Transactions'));
            widgets.add(const SizedBox(height: 10));
            widgets.add(TransactionTableWidget(transactions: snap.recentTransactions));
          }
      }
    }
    return widgets;
  }

  Widget _header(BuildContext context, FinancialSnapshot snap) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(greeting, style: const TextStyle(color: AppColors.inkMid, fontSize: 13)),
          const SizedBox(height: 2),
          Text(
            snap.profileName.isNotEmpty ? snap.profileName : "Here's your money.",
            style: const TextStyle(color: AppColors.ink, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5),
          ),
          if (snap.profileTagline.isNotEmpty)
            Text(snap.profileTagline, style: const TextStyle(color: AppColors.inkMid, fontSize: 12)),
        ]),
        GestureDetector(
          onTap: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(20)),
            child: const Text('Sign out', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String label) => Text(
        label.toUpperCase(),
        style: const TextStyle(color: AppColors.inkLight, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8),
      );

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
}
