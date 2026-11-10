import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/kx_widgets.dart';

/// Cartão de um sensor: o que está acontecendo (em palavras), o número e,
/// em letra pequena, o detalhe técnico.
class SensorCard extends StatelessWidget {
  const SensorCard({
    super.key,
    required this.icon,
    required this.title,
    required this.state,
    required this.color,
    required this.value,
    required this.detail,
    this.alert = false,
    this.chart,
  });

  final IconData icon;
  final String title;
  final String state;
  final Color color;
  final String value;
  final String detail;
  final bool alert;
  final Widget? chart;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title: $state, $value',
      child: KxCard(
        glow: alert ? KxColors.talpaLava : null,
        padding: const EdgeInsets.all(KxSpace.md + 2),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 18, color: alert ? KxColors.talpaLava : KxColors.cyberCyan),
            const SizedBox(width: 6),
            Expanded(child: Text(title.toUpperCase(), style: KxText.label, maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: KxSpace.sm),
          Text(state, style: KxText.h3.copyWith(color: color, fontSize: 17), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(value, style: KxText.metric(KxColors.textDisplay).copyWith(fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis),
          if (chart != null) ...[const SizedBox(height: KxSpace.sm), SizedBox(height: 34, child: chart)],
          const SizedBox(height: 4),
          Text(detail, style: KxText.log.copyWith(fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}

/// Mini gráfico de linha (temperatura), com a faixa segura sombreada.
class Sparkline extends StatelessWidget {
  const Sparkline({super.key, required this.values, this.min, this.max, this.color = KxColors.cyberCyan});
  final List<double> values;
  final double? min;
  final double? max;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) return const SizedBox.shrink();
    final lo = [...values, if (min != null) min!].reduce((a, b) => a < b ? a : b) - 0.5;
    final hi = [...values, if (max != null) max!].reduce((a, b) => a > b ? a : b) + 0.5;
    return LineChart(
      LineChartData(
        minY: lo,
        maxY: hi,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        rangeAnnotations: RangeAnnotations(horizontalRangeAnnotations: [
          if (min != null && max != null)
            HorizontalRangeAnnotation(y1: min!, y2: max!, color: KxColors.electricLime.withValues(alpha: 0.06)),
        ]),
        lineBarsData: [
          LineChartBarData(
            spots: [for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i])],
            isCurved: true,
            preventCurveOverShooting: true,
            color: color,
            barWidth: 1.6,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.08)),
          ),
        ],
      ),
      duration: Duration.zero,
    );
  }
}
