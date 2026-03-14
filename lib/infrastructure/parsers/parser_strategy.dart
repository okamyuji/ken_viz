import 'package:kenviz/infrastructure/parsers/parsed_checkup_result.dart';

/// OCRエンジンからの出力を抽象化したクラス
///
/// ML Kit の RecognizedText を直接依存せず、
/// テスト時にはモックデータを注入できるようにする。
class OcrTextResult {
  const OcrTextResult({required this.blocks, required this.fullText});

  /// テキストブロック（段落単位）
  final List<OcrTextBlock> blocks;

  /// 全テキスト結合
  final String fullText;

  /// 全行を取得
  List<OcrTextLine> get allLines => blocks.expand((b) => b.lines).toList();
}

/// テキストブロック（段落やセクション単位）
class OcrTextBlock {
  const OcrTextBlock({required this.lines, this.boundingBox});

  final List<OcrTextLine> lines;
  final BoundingBox? boundingBox;
}

/// テキスト行
class OcrTextLine {
  const OcrTextLine({
    required this.text,
    required this.elements,
    this.boundingBox,
  });

  final String text;
  final List<OcrTextElement> elements;
  final BoundingBox? boundingBox;
}

/// テキスト要素（単語単位）
class OcrTextElement {
  const OcrTextElement({required this.text, this.boundingBox});

  final String text;
  final BoundingBox? boundingBox;
}

/// バウンディングボックス
class BoundingBox {
  const BoundingBox({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final double left;
  final double top;
  final double right;
  final double bottom;

  double get width => right - left;
  double get height => bottom - top;
  double get centerX => (left + right) / 2;
  double get centerY => (top + bottom) / 2;
}

/// パーサー Strategy Interface
///
/// 各フォーマットに対応するパーサーはこのインターフェースを実装する。
abstract class CheckupParser {
  /// このパーサーで処理可能かのスコアを返す (0.0〜1.0)
  ///
  /// - 1.0: 確実にこのフォーマット
  /// - 0.0: このフォーマットではない
  double canParse(OcrTextResult ocrResult);

  /// パース実行
  ParsedCheckupResult parse(OcrTextResult ocrResult);

  /// このパーサーが対応するフォーマット
  CheckupFormat get format;
}
