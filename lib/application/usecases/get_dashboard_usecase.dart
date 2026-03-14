// ダッシュボード取得ユースケース [UC-04]
import 'package:kenviz/core/constants/test_item_defaults.dart';
import 'package:kenviz/domain/entities/test_item_master.dart';
import 'package:kenviz/domain/entities/test_result.dart';
import 'package:kenviz/domain/repositories/repositories.dart';

/// ダッシュボード用のカテゴリ別サマリーを取得する
class GetDashboardUseCase {
  GetDashboardUseCase({
    required this.checkupRepository,
    required this.testResultRepository,
  });

  final CheckupRepository checkupRepository;
  final TestResultRepository testResultRepository;

  /// デフォルトプロフィールの最新健診サマリーを取得
  Future<List<DashboardCategorySummary>> execute() async {
    final latest = await checkupRepository.getLatestByProfileId('default');
    if (latest == null) return [];

    final results = await testResultRepository.getByCheckupId(latest.id);

    // 前回健診との比較
    final allCheckups = await checkupRepository.getByProfileId('default');
    var previousResults = <String, TestResult>{};
    if (allCheckups.length >= 2) {
      final prev = await testResultRepository.getByCheckupId(allCheckups[1].id);
      previousResults = {for (final r in prev) r.itemCode: r};
    }

    // カテゴリごとに集約
    final summaries = <DashboardCategorySummary>[];
    for (final cat in defaultCategories) {
      final codes = defaultTestItems
          .where((TestItemMaster item) => item.categoryId == cat.id)
          .map((TestItemMaster item) => item.id)
          .toSet();

      final catResults = results
          .where((r) => codes.contains(r.itemCode))
          .toList();
      if (catResults.isEmpty) continue;

      final items = catResults.map((r) {
        TrendDirection? trend;
        final prev = previousResults[r.itemCode];
        if (prev != null && r.value != null && prev.value != null) {
          if (r.value! > prev.value!) {
            trend = TrendDirection.up;
          } else if (r.value! < prev.value!) {
            trend = TrendDirection.down;
          }
        }
        return DashboardItemSummary(
          itemCode: r.itemCode,
          itemName: r.itemName,
          value: r.value,
          valueText: r.valueText,
          unit: r.unit,
          judgment: r.judgment,
          trend: trend,
        );
      }).toList();

      summaries.add(
        DashboardCategorySummary(
          categoryId: cat.id,
          categoryName: cat.name,
          items: items,
        ),
      );
    }

    return summaries;
  }
}

/// カテゴリ別サマリー
class DashboardCategorySummary {
  const DashboardCategorySummary({
    required this.categoryId,
    required this.categoryName,
    required this.items,
  });

  final String categoryId;
  final String categoryName;
  final List<DashboardItemSummary> items;
}

/// 個別項目サマリー
class DashboardItemSummary {
  const DashboardItemSummary({
    required this.itemCode,
    required this.itemName,
    this.value,
    this.valueText,
    this.unit,
    required this.judgment,
    this.trend,
  });

  final String itemCode;
  final String itemName;
  final double? value;
  final String? valueText;
  final String? unit;
  final JudgmentFlag judgment;
  final TrendDirection? trend;
}

/// トレンド方向
enum TrendDirection { up, down }
