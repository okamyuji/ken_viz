// ML Kit モデル準備サービス
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

/// ML Kit 日本語テキスト認識モデルの準備状態を管理する
///
/// google_mlkit_text_recognition 0.14.0 では ModelManager が
/// TextRecognizer に公開されていないため、ダミー画像による
/// ウォームアップで初回モデルDLをトリガーする。
class OcrModelService {
  TextRecognizer? _recognizer;

  /// モデルが使用可能か確認・準備する
  ///
  /// 小さな白画像で processImage を実行し、成功すればモデルDL済み。
  /// 初回はモデルDLが走るため時間がかかる場合がある。
  Future<bool> ensureModelReady() async {
    _recognizer ??= TextRecognizer(script: TextRecognitionScript.japanese);
    try {
      final dummyFile = await _createDummyImage();
      try {
        final inputImage = InputImage.fromFile(dummyFile);
        await _recognizer!.processImage(inputImage);
        return true;
      } finally {
        if (dummyFile.existsSync()) {
          dummyFile.deleteSync();
        }
      }
    } on PlatformException {
      return false;
    }
  }

  /// 1x1 白画像PNGファイルを生成
  Future<File> _createDummyImage() async {
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawColor(const ui.Color(0xFFFFFFFF), ui.BlendMode.src);
    final picture = recorder.endRecording();
    final image = await picture.toImage(1, 1);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/kenviz_warmup.png');
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<void> dispose() async {
    await _recognizer?.close();
    _recognizer = null;
  }
}
