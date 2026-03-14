import 'package:kenviz/core/utils/text_normalizer.dart';
import 'package:kenviz/domain/entities/test_item_master.dart';
import 'package:kenviz/domain/value_objects/value_objects.dart';
import 'package:kenviz/infrastructure/parsers/item_matcher.dart';
import 'package:kenviz/infrastructure/parsers/parsed_checkup_result.dart';
import 'package:kenviz/infrastructure/parsers/parser_strategy.dart';

/// タイプC: フリーテキストパーサー（フォールバック）
///
/// 表罫線のないレイアウト。行ごとに「ラベル 数値 単位」を探す。
class FreetextParser implements CheckupParser {
  FreetextParser(this._masters);

  final List<TestItemMaster> _masters;

  @override
  CheckupFormat get format => CheckupFormat.freetext;

  @override
  double canParse(OcrTextResult ocrResult) {
    // フォールバックとして常に低スコアで受け入れ可能
    return 0.3;
  }

  @override
  ParsedCheckupResult parse(OcrTextResult ocrResult) {
    final matcher = ItemMatcher(_masters);
    final rows = <ParsedResultRow>[];

    // 「項目名 数値」パターンを各行から探す
    final pattern = RegExp(
      r'([^\d]{2,})\s+(\d+\.?\d*)\s*(mg/dL|g/dL|U/L|mmHg|%|cm|kg)?',
    );

    for (final line in ocrResult.allLines) {
      final text = TextNormalizer.normalize(line.text);
      final match = pattern.firstMatch(text);
      if (match == null) continue;

      final itemNameRaw = match.group(1)!.trim();
      final valueStr = match.group(2)!;
      final unitStr = match.group(3);

      final matchResult = matcher.match(itemNameRaw);
      final numValue = double.tryParse(valueStr);
      if (numValue == null) continue;

      rows.add(
        ParsedResultRow(
          itemName: ParsedField(
            value: itemNameRaw,
            confidence: ConfidenceScore(matchResult?.confidence ?? 0.4),
            rawText: itemNameRaw,
          ),
          matchedItemCode: matchResult?.item.id,
          value: ParsedField(
            value: numValue,
            confidence: const ConfidenceScore(0.7),
            rawText: valueStr,
          ),
          unit: unitStr != null
              ? ParsedField(
                  value: unitStr,
                  confidence: const ConfidenceScore(0.8),
                )
              : null,
          overallConfidence: ConfidenceScore(matchResult != null ? 0.65 : 0.4),
        ),
      );
    }

    return ParsedCheckupResult(
      rows: rows,
      detectedFormat: format,
      overallConfidence: ConfidenceScore(
        rows.isEmpty
            ? 0.0
            : rows
                      .map((r) => r.overallConfidence.value)
                      .reduce((a, b) => a + b) /
                  rows.length,
      ),
    );
  }
}
