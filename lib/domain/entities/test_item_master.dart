/// 検査項目マスタ [DE-05]
class TestItemMaster {
  const TestItemMaster({
    required this.id,
    required this.categoryId,
    required this.standardName,
    this.aliases = const [],
    this.unit,
    this.defaultRefLow,
    this.defaultRefHigh,
    this.displayOrder = 0,
  });

  final String id;
  final String categoryId;
  final String standardName;
  final List<String> aliases;
  final String? unit;
  final double? defaultRefLow;
  final double? defaultRefHigh;
  final int displayOrder;

  /// 全ての名称候補（standardName + aliases）
  List<String> get allNames => [standardName, ...aliases];
}

/// 検査カテゴリマスタ [DE-04]
class TestCategory {
  const TestCategory({
    required this.id,
    required this.name,
    required this.displayOrder,
    this.iconName,
  });

  final String id;
  final String name;
  final int displayOrder;
  final String? iconName;
}
