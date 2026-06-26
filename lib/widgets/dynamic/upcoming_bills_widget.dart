import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/financial_snapshot.dart';

class UpcomingBillsWidget extends StatelessWidget {
  final List<UpcomingBill> bills;

  const UpcomingBillsWidget({super.key, required this.bills});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '\$');

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
          const Text('Upcoming Bills', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          ...bills.map((b) {
            final daysLeft = b.dueDate.difference(DateTime.now()).inDays;
            final urgent = daysLeft <= 2;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Icon(Icons.calendar_today, size: 14, color: urgent ? Colors.orangeAccent : Colors.white38),
                    const SizedBox(width: 8),
                    Text(b.name, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  ]),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(fmt.format(b.amount), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                    Text(
                      daysLeft == 0 ? 'Today' : daysLeft == 1 ? 'Tomorrow' : 'In $daysLeft days',
                      style: TextStyle(color: urgent ? Colors.orangeAccent : Colors.white38, fontSize: 11),
                    ),
                  ]),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
