// 画像前処理サービス [UC-02]
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// OCR精度向上のための画像前処理パイプライン
///
/// クリーンなデジタル画像（PDF変換等）はそのまま渡す。
/// カメラ撮影画像はEXIF回転を適用。
/// デコード失敗時は元画像をそのまま返す（ML Kitがネイティブ処理）。
class ImagePreprocessor {
  /// 前処理を実行（Isolateで非同期処理）
  Future<File> process(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final processed = await compute(_processImage, bytes);

      // 処理結果がnullの場合は元ファイルをそのまま返す
      if (processed == null) return imageFile;

      final outputPath =
          '${imageFile.parent.path}/preprocessed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(processed);
      return outputFile;
    } on Exception {
      // 前処理失敗時は元画像をそのまま返す（ML Kitがネイティブで処理）
      return imageFile;
    }
  }

  static Uint8List? _processImage(Uint8List bytes) {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      // EXIF回転情報を適用（iPhoneの回転メタデータ対応）
      final oriented = img.bakeOrientation(image);

      return Uint8List.fromList(img.encodeJpg(oriented, quality: 95));
    } on Exception {
      return null;
    }
  }
}
