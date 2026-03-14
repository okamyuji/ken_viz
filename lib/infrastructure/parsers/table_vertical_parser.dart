import 'package:kenviz/core/utils/text_normalizer.dart';
import 'package:kenviz/domain/entities/test_item_master.dart';
import 'package:kenviz/domain/value_objects/value_objects.dart';
import 'package:kenviz/infrastructure/parsers/item_matcher.dart';
import 'package:kenviz/infrastructure/parsers/parsed_checkup_result.dart';
import 'package:kenviz/infrastructure/parsers/parser_strategy.dart';

/// タイプA: 縦型表形式パーサー
///
/// 検査項目が左列、数値が右列のレイアウト。
/// 大手企業の健診結果に多いフォーマット。
///
/// 想定レイアウト:
/// ```
/// 検査項目    | 結果  | 基準値     | 判定
/// ────────────┼──────┼──────────┼────
/// 身長        | 170.5 | -         | A
/// 体重        | 65.0  | -         | A
/// BMI         | 22.4  | 18.5〜24.9 | A
/// 血圧(上)    | 128   | 〜129      | A
/// ```
class TableVerticalParser implements CheckupParser {
  TableVerticalParser(this._masters);

  final List<TestItemMaster> _masters;

  @override
  CheckupFormat get format => CheckupFormat.tableVertical;

  @override
  double canParse(OcrTextResult ocrResult) {
    final lines = ocrResult.allLines;
    if (lines.length < 3) return 0.0;

    var score = 0.0;
    var tableLineCnt = 0;
    var matchedItemCnt = 0;

    final matcher = ItemMatcher(_masters);

    for (final line in lines) {
      final halfWidth = TextNormalizer.toHalfWidth(line.text);
      final parts = _splitLine(halfWidth);

      // 2列以上に分割できる行が多い → テーブル構造
      if (parts.length >= 2) tableLineCnt++;

      // 行の先頭部分がマスタにマッチする → 検査項目行
      if (parts.isNotEmpty &&
          matcher.match(TextNormalizer.normalize(parts[0])) != null) {
        matchedItemCnt++;
      }
    }

    // テーブル構造率
    if (lines.isNotEmpty) {
      score += (tableLineCnt / lines.length) * 0.5;
    }
    // マスタマッチ率
    if (tableLineCnt > 0) {
      score += (matchedItemCnt / tableLineCnt) * 0.5;
    }

    return score.clamp(0.0, 1.0);
  }

  @override
  ParsedCheckupResult parse(OcrTextResult ocrResult) {
    final matcher = ItemMatcher(_masters);
    final rows = <ParsedResultRow>[];

    for (final line in ocrResult.allLines) {
      // タブ等の区切り文字を保持するため、先に分割してから各パーツを正規化
      final halfWidth = TextNormalizer.toHalfWidth(line.text);
      final parts = _splitLine(halfWidth);

      if (parts.length < 2) continue;

      final itemNameRaw = TextNormalizer.normalize(parts[0]);
      final matchResult = matcher.match(itemNameRaw);

      // 数値を探す
      ParsedField<double>? valueParsed;
      ParsedField<String>? unitParsed;
      ParsedField<String>? refRangeParsed;
      ParsedField<String>? flagParsed;

      for (var i = 1; i < parts.length; i++) {
        final part = parts[i];

        // 数値
        if (valueParsed == null) {
          final num = TextNormalizer.extractNumber(part);
          if (num != null) {
            valueParsed = ParsedField(
              value: num,
              confidence: ConfidenceScore(_estimateNumericConfidence(part)),
              rawText: part,
            );
            continue;
          }
        }

        // 基準範囲
        if (refRangeParsed == null) {
          final range = TextNormalizer.extractRange(part);
          if (range != null) {
            refRangeParsed = ParsedField(
              value: part,
              confidence: const ConfidenceScore(0.85),
              rawText: part,
            );
            continue;
          }
        }

        // 判定フラグ
        if (flagParsed == null) {
          final flag = TextNormalizer.extractFlag(part);
          if (flag != null) {
            flagParsed = ParsedField(
              value: flag,
              confidence: const ConfidenceScore(0.9),
              rawText: part,
            );
            continue;
          }
        }

        // 単位
        if (unitParsed == null) {
          final unit = TextNormalizer.extractUnit(part);
          if (unit != null) {
            unitParsed = ParsedField(
              value: unit,
              confidence: const ConfidenceScore(0.9),
              rawText: part,
            );
          }
        }
      }

      // 数値もテキスト結果もない行はスキップ
      if (valueParsed == null) continue;

      // 行の信頼度を算出
      final confidences = <double>[
        matchResult?.confidence ?? 0.5,
        valueParsed.confidence.value,
      ];
      if (refRangeParsed != null) {
        confidences.add(refRangeParsed.confidence.value);
      }
      final avgConf = confidences.reduce((a, b) => a + b) / confidences.length;

      rows.add(
        ParsedResultRow(
          itemName: ParsedField(
            value: itemNameRaw,
            confidence: ConfidenceScore(matchResult?.confidence ?? 0.5),
            rawText: itemNameRaw,
          ),
          matchedItemCode: matchResult?.item.id,
          value: valueParsed,
          unit:
              unitParsed ??
              (matchResult != null && matchResult.item.unit != null
                  ? ParsedField(
                      value: matchResult.item.unit!,
                      confidence: const ConfidenceScore(0.7),
                    )
                  : null),
          refRange: refRangeParsed,
          flag: flagParsed,
          overallConfidence: ConfidenceScore(avgConf),
        ),
      );
    }

    final overallConf = rows.isEmpty
        ? 0.0
        : rows.map((r) => r.overallConfidence.value).reduce((a, b) => a + b) /
              rows.length;

    return ParsedCheckupResult(
      rows: rows,
      detectedFormat: format,
      overallConfidence: ConfidenceScore(overallConf),
    );
  }

  /// 行をカラムに分割
  ///
  /// タブ、複数スペース、パイプ文字等で分割
  List<String> _splitLine(String text) {
    // タブ区切り
    if (text.contains('\t')) {
      return text
          .split('\t')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    // パイプ区切り
    if (text.contains('|') || text.contains('│') || text.contains('｜')) {
      return text
          .split(RegExp('[|│｜]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    // 3つ以上の連続スペースで区切り
    if (RegExp(r'\s{3,}').hasMatch(text)) {
      return text
          .split(RegExp(r'\s{3,}'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    // 2つ以上の連続スペースで区切り
    if (RegExp(r'\s{2,}').hasMatch(text)) {
      return text
          .split(RegExp(r'\s{2,}'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [text];
  }

  /// 数値の信頼度推定
  double _estimateNumericConfidence(String text) {
    final normalized = TextNormalizer.toHalfWidth(text).trim();
    // きれいな数値パターンなら高信頼
    if (RegExp(r'^\d+\.?\d*$').hasMatch(normalized)) return 0.95;
    // 前後に余計な文字がある場合
    if (RegExp(r'\d+\.?\d*').hasMatch(normalized)) return 0.75;
    return 0.5;
  }
}
