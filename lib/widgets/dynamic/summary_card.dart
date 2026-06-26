import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
        color: const Color(0xFF1E2A3A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 4),
            if (subtitle.isNotEmpty)
              Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ]),
          Text(
            fmt.format(value),
            style: TextStyle(
              color: value >= 0 ? Colors.greenAccent : Colors.redAccent,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
