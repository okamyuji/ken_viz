// ダッシュボード関連 Provider [UC-04]
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kenviz/domain/entities/test_result.dart';
import 'package:kenviz/presentation/providers/repository_providers.dart';

/// ダッシュボードサマリー
final dashboardSummaryProvider = FutureProvider<List<CategorySummary>>((
  ref,
) async {
  final checkupRepo = ref.watch(checkupRepositoryProvider);
  final resultRepo = ref.watch(testResultRepositoryProvider);
  final masterRepo = ref.watch(testItemMasterRepositoryProvider);

  // デフォルトプロフィールの最新健診を取得
  final latest = await checkupRepo.getLatestByProfileId('default');
  if (latest == null) return [];

  final results = await resultRepo.getByCheckupId(latest.id);
  final categories = await masterRepo.getAllCategories();

  // 前回の健診も取得（変化矢印用）
  final allCheckups = await checkupRepo.getByProfileId('default');
  var previousResults = <String, TestResult>{};
  if (allCheckups.length >= 2) {
    final prev = await resultRepo.getByCheckupId(allCheckups[1].id);
    previousResults = {for (final r in prev) r.itemCode: r};
  }

  final summaries = <CategorySummary>[];
  for (final cat in categories) {
    final catResults = results
        .where((r) => _belongsToCategory(r, cat.id))
        .toList();
    if (catResults.isEmpty) continue;

    final items = catResults.map((r) {
      ChangeDirection? change;
      final prev = previousResults[r.itemCode];
      if (prev != null && r.value != null && prev.value != null) {
        if (r.value! > prev.value!) {
          change = ChangeDirection.up;
        } else if (r.value! < prev.value!) {
          change = ChangeDirection.down;
        }
      }

      return DashboardItem(
        itemCode: r.itemCode,
        itemName: r.itemName,
        value: r.value,
        valueText: r.valueText,
        unit: r.unit,
        judgment: r.judgment,
        changeArrow: change,
      );
    }).toList();

    summaries.add(
      CategorySummary(categoryId: cat.id, categoryName: cat.name, items: items),
    );
  }

  return summaries;
});

/// カテゴリにitemCodeが属するか判定
bool _belongsToCategory(TestResult result, String categoryId) {
  // マスタデータのカテゴリマッピング
  const mapping = {
    'body': ['HEIGHT', 'WEIGHT', 'BMI', 'WAIST', 'BODY_FAT'],
    'bp': ['BP_SYS', 'BP_DIA', 'HEART_RATE'],
    'blood': [
      'RBC', 'WBC', 'HB', 'HCT', 'PLT',
      'MCV', 'MCH', 'MCHC', 'RETIC', 'FE',
    ],
    'lipid': ['LDL_C', 'HDL_C', 'TG', 'TC'],
    'sugar': ['FPG', 'HBA1C'],
    'liver': ['AST', 'ALT', 'GGT', 'ALP', 'TBIL', 'TP', 'ALB', 'LDH'],
    'kidney': ['CRE', 'EGFR', 'BUN', 'UA'],
    'urine': [
      'U_GLU', 'U_PRO', 'U_OB', 'U_SG', 'U_PH',
      'U_URO', 'U_RBC', 'U_WBC',
    ],
    'eye': ['VISION_R', 'VISION_L', 'IOP_R', 'IOP_L'],
    'hearing': <String>[],
    'other': ['CRP', 'RF', 'PSA'],
  };
  return mapping[categoryId]?.contains(result.itemCode) ?? false;
}

/// カテゴリサマリー
class CategorySummary {
  const CategorySummary({
    required this.categoryId,
    required this.categoryName,
    required this.items,
  });

  final String categoryId;
  final String categoryName;
  final List<DashboardItem> items;
}

/// ダッシュボード表示用アイテム
class DashboardItem {
  const DashboardItem({
    required this.itemCode,
    required this.itemName,
    this.value,
    this.valueText,
    this.unit,
    required this.judgment,
    this.changeArrow,
  });

  final String itemCode;
  final String itemName;
  final double? value;
  final String? valueText;
  final String? unit;
  final JudgmentFlag judgment;
  final ChangeDirection? changeArrow;
}

/// 変化方向
enum ChangeDirection { up, down }
