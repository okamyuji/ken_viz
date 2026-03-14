// バウンディングボックスを使った検査項目マッチング [UC-02]

import 'package:kenviz/core/utils/text_normalizer.dart';
import 'package:kenviz/domain/entities/test_item_master.dart';
import 'package:kenviz/domain/value_objects/value_objects.dart';
import 'package:kenviz/infrastructure/parsers/item_matcher.dart';
import 'package:kenviz/infrastructure/parsers/parsed_checkup_result.dart';
import 'package:kenviz/infrastructure/parsers/parser_strategy.dart';

/// 既知の検査項目名をOCR結果から探し、
/// 同一Y座標にある数値を紐付けて検査結果を構築する。
///
/// 従来のパーサーは「項目名と値が同一行にある」前提だが、
/// ML KitはPDFテーブルを列ごとにバラバラに読むため、
/// バウンディングボックスの位置関係で紐付ける必要がある。
class SpatialItemMatcher {
  SpatialItemMatcher(this._masters);

  final List<TestItemMaster> _masters;

  /// OCR結果から検査項目をマッチング
  ParsedCheckupResult match(OcrTextResult ocrResult) {
    final matcher = ItemMatcher(_masters);

    // 全テキスト行をバウンディングボックス付きで収集
    final allLines = <_PositionedLine>[];
    for (final block in ocrResult.blocks) {
      for (final line in block.lines) {
        if (line.boundingBox != null) {
          allLines.add(_PositionedLine(
            text: line.text,
            box: line.boundingBox!,
          ));
        }
      }
    }

    if (allLines.isEmpty) {
      return const ParsedCheckupResult(
        rows: [],
        detectedFormat: CheckupFormat.tableVertical,
      );
    }

    // Step 1: 既知の検査項目名にマッチする行を探す
    final itemLines = <_MatchedItemLine>[];
    for (final line in allLines) {
      final normalized = TextNormalizer.normalize(line.text);
      final result = matcher.match(normalized);
      if (result != null && result.confidence >= 0.6) {
        itemLines.add(_MatchedItemLine(
          line: line,
          matchResult: result,
        ));
      }
    }

    // Step 2: 数値を含む行を収集
    final numericLines = <_NumericLine>[];
    for (final line in allLines) {
      final text = TextNormalizer.toHalfWidth(line.text).trim();
      final num = _extractNumber(text);
      if (num != null) {
        numericLines.add(_NumericLine(
          line: line,
          value: num,
          rawText: text,
        ));
      }
    }

    // Step 3: 各項目に対して同一Y座標の数値を探す
    final rows = <ParsedResultRow>[];
    final usedNumericLines = <int>{};

    for (final item in itemLines) {
      final itemCenterY = item.line.box.centerY;
      final itemHeight = item.line.box.height;
      // 行の高さの70%以内を同一行とみなす
      final yTolerance = itemHeight * 0.7;

      // 同一Y座標の数値を探す（項目の右側にあるもの優先）
      _NumericLine? bestMatch;
      var bestScore = double.infinity;

      for (var i = 0; i < numericLines.length; i++) {
        if (usedNumericLines.contains(i)) continue;
        final numLine = numericLines[i];

        final yDiff = (numLine.line.box.centerY - itemCenterY).abs();
        if (yDiff > yTolerance) continue;

        // 項目名の右側にある数値を優先
        final xDiff = numLine.line.box.centerX - item.line.box.right;
        if (xDiff < -item.line.box.width) continue; // 項目より大きく左は除外

        final score = yDiff + (xDiff < 0 ? 1000 : xDiff * 0.1);
        if (score < bestScore) {
          bestScore = score;
          bestMatch = numLine;
        }
      }

      if (bestMatch == null) continue;

      // この数値を使用済みにする
      final usedIdx = numericLines.indexOf(bestMatch);
      usedNumericLines.add(usedIdx);

      // 値の信頼度を推定（自動補正はしない — 医療データの改変は危険）
      final valueConf = _estimateValueConfidence(
        bestMatch.value,
        item.matchResult.item,
      );

      // 同一Y座標の単位テキストを探す
      String? unit;
      for (final line in allLines) {
        if (line == item.line || line == bestMatch.line) continue;
        final yDiff = (line.box.centerY - itemCenterY).abs();
        if (yDiff > yTolerance) continue;
        final extractedUnit = TextNormalizer.extractUnit(line.text);
        if (extractedUnit != null) {
          unit = extractedUnit;
          break;
        }
      }

      rows.add(ParsedResultRow(
        itemName: ParsedField(
          value: item.matchResult.item.standardName,
          confidence: ConfidenceScore(item.matchResult.confidence),
          rawText: item.line.text,
        ),
        matchedItemCode: item.matchResult.item.id,
        value: ParsedField(
          value: bestMatch.value,
          confidence: ConfidenceScore(valueConf),
          rawText: bestMatch.rawText,
        ),
        unit: ParsedField(
          value: unit ?? item.matchResult.item.unit ?? '',
          confidence: ConfidenceScore(unit != null ? 0.9 : 0.7),
        ),
        overallConfidence: ConfidenceScore(
          (item.matchResult.confidence + valueConf) / 2,
        ),
      ));
    }

    // 同一itemCodeの重複を除去（最初に見つかったもの＝今回の値を採用）
    final seen = <String>{};
    final deduped = <ParsedResultRow>[];
    for (final row in rows) {
      final code = row.matchedItemCode;
      if (code != null && seen.contains(code)) continue;
      if (code != null) seen.add(code);

      // 明らかに異常な値をフィルタリング
      if (row.value != null && _isImplausible(row.value!.value, code)) continue;

      deduped.add(row);
    }

    return ParsedCheckupResult(
      rows: deduped,
      detectedFormat: CheckupFormat.tableVertical,
      overallConfidence: ConfidenceScore(
        deduped.isEmpty
            ? 0.0
            : deduped.map((r) => r.overallConfidence.value).reduce((a, b) => a + b) /
                  deduped.length,
      ),
    );
  }

