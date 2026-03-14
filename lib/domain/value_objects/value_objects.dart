import 'package:kenviz/domain/entities/test_result.dart';

/// 基準範囲 値オブジェクト [VO-02]
class ReferenceRange {
  const ReferenceRange({this.low, this.high});

  final double? low;
  final double? high;

  /// 基準値判定
  JudgmentFlag judge(double value) {
    if (high != null && value > high!) return JudgmentFlag.high;
    if (low != null && value < low!) return JudgmentFlag.low;
    return JudgmentFlag.normal;
  }

  /// 基準範囲の中央値（正規化用）
  double? get midpoint {
    if (low != null && high != null) return (low! + high!) / 2;
    return null;
  }

  /// 境界付近か（基準値の±10%以内）
  bool isNearBoundary(double value) {
    if (high != null) {
      final margin = high! * 0.1;
      if (value > high! - margin && value <= high!) return true;
    }
    if (low != null) {
      final margin = low! * 0.1;
      if (value < low! + margin && value >= low!) return true;
    }
    return false;
  }

  @override
  String toString() {
    if (low != null && high != null) return '$low〜$high';
    if (low != null) return '$low以上';
    if (high != null) return '$high以下';
    return '-';
  }
}

/// OCR信頼度 値オブジェクト [VO-03]
class ConfidenceScore {
  const ConfidenceScore(this.value)
    : assert(value >= 0.0 && value <= 1.0, 'value must be 0.0〜1.0');

  final double value;

  ConfidenceLevel get level {
    if (value >= 0.9) return ConfidenceLevel.high;
    if (value >= 0.7) return ConfidenceLevel.medium;
    return ConfidenceLevel.low;
  }

  bool get needsUserConfirmation => value < 0.7;

  @override
  String toString() => '${(value * 100).toStringAsFixed(0)}%';
}

/// 信頼度レベル
enum ConfidenceLevel {
  high('高'),
  medium('中'),
  low('低');

  const ConfidenceLevel(this.label);
  final String label;
}

/// パース済み1フィールド（信頼度付き）
class ParsedField<T> {
  const ParsedField({
    required this.value,
    required this.confidence,
    this.rawText,
  });

  final T value;
  final ConfidenceScore confidence;
  final String? rawText;

  bool get needsConfirmation => confidence.needsUserConfirmation;
}
