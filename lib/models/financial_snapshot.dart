class MerchantSpend {
  final String name;
  final double amount;
  final int count;

  MerchantSpend({required this.name, required this.amount, required this.count});

  factory MerchantSpend.fromJson(Map<String, dynamic> json) => MerchantSpend(
        name: json['name'] as String,
        amount: (json['amount'] as num).toDouble(),
        count: (json['count'] as num).toInt(),
      );
}

class FinancialSnapshot {
  final double checkingBalance;
  final double savingsBalance;
  final double monthlyIncome;
  final double monthlySpending;
  final List<CategorySpend> topCategories;
  final List<Transaction> recentTransactions;
  final List<Goal> goals;
  final List<UpcomingBill> upcomingBills;
  // GenUI layout fields
  final List<String> layout;
  final List<String> tabs;
  final String profileName;
  final String profileTagline;
  // Per-user intelligence fields
  final int overdraftDays;          // 0 = no risk
  final String criticalMessage;     // empty = none
  final double netWorth;            // 0 = not tracked
  final double netWorthChange;      // monthly delta
  final int savingsRate;            // % of income saved, 0 = N/A
  final List<MerchantSpend> topMerchants;
  final List<double> weeklySpending; // last 7 days (Mon–Sun)

  FinancialSnapshot({
    required this.checkingBalance,
    required this.savingsBalance,
    required this.monthlyIncome,
    required this.monthlySpending,
    required this.topCategories,
    required this.recentTransactions,
    required this.goals,
    required this.upcomingBills,
    this.layout = const ['balances', 'cashflow', 'spending_chart', 'goals', 'upcoming_bills', 'transactions'],
    this.tabs = const ['dashboard', 'advisor', 'goals'],
    this.profileName = '',
    this.profileTagline = '',
    this.overdraftDays = 0,
    this.criticalMessage = '',
    this.netWorth = 0,
    this.netWorthChange = 0,
    this.savingsRate = 0,
    this.topMerchants = const [],
    this.weeklySpending = const [],
  });

  factory FinancialSnapshot.fromJson(Map<String, dynamic> json) {
    return FinancialSnapshot(
      checkingBalance: (json['checking_balance'] as num).toDouble(),
      savingsBalance: (json['savings_balance'] as num).toDouble(),
      monthlyIncome: (json['monthly_income'] as num).toDouble(),
      monthlySpending: (json['monthly_spending'] as num).toDouble(),
      topCategories: (json['top_categories'] as List<dynamic>? ?? [])
          .map((c) => CategorySpend.fromJson(c as Map<String, dynamic>))
          .toList(),
      recentTransactions: (json['recent_transactions'] as List<dynamic>? ?? [])
          .map((t) => Transaction.fromJson(t as Map<String, dynamic>))
          .toList(),
      goals: (json['goals'] as List<dynamic>? ?? [])
          .map((g) => Goal.fromJson(g as Map<String, dynamic>))
          .toList(),
      upcomingBills: (json['upcoming_bills'] as List<dynamic>? ?? [])
          .map((b) => UpcomingBill.fromJson(b as Map<String, dynamic>))
          .toList(),
      layout: (json['layout'] as List<dynamic>? ?? ['balances', 'cashflow', 'spending_chart'])
          .map((e) => e as String).toList(),
      tabs: (json['tabs'] as List<dynamic>? ?? ['dashboard', 'advisor'])
          .map((e) => e as String).toList(),
      profileName: json['profile_name'] as String? ?? '',
      profileTagline: json['profile_tagline'] as String? ?? '',
      overdraftDays: (json['overdraft_days'] as num? ?? 0).toInt(),
      criticalMessage: json['critical_message'] as String? ?? '',
      netWorth: (json['net_worth'] as num? ?? 0).toDouble(),
      netWorthChange: (json['net_worth_change'] as num? ?? 0).toDouble(),
      savingsRate: (json['savings_rate'] as num? ?? 0).toInt(),
      topMerchants: (json['top_merchants'] as List<dynamic>? ?? [])
          .map((m) => MerchantSpend.fromJson(m as Map<String, dynamic>))
          .toList(),
      weeklySpending: (json['weekly_spending'] as List<dynamic>? ?? [])
          .map((v) => (v as num).toDouble())
          .toList(),
    );
  }

