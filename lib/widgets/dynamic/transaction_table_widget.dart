import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/financial_snapshot.dart';

class TransactionTableWidget extends StatelessWidget {
  final List<Transaction> transactions;

  const TransactionTableWidget({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '\$');
    final dateFmt = DateFormat('MMM d');

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2A3A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text('Recent Transactions', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          ...transactions.take(5).map((t) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white08,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_iconFor(t.category), color: Colors.white54, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t.name, style: const TextStyle(color: Colors.white, fontSize: 14)),
                    Text(t.category, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(
                    t.amount >= 0 ? '+${fmt.format(t.amount)}' : fmt.format(t.amount),
                    style: TextStyle(
                      color: t.amount >= 0 ? Colors.greenAccent : Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(dateFmt.format(t.date), style: const TextStyle(color: Colors.white38, fontSize: 11)),
                ]),
              ],
            ),
          )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  IconData _iconFor(String category) {
    switch (category.toLowerCase()) {
      case 'dining': return Icons.restaurant;
      case 'rideshare': return Icons.directions_car;
      case 'groceries': return Icons.local_grocery_store;
      case 'entertainment': return Icons.movie;
      case 'income': return Icons.account_balance;
      default: return Icons.receipt_long;
    }
  }
}
