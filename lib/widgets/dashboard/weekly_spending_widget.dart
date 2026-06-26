import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../main.dart';

class WeeklySpendingWidget extends StatelessWidget {
  final List<double> daily; // 7 values Mon–Sun

  const WeeklySpendingWidget({super.key, required this.daily});

  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    if (daily.length < 7) return const SizedBox.shrink();
    final maxVal = daily.reduce((a, b) => a > b ? a : b);
    final avg = daily.reduce((a, b) => a + b) / 7;
    final isEscalating = daily.last > daily.first * 1.3;

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
            const Text('DAILY SPENDING', style: TextStyle(color: AppColors.inkLight, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
            Row(children: [
              Icon(
                isEscalating ? Icons.trending_up_rounded : Icons.trending_flat_rounded,
                size: 14,
                color: isEscalating ? AppColors.red : AppColors.green,
              ),
              const SizedBox(width: 4),
              Text(
                isEscalating ? 'Escalating' : 'Stable',
                style: TextStyle(
                  color: isEscalating ? AppColors.red : AppColors.green,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ]),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
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
                        if (i < 0 || i >= _days.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(_days[i], style: const TextStyle(color: AppColors.inkLight, fontSize: 10)),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: daily.asMap().entries.map((e) {
                  final isToday = e.key == 6;
                  final isHigh = e.value > avg * 1.4;
                  Color color;
                  if (isToday) {
                    color = AppColors.ink;
                  } else if (isHigh) {
                    color = AppColors.red.withValues(alpha: 0.7);
                  } else {
                    color = AppColors.inkLight;
                  }
                  return BarChartGroupData(x: e.key, barRods: [
                    BarChartRodData(
                      toY: e.value,
                      color: color,
                      width: 18,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ]);
                }).toList(),
                maxY: maxVal * 1.2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Avg \$${avg.toStringAsFixed(0)}/day · Peak \$${maxVal.toStringAsFixed(0)}',
            style: const TextStyle(color: AppColors.inkLight, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
