import 'package:kenviz/domain/value_objects/value_objects.dart';

/// パース結果全体
class ParsedCheckupResult {
  const ParsedCheckupResult({
    required this.rows,
    required this.detectedFormat,
    this.facilityName,
    this.checkupDate,
    this.overallConfidence = const ConfidenceScore(0.0),
    this.rawOcrText = '',
  });

  final List<ParsedResultRow> rows;
  final CheckupFormat detectedFormat;
  final ParsedField<String>? facilityName;
  final ParsedField<DateTime>? checkupDate;
  final ConfidenceScore overallConfidence;

  /// OCR生テキスト（デバッグ・診断用）
  final String rawOcrText;

  /// 要確認行の数
  int get rowsNeedingConfirmation =>
      rows.where((r) => r.needsConfirmation).length;

  /// 全行の平均信頼度
  double get averageConfidence {
    if (rows.isEmpty) return 0.0;
    final sum = rows.fold<double>(0.0, (s, r) => s + r.overallConfidence.value);
    return sum / rows.length;
  }
}

/// パース済み1行（1検査項目）
class ParsedResultRow {
  const ParsedResultRow({
    required this.itemName,
    this.matchedItemCode,
    this.value,
    this.valueText,
    this.unit,
    this.refRange,
    this.flag,
    required this.overallConfidence,
  });

  /// OCRで読み取った検査項目名
  final ParsedField<String> itemName;

  /// マスタとマッチした項目コード (null = マッチ失敗)
  final String? matchedItemCode;

  /// 数値結果
  final ParsedField<double>? value;

  /// テキスト結果（定性）
  final ParsedField<String>? valueText;

  /// 単位
  final ParsedField<String>? unit;

  /// 基準範囲
  final ParsedField<String>? refRange;

  /// 判定フラグ
  final ParsedField<String>? flag;

  /// 行全体の信頼度
  final ConfidenceScore overallConfidence;

  /// 要確認か
  bool get needsConfirmation => overallConfidence.needsUserConfirmation;

  /// refRange文字列からReferenceRangeをパース
  ReferenceRange? get parsedRefRange {
    if (refRange == null) return null;
    return _parseReferenceRange(refRange!.value);
  }

  static ReferenceRange? _parseReferenceRange(String text) {
    // "70〜139", "70-139", "70 ~ 139", "≦139", "≧70" 等をパース
    final rangePattern = RegExp(r'(\d+\.?\d*)\s*[〜~\-–—]\s*(\d+\.?\d*)');
    final match = rangePattern.firstMatch(text);
    if (match != null) {
      return ReferenceRange(
        low: double.tryParse(match.group(1)!),
        high: double.tryParse(match.group(2)!),
      );
    }

    // 上限のみ: "≦139", "139以下"
    final upperPattern = RegExp(r'[≦≤]?\s*(\d+\.?\d*)\s*以下?');
    final upperMatch = upperPattern.firstMatch(text);
    if (upperMatch != null) {
      return ReferenceRange(high: double.tryParse(upperMatch.group(1)!));
    }

    // 下限のみ: "≧70", "70以上"
    final lowerPattern = RegExp(r'[≧≥]?\s*(\d+\.?\d*)\s*以上?');
    final lowerMatch = lowerPattern.firstMatch(text);
    if (lowerMatch != null) {
      return ReferenceRange(low: double.tryParse(lowerMatch.group(1)!));
    }

    return null;
  }
}

/// 検出されたフォーマット種別
enum CheckupFormat {
  tableVertical('タイプA: 縦型表'),
  tableHorizontal('タイプB: 横型表'),
  freetext('タイプC: フリーテキスト'),
  unknown('不明');

  const CheckupFormat(this.label);
  final String label;
}
