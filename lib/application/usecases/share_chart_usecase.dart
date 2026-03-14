// チャート画像共有ユースケース [UC-12]
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// チャートウィジェットをキャプチャして共有する
class ShareChartUseCase {
  /// RenderRepaintBoundaryからキャプチャ→共有
  Future<void> execute({
    required RenderRepaintBoundary boundary,
    required String fileName,
  }) async {
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('画像のキャプチャに失敗しました');
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName.png');
    await file.writeAsBytes(byteData.buffer.asUint8List());

    await Share.shareXFiles([XFile(file.path)]);
  }
}
