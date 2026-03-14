// OCR + パース統合サービス [UC-02]
import 'dart:io';

import 'package:kenviz/infrastructure/ocr/ocr_engine.dart';
import 'package:kenviz/infrastructure/parsers/parsed_checkup_result.dart';
import 'package:kenviz/infrastructure/parsers/parser_factory.dart';

/// 画像 → OCR → パース の一気通貫サービス
class OcrService {
  OcrService({
    required OcrEngine ocrEngine,
    required ParserFactory parserFactory,
  }) : _ocrEngine = ocrEngine,
       _parserFactory = parserFactory;

  final OcrEngine _ocrEngine;
  final ParserFactory _parserFactory;

  /// 画像ファイルから健診結果をパース
  Future<ParsedCheckupResult> processImage(File imageFile) async {
    // ML KitはiOS上でJPEG/HEIC/PNGをネイティブ処理し、
    // EXIF回転も自動適用するため、前処理をバイパスして直接渡す
    final ocrResult = await _ocrEngine.recognizeFromFile(imageFile);

    // パーサー自動選択 + パース
    final parsed = _parserFactory.parse(ocrResult);
    return ParsedCheckupResult(
      rows: parsed.rows,
      detectedFormat: parsed.detectedFormat,
      facilityName: parsed.facilityName,
      checkupDate: parsed.checkupDate,
      overallConfidence: parsed.overallConfidence,
      rawOcrText: ocrResult.fullText,
    );
  }

  /// リソース解放
  Future<void> dispose() async {
    await _ocrEngine.dispose();
  }
}
