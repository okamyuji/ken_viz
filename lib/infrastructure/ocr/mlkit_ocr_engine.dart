// ML Kit OCR エンジン実装
import 'dart:io';
import 'dart:ui';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:kenviz/infrastructure/ocr/ocr_engine.dart';
import 'package:kenviz/infrastructure/parsers/parser_strategy.dart';

/// [UC-02] ML Kit on-device OCR エンジン
class MlKitOcrEngine implements OcrEngine {
  MlKitOcrEngine()
    : _recognizer = TextRecognizer(script: TextRecognitionScript.japanese);

  final TextRecognizer _recognizer;

  @override
  Future<OcrTextResult> recognizeFromFile(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognized = await _recognizer.processImage(inputImage);
    return _convert(recognized);
  }

  @override
  Future<void> dispose() async {
    await _recognizer.close();
  }

  OcrTextResult _convert(RecognizedText recognized) {
    final blocks = recognized.blocks.map((block) {
      final lines = block.lines.map((line) {
        final elements = line.elements.map((element) {
          return OcrTextElement(
            text: element.text,
            boundingBox: _toBoundingBox(element.boundingBox),
          );
        }).toList();

        return OcrTextLine(
          text: line.text,
          elements: elements,
          boundingBox: _toBoundingBox(line.boundingBox),
        );
      }).toList();

      return OcrTextBlock(
        lines: lines,
        boundingBox: _toBoundingBox(block.boundingBox),
      );
    }).toList();

    return OcrTextResult(blocks: blocks, fullText: recognized.text);
  }

  BoundingBox? _toBoundingBox(Rect? rect) {
    if (rect == null) return null;
    return BoundingBox(
      left: rect.left,
      top: rect.top,
      right: rect.right,
      bottom: rect.bottom,
    );
  }
}
