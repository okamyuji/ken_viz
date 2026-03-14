// チャート詳細ページ [UC-06]
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kenviz/domain/entities/test_result.dart';
import 'package:kenviz/presentation/providers/repository_providers.dart';

/// 検査項目の経時変化を折れ線グラフで表示するページ
class ChartDetailPage extends ConsumerWidget {
  const ChartDetailPage({required this.itemCode, super.key});

  final String itemCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultRepo = ref.watch(testResultRepositoryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(itemCode)),
      body: FutureBuilder<List<TestResult>>(
        future: resultRepo.getByItemCode(
          profileId: 'default',
          itemCode: itemCode,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('エラー: ${snapshot.error}'));
          }

          final results = snapshot.data ?? [];
          if (results.isEmpty) {
            return const Center(child: Text('データがありません'));
          }

          // 定量データのみフィルタ
          final quantitative = results.where((r) => r.value != null).toList();
          if (quantitative.isEmpty) {
            return const Center(child: Text('数値データがありません'));
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quantitative.first.itemName,
                  style: theme.textTheme.headlineSmall,
                ),
                if (quantitative.first.unit != null)
                  Text(
                    '単位: ${quantitative.first.unit}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: 24),
                Expanded(
                  child: _TrendChart(results: quantitative, theme: theme),
                ),
                const SizedBox(height: 16),
                _ResultTable(results: quantitative, theme: theme),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.results, required this.theme});

  final List<TestResult> results;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (var i = 0; i < results.length; i++) {
      spots.add(FlSpot(i.toDouble(), results[i].value!));
    }

    final values = results.map((r) => r.value!).toList();
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final range = maxVal - minVal;
    // 全値が同一の場合、値の10%（最低1.0）をパディングとして使用
    final padding = range == 0
        ? (minVal.abs() * 0.1).clamp(1.0, double.infinity)
        : range * 0.2;
    final yMin = (minVal - padding).clamp(0, double.infinity).toDouble();
    final yMax = maxVal + padding;

    // 基準範囲バンド
    final refLow = results.first.refLow;
    final refHigh = results.first.refHigh;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (results.length - 1).toDouble(),
        minY: yMin,
        maxY: yMax,
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 48),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                // 整数位置のみラベル表示（重複防止）
                if (value != index.toDouble() ||
                    index < 0 ||
                    index >= results.length) {
                  return const SizedBox.shrink();
                }
                return Text(
                  '${index + 1}回目',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
        ),
        borderData: FlBorderData(),
        rangeAnnotations: RangeAnnotations(
          horizontalRangeAnnotations: [
            if (refLow != null && refHigh != null)
              HorizontalRangeAnnotation(
                y1: refLow,
                y2: refHigh,
                color: Colors.green.withAlpha(30),
              ),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            color: theme.colorScheme.primary,
            barWidth: 3,
            belowBarData: BarAreaData(
              color: theme.colorScheme.primary.withAlpha(30),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  spot.y.toStringAsFixed(1),
                  TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

class _ResultTable extends StatelessWidget {
  const _ResultTable({required this.results, required this.theme});

  final List<TestResult> results;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(),
        2: FlexColumnWidth(),
      },
      children: [
        TableRow(
          children: [
            Text('回', style: theme.textTheme.labelSmall),
            Text('結果', style: theme.textTheme.labelSmall),
            Text('判定', style: theme.textTheme.labelSmall),
          ],
        ),
        ...results.asMap().entries.map((e) {
          final color = switch (e.value.judgment) {
            JudgmentFlag.normal => Colors.green,
            JudgmentFlag.high => Colors.red,
            JudgmentFlag.low => Colors.orange,
            JudgmentFlag.unknown => Colors.grey,
          };
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('${e.key + 1}回目'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  e.value.value!.toStringAsFixed(1),
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  e.value.judgment.label,
                  style: TextStyle(color: color),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}
