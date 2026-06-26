import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../main.dart';

class SavingsRateWidget extends StatelessWidget {
  final int rate; // percentage 0–100

  const SavingsRateWidget({super.key, required this.rate});

  @override
  Widget build(BuildContext context) {
    final spent = 100 - rate;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            height: 90,
            child: PieChart(
              PieChartData(
                startDegreeOffset: -90,
                sectionsSpace: 2,
                centerSpaceRadius: 28,
                sections: [
                  PieChartSectionData(
                    value: rate.toDouble(),
                    color: AppColors.green,
                    radius: 16,
                    showTitle: false,
                  ),
                  PieChartSectionData(
                    value: spent.toDouble(),
                    color: AppColors.divider,
                    radius: 14,
                    showTitle: false,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SAVINGS RATE',
                  style: TextStyle(color: AppColors.inkLight, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.8),
                ),
                const SizedBox(height: 6),
                Text(
                  '$rate%',
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'of income saved\nthis month',
                  style: const TextStyle(color: AppColors.inkMid, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 8),
                _badge(rate),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(int r) {
    String label;
    Color color;
    if (r >= 30) {
      label = 'Excellent';
      color = AppColors.green;
    } else if (r >= 15) {
      label = 'On track';
      color = AppColors.amber;
    } else {
      label = 'Below target';
      color = AppColors.red;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}
