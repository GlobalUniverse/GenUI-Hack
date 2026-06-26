import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/financial_snapshot.dart';

class SpendingChartWidget extends StatelessWidget {
  final List<CategorySpend> categories;

  const SpendingChartWidget({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFF4FC3F7),
      const Color(0xFFFF8A65),
      const Color(0xFFA5D6A7),
      const Color(0xFFCE93D8),
      const Color(0xFFFFCC02),
    ];

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
          const Text('Spending by Category', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(color: Colors.white10, strokeWidth: 1),
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
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            categories[i].name.length > 6 ? categories[i].name.substring(0, 6) : categories[i].name,
                            style: const TextStyle(color: Colors.white54, fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: categories.asMap().entries.map((e) {
                  final delta = e.value.delta;
                  return BarChartGroupData(x: e.key, barRods: [
                    BarChartRodData(
                      toY: e.value.amount,
                      color: colors[e.key % colors.length],
                      width: 20,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: delta > 0,
                        toY: e.value.amount * 0.85,
                        color: Colors.white05,
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: categories.asMap().entries.map((e) {
              final d = e.value.delta;
              return Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: colors[e.key % colors.length], shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text('${e.value.name} ', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                Text(
                  d == 0 ? '' : '${d > 0 ? '+' : ''}${d.toStringAsFixed(0)}%',
                  style: TextStyle(color: d > 0 ? Colors.redAccent : Colors.greenAccent, fontSize: 11),
                ),
              ]);
            }).toList(),
          ),
        ],
      ),
    );
  }
}
