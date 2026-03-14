// OCRモデル準備ページ
import 'package:flutter/material.dart';

/// ML Kit モデルのダウンロード/準備中に表示するページ
class ModelDownloadPage extends StatelessWidget {
  const ModelDownloadPage({required this.status, this.onRetry, super.key});

  final ModelDownloadStatus status;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                status == ModelDownloadStatus.error
                    ? Icons.error_outline
                    : Icons.download,
                size: 64,
                color: status == ModelDownloadStatus.error
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                _title,
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (status == ModelDownloadStatus.downloading) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  '通信中...',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (status == ModelDownloadStatus.error && onRetry != null)
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('再試行'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String get _title => switch (status) {
    ModelDownloadStatus.checking => 'OCRモデルを確認中...',
    ModelDownloadStatus.downloading => '日本語OCRモデルを準備中',
    ModelDownloadStatus.error => 'モデルの準備に失敗しました',
    ModelDownloadStatus.ready => '準備完了',
  };

  String get _subtitle => switch (status) {
    ModelDownloadStatus.checking => 'しばらくお待ちください',
    ModelDownloadStatus.downloading => '初回のみモデルのダウンロードが必要です。\nインターネット接続が必要です。',
    ModelDownloadStatus.error => 'インターネット接続を確認して再試行してください。',
    ModelDownloadStatus.ready => '',
  };
}

/// モデル準備状態
enum ModelDownloadStatus { checking, downloading, ready, error }
