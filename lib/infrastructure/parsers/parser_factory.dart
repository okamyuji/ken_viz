import 'package:kenviz/domain/entities/test_item_master.dart';
import 'package:kenviz/infrastructure/parsers/freetext_parser.dart';
import 'package:kenviz/infrastructure/parsers/parsed_checkup_result.dart';
import 'package:kenviz/infrastructure/parsers/parser_strategy.dart';
import 'package:kenviz/infrastructure/parsers/spatial_row_reconstructor.dart';
import 'package:kenviz/infrastructure/parsers/table_vertical_parser.dart';

/// パーサーファクトリ
///
/// OCR結果のフォーマットを自動判定し、最適なパーサーを選択する。
/// バウンディングボックスが利用可能な場合は空間マッチングを先に試行する。
class ParserFactory {
  ParserFactory(List<TestItemMaster> masters) : _masters = masters {
    _parsers = [
      TableVerticalParser(masters),
      FreetextParser(masters), // フォールバック（常に最後）
    ];
  }

  final List<TestItemMaster> _masters;
  late final List<CheckupParser> _parsers;

  /// 最適なパーサーを選択
  CheckupParser selectParser(OcrTextResult ocrResult) {
    final scored =
        _parsers
            .map((p) => _ScoredParser(parser: p, score: p.canParse(ocrResult)))
            .toList()
          ..sort((a, b) => b.score.compareTo(a.score));

    return scored.first.parser;
  }

  /// フォーマット自動判定してパース実行
  ///
  /// まず空間マッチング（既知項目名→同一Y座標の数値紐付け）を試み、
  /// 結果が良好ならそれを採用。不十分なら通常パースにフォールバック。
  ParsedCheckupResult parse(OcrTextResult ocrResult) {
    // 1. 空間マッチングを試行（バウンディングボックスがある場合）
    final hasBoundingBoxes = ocrResult.blocks.any(
      (b) => b.lines.any((l) => l.boundingBox != null),
    );

    if (hasBoundingBoxes) {
      final spatialMatcher = SpatialItemMatcher(_masters);
      final spatialResult = spatialMatcher.match(ocrResult);
      if (spatialResult.rows.length >= 2) {
        return spatialResult;
      }
    }

    // 2. 通常パース（フォールバック）
    final parser = selectParser(ocrResult);
    return parser.parse(ocrResult);
  }

  /// 全パーサーのスコアを返す（デバッグ用）
  Map<CheckupFormat, double> scoreAll(OcrTextResult ocrResult) {
    return {
      for (final parser in _parsers) parser.format: parser.canParse(ocrResult),
    };
  }
}

class _ScoredParser {
  const _ScoredParser({required this.parser, required this.score});
  final CheckupParser parser;
  final double score;
}
