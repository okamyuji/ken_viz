import 'dart:io';

import 'package:kenviz/infrastructure/parsers/parser_strategy.dart';

/// OCRエンジンの抽象インターフェース
///
/// テスト時にモックへ差し替え可能にする。
abstract class OcrEngine {
  /// 画像ファイルからテキストを認識
  Future<OcrTextResult> recognizeFromFile(File imageFile);

  /// リソース解放
  Future<void> dispose();
}
