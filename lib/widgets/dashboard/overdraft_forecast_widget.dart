import 'package:flutter/material.dart';
import '../../main.dart';

class OverdraftForecastWidget extends StatelessWidget {
  final int days;
  final double balance;
  final double dailyBurn;

  const OverdraftForecastWidget({
    super.key,
    required this.days,
    required this.balance,
    required this.dailyBurn,
  });

  @override
  Widget build(BuildContext context) {
    final isImminent = days <= 2;
    final color = isImminent ? AppColors.red : AppColors.amber;
    final bgColor = isImminent ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB);
    final fill = (balance / (dailyBurn * 14)).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BALANCE RUNWAY',
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isImminent ? 'CRITICAL' : 'WARNING',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$days',
                style: TextStyle(
                  color: color,
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -2,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'days until\noverdraft',
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fill,
              minHeight: 7,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Burning ~\$${dailyBurn.toStringAsFixed(0)}/day at current rate',
            style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 11),
          ),
        ],
      ),
    );
  }
}
