/// 個別検査結果 [DE-03]
class TestResult {
  const TestResult({
    required this.id,
    required this.checkupId,
    required this.itemCode,
    required this.itemName,
    this.value,
    this.valueText,
    this.unit,
    this.refLow,
    this.refHigh,
    this.flag,
    this.confidence = 1.0,
    this.isManuallyEdited = false,
  });

  final String id;
  final String checkupId;
  final String itemCode;
  final String itemName;
  final double? value;
  final String? valueText;
  final String? unit;
  final double? refLow;
  final double? refHigh;
  final String? flag;
  final double confidence;
  final bool isManuallyEdited;

  /// 定量検査か（数値があるか）
  bool get isQuantitative => value != null;

  /// 定性検査か（テキスト結果か）
  bool get isQualitative => valueText != null && value == null;

  /// 確認が必要か
  bool get needsConfirmation => confidence < 0.7;

  /// 基準値判定
  JudgmentFlag get judgment {
    if (value == null) return JudgmentFlag.unknown;
    if (refHigh != null && value! > refHigh!) return JudgmentFlag.high;
    if (refLow != null && value! < refLow!) return JudgmentFlag.low;
    return JudgmentFlag.normal;
  }

  TestResult copyWith({
    String? itemCode,
    String? itemName,
    double? value,
    String? valueText,
    String? unit,
    double? refLow,
    double? refHigh,
    String? flag,
    double? confidence,
    bool? isManuallyEdited,
  }) {
    return TestResult(
      id: id,
      checkupId: checkupId,
      itemCode: itemCode ?? this.itemCode,
      itemName: itemName ?? this.itemName,
      value: value ?? this.value,
      valueText: valueText ?? this.valueText,
      unit: unit ?? this.unit,
      refLow: refLow ?? this.refLow,
      refHigh: refHigh ?? this.refHigh,
      flag: flag ?? this.flag,
      confidence: confidence ?? this.confidence,
      isManuallyEdited: isManuallyEdited ?? this.isManuallyEdited,
    );
  }
}

/// 基準値判定フラグ
enum JudgmentFlag {
  normal('正常'),
  high('高値'),
  low('低値'),
  unknown('不明');

  const JudgmentFlag(this.label);
  final String label;
}
