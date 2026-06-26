import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../main.dart';
import '../../models/financial_snapshot.dart';

class SpendingChartWidget extends StatelessWidget {
  final List<CategorySpend> categories;

  const SpendingChartWidget({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    const barColors = [
      Color(0xFF0A0A0A),
      Color(0xFF6B7280),
      Color(0xFFB0B0B0),
      Color(0xFFD1D5DB),
      Color(0xFFE5E7EB),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('BY CATEGORY', style: TextStyle(color: AppColors.inkLight, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
            Text('This month', style: TextStyle(color: AppColors.inkLight, fontSize: 11)),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.border, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, _) {
                        final i = val.toInt();
                        if (i < 0 || i >= categories.length) return const SizedBox.shrink();
                        final name = categories[i].name;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            name.length > 5 ? name.substring(0, 5) : name,
                            style: const TextStyle(color: AppColors.inkLight, fontSize: 10, fontWeight: FontWeight.w500),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: categories.asMap().entries.map((e) {
                  return BarChartGroupData(x: e.key, barRods: [
                    BarChartRodData(
                      toY: e.value.amount,
                      color: barColors[e.key % barColors.length],
                      width: 22,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                    ),
                  ]);
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: categories.asMap().entries.map((e) {
              final d = e.value.delta;
              return Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: barColors[e.key % barColors.length], borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 5),
                Text(e.value.name, style: const TextStyle(color: AppColors.inkMid, fontSize: 11)),
                if (d != 0) ...[
                  const SizedBox(width: 3),
                  Text(
                    '${d > 0 ? '+' : ''}${d.toStringAsFixed(0)}%',
                    style: TextStyle(color: d > 0 ? AppColors.red : AppColors.green, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
              ]);
            }).toList(),
          ),
        ],
      ),
    );
  }
}
