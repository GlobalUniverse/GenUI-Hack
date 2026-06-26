import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../main.dart';

class SummaryCardWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const SummaryCardWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final label = data['label'] as String? ?? '';
    final value = (data['value'] as num?)?.toDouble() ?? 0;
    final subtitle = data['subtitle'] as String? ?? '';
    final fmt = NumberFormat.currency(symbol: '\$');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label.toUpperCase(), style: const TextStyle(color: AppColors.inkLight, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.6)),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: AppColors.inkMid, fontSize: 12)),
            ],
          ]),
          Text(
            fmt.format(value),
            style: TextStyle(
              color: value >= 0 ? AppColors.green : AppColors.red,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
