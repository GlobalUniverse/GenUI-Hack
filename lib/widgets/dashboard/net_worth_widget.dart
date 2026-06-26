import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../main.dart';

class NetWorthWidget extends StatelessWidget {
  final double netWorth;
  final double monthlyChange;

  const NetWorthWidget({super.key, required this.netWorth, required this.monthlyChange});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final isUp = monthlyChange >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NET WORTH',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            fmt.format(netWorth),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                color: isUp ? AppColors.green : AppColors.red,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                '${isUp ? '+' : ''}${fmt.format(monthlyChange)} this month',
                style: TextStyle(
                  color: isUp ? AppColors.green : AppColors.red,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