  /// テキストから数値を抽出
  double? _extractNumber(String text) {
    // "131~163" のような基準範囲は除外
    if (RegExp(r'\d+\s*[~〜\-–—]\s*\d+').hasMatch(text)) return null;
    // "1/5-6視野" のような表記は除外
    if (RegExp(r'\d+/\d+').hasMatch(text)) return null;
    // "%o", "万/μL" など単位のみの行は除外
    if (RegExp(r'^[%‰]+$').hasMatch(text.trim())) return null;

    final match = RegExp(r'^[^\d]*(\d+\.?\d*)\s*$').firstMatch(text);
    if (match == null) return null;
    return double.tryParse(match.group(1)!);
  }

  /// 値が明らかに異常かチェック
  bool _isImplausible(double value, String? itemCode) {
    if (itemCode == null) return false;
    // 血圧が10未満は明らかに異常（7.0 mmHg等）
    if ((itemCode == 'BP_SYS' || itemCode == 'BP_DIA') && value < 30) {
      return true;
    }
    return false;
  }

  /// 値の信頼度を推定（基準範囲と大きくずれている場合は低信頼度）
  ///
  /// 自動補正は行わない。医療データの勝手な改変は危険なため、
  /// 異常値の可能性がある場合は低信頼度として確認画面で警告する。
  double _estimateValueConfidence(double value, TestItemMaster item) {
    final low = item.defaultRefLow;
    final high = item.defaultRefHigh;

    if (low == null && high == null) return 0.8;

    // 基準範囲の10倍以上は小数点消失の可能性大 → 低信頼度
    if (high != null && value > high * 10) return 0.3;
    if (low != null && value > low * 20) return 0.3;

    // 基準範囲の5倍以上はやや疑わしい
    if (high != null && value > high * 5) return 0.5;

    return 0.8;
  }
}

class _PositionedLine {
  const _PositionedLine({required this.text, required this.box});
  final String text;
  final BoundingBox box;
}

class _MatchedItemLine {
  const _MatchedItemLine({required this.line, required this.matchResult});
  final _PositionedLine line;
  final MatchResult matchResult;
}

class _NumericLine {
  const _NumericLine({
    required this.line,
    required this.value,
    required this.rawText,
  });
  final _PositionedLine line;
  final double value;
  final String rawText;
}
