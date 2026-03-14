// カメラ撮影 / ギャラリー選択ページ [UC-01]
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kenviz/presentation/pages/model_download_page.dart';
import 'package:kenviz/presentation/providers/ocr_providers.dart';

/// 健診結果の画像取得ページ
class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({super.key});

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage> {
  final _picker = ImagePicker();
  bool _isProcessing = false;
  ModelDownloadStatus? _modelStatus;

  @override
  void initState() {
    super.initState();
    _checkModelReady();
  }

  /// モデル準備状態を確認し、未準備ならダウンロードを実行
  Future<void> _checkModelReady() async {
    setState(() => _modelStatus = ModelDownloadStatus.checking);

    // ダウンロード中表示に切り替え
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _modelStatus = ModelDownloadStatus.downloading);

    final ready = await ref.read(ocrModelServiceProvider).ensureModelReady();
    if (!mounted) return;

    if (ready) {
      setState(() => _modelStatus = null);
    } else {
      setState(() => _modelStatus = ModelDownloadStatus.error);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      requestFullMetadata: false,
    );
    if (picked == null || !mounted) return;

    setState(() => _isProcessing = true);

    try {
      final file = File(picked.path);
      final result = await ref.read(ocrServiceProvider).processImage(file);
      if (!mounted) return;
      // OcrConfirmPageへ遷移（結果を渡す）
      ref.read(parsedResultProvider.notifier).set(result);
      if (mounted) unawaited(context.push('/confirm'));
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('OCR処理に失敗しました: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // モデル準備中はダウンロードページを表示
    if (_modelStatus != null) {
      return ModelDownloadPage(
        status: _modelStatus!,
        onRetry: _modelStatus == ModelDownloadStatus.error
            ? _checkModelReady
            : null,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('スキャン')),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('OCR処理中...'),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.document_scanner,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '健診結果を撮影またはギャラリーから選択してください',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  FilledButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('カメラで撮影'),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('ギャラリーから選択'),
                  ),
                ],
              ),
            ),
    );
  }
}
