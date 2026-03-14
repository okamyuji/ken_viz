// OCR関連 Provider [UC-02]
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kenviz/application/services/ocr_service.dart';
import 'package:kenviz/core/constants/test_item_defaults.dart';
import 'package:kenviz/infrastructure/ocr/mlkit_ocr_engine.dart';
import 'package:kenviz/infrastructure/ocr/ocr_model_service.dart';
import 'package:kenviz/infrastructure/parsers/parsed_checkup_result.dart';
import 'package:kenviz/infrastructure/parsers/parser_factory.dart';

/// OcrService プロバイダ
final ocrServiceProvider = Provider<OcrService>((ref) {
  final engine = MlKitOcrEngine();
  final factory = ParserFactory(defaultTestItems);
  final service = OcrService(ocrEngine: engine, parserFactory: factory);
  ref.onDispose(service.dispose);
  return service;
});

/// パース結果を一時保持する Notifier
class ParsedResultNotifier extends Notifier<ParsedCheckupResult?> {
  @override
  ParsedCheckupResult? build() => null;

  // ignore: use_setters_to_change_properties
  void set(ParsedCheckupResult? result) {
    state = result;
  }

  void clear() {
    state = null;
  }
}

/// パース結果プロバイダ
final parsedResultProvider =
    NotifierProvider<ParsedResultNotifier, ParsedCheckupResult?>(
      ParsedResultNotifier.new,
    );

/// OCRモデル準備サービス プロバイダ
final ocrModelServiceProvider = Provider<OcrModelService>((ref) {
  final service = OcrModelService();
  ref.onDispose(service.dispose);
  return service;
});
