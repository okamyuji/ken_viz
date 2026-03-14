import 'package:kenviz/core/utils/text_normalizer.dart';
import 'package:kenviz/domain/entities/test_item_master.dart';

/// マスタとのマッチング結果
class MatchResult {
  const MatchResult({required this.item, required this.confidence});

  final TestItemMaster item;
  final double confidence;
}

/// 検査項目名をマスタと照合する
///
/// 3段階マッチング:
///   Phase 1: 完全一致 (confidence: 1.0)
///   Phase 2: 正規化後一致 (confidence: 0.95)
///   Phase 3: ファジーマッチ (confidence: 0.6〜0.9)
class ItemMatcher {
  ItemMatcher(this._masters);

  final List<TestItemMaster> _masters;

  /// OCRテキストをマスタと照合
  MatchResult? match(String ocrText) {
    final trimmed = ocrText.trim();
    if (trimmed.isEmpty) return null;

    // Phase 1: 完全一致
    final exact = _findExact(trimmed);
    if (exact != null) return MatchResult(item: exact, confidence: 1.0);

    // Phase 2: 正規化後一致
    final normalized = TextNormalizer.normalizeItemName(trimmed);
    final normMatch = _findNormalized(normalized);
    if (normMatch != null) {
      return MatchResult(item: normMatch, confidence: 0.95);
    }

    // Phase 3: ファジーマッチ
    return _findFuzzy(normalized);
  }

  /// Phase 1: 完全一致
  TestItemMaster? _findExact(String text) {
    for (final master in _masters) {
      if (master.standardName == text) return master;
      if (master.aliases.contains(text)) return master;
    }
    return null;
  }

  /// Phase 2: 正規化後一致
  TestItemMaster? _findNormalized(String normalizedText) {
    for (final master in _masters) {
      final normalizedStd = TextNormalizer.normalizeItemName(
        master.standardName,
      );
      if (normalizedStd == normalizedText) return master;

      for (final alias in master.aliases) {
        if (TextNormalizer.normalizeItemName(alias) == normalizedText) {
          return master;
        }
      }
    }
    return null;
  }

  /// Phase 3: ファジーマッチ
  MatchResult? _findFuzzy(String normalizedText) {
    var bestScore = 0.0;
    TestItemMaster? bestMatch;

    for (final master in _masters) {
      final scores = <double>[
        TextNormalizer.similarityScore(
          normalizedText,
          TextNormalizer.normalizeItemName(master.standardName),
        ),
        ...master.aliases.map(
          (a) => TextNormalizer.similarityScore(
            normalizedText,
            TextNormalizer.normalizeItemName(a),
          ),
        ),
      ];

      final maxScore = scores.reduce((a, b) => a > b ? a : b);
      if (maxScore > bestScore) {
        bestScore = maxScore;
        bestMatch = master;
      }
    }

    // 閾値以上のみ返す
    if (bestMatch != null && bestScore > 0.6) {
      // ファジーマッチのconfidenceは0.6〜0.9にスケール
      final confidence = 0.6 + (bestScore - 0.6) * 0.75;
      return MatchResult(
        item: bestMatch,
        confidence: confidence.clamp(0.0, 0.9),
      );
    }

    return null;
  }
}