  factory FinancialSnapshot.mock() {
    return FinancialSnapshot(
      checkingBalance: 1284.50,
      savingsBalance: 3420.00,
      monthlyIncome: 4200.00,
      monthlySpending: 3180.00,
      layout: const ['balances', 'cashflow', 'spending_chart', 'goals', 'upcoming_bills', 'transactions'],
      tabs: const ['dashboard', 'advisor', 'goals'],
      profileName: 'Demo User',
      profileTagline: 'Sample financial data',
      topCategories: [
        CategorySpend(name: 'Dining', amount: 620, delta: 18),
        CategorySpend(name: 'Rideshare', amount: 310, delta: 42),
        CategorySpend(name: 'Groceries', amount: 480, delta: -5),
        CategorySpend(name: 'Entertainment', amount: 210, delta: 12),
        CategorySpend(name: 'Utilities', amount: 190, delta: 0),
      ],
      recentTransactions: [
        Transaction(name: 'Uber', amount: -24.50, category: 'Rideshare', date: DateTime.now().subtract(const Duration(hours: 3))),
        Transaction(name: 'Whole Foods', amount: -87.20, category: 'Groceries', date: DateTime.now().subtract(const Duration(days: 1))),
        Transaction(name: 'Chipotle', amount: -13.80, category: 'Dining', date: DateTime.now().subtract(const Duration(days: 1))),
        Transaction(name: 'Netflix', amount: -15.99, category: 'Entertainment', date: DateTime.now().subtract(const Duration(days: 2))),
        Transaction(name: 'Direct Deposit', amount: 2100.00, category: 'Income', date: DateTime.now().subtract(const Duration(days: 3))),
      ],
      goals: [
        Goal(name: 'Emergency Fund', targetAmount: 5000, currentAmount: 3420, targetDate: DateTime.now().add(const Duration(days: 90))),
        Goal(name: 'Travel Fund', targetAmount: 2000, currentAmount: 640, targetDate: DateTime.now().add(const Duration(days: 180))),
      ],
      upcomingBills: [
        UpcomingBill(name: 'Rent', amount: 1500, dueDate: DateTime.now().add(const Duration(days: 2))),
        UpcomingBill(name: 'Electric', amount: 95, dueDate: DateTime.now().add(const Duration(days: 8))),
      ],
    );
  }
}

class CategorySpend {
  final String name;
  final double amount;
  final double delta;

  CategorySpend({required this.name, required this.amount, required this.delta});

  factory CategorySpend.fromJson(Map<String, dynamic> json) => CategorySpend(
        name: json['name'] as String,
        amount: (json['amount'] as num).toDouble(),
        delta: (json['delta'] as num? ?? 0).toDouble(),
      );
}

class Transaction {
  final String name;
  final double amount;
  final String category;
  final DateTime date;

  Transaction({required this.name, required this.amount, required this.category, required this.date});

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        name: json['name'] as String,
        amount: (json['amount'] as num).toDouble(),
        category: json['category'] as String,
        date: DateTime.parse(json['date'] as String),
      );
}

class Goal {
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;

  Goal({required this.name, required this.targetAmount, required this.currentAmount, required this.targetDate});

  double get progress => currentAmount / targetAmount;

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
        name: json['name'] as String,
        targetAmount: (json['target_amount'] as num).toDouble(),
        currentAmount: (json['current_amount'] as num).toDouble(),
        targetDate: DateTime.parse(json['target_date'] as String),
      );
}

class UpcomingBill {
  final String name;
  final double amount;
  final DateTime dueDate;

  UpcomingBill({required this.name, required this.amount, required this.dueDate});

  factory UpcomingBill.fromJson(Map<String, dynamic> json) => UpcomingBill(
        name: json['name'] as String,
        amount: (json['amount'] as num).toDouble(),
        dueDate: DateTime.parse(json['due_date'] as String),
      );
}
