// 共有ページ [UC-10, UC-12]
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kenviz/application/services/pdf_generator_service.dart';
import 'package:kenviz/application/usecases/export_pdf_usecase.dart';
import 'package:kenviz/presentation/providers/repository_providers.dart';
import 'package:share_plus/share_plus.dart';

/// 健診結果の共有画面
class SharePage extends ConsumerStatefulWidget {
  const SharePage({required this.checkupId, super.key});

  final String checkupId;

  @override
  ConsumerState<SharePage> createState() => _SharePageState();
}

class _SharePageState extends ConsumerState<SharePage> {
  bool _isExporting = false;

  Future<void> _exportPdf() async {
    setState(() => _isExporting = true);
    try {
      final useCase = ExportPdfUseCase(
        checkupRepository: ref.read(checkupRepositoryProvider),
        testResultRepository: ref.read(testResultRepositoryProvider),
        pdfGenerator: PdfGeneratorService(),
      );
      final path = await useCase.execute(widget.checkupId);

      await Share.shareXFiles([XFile(path)]);
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF生成に失敗しました: $e')));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('共有')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('PDFレポート'),
                subtitle: const Text('検査結果を一覧形式でPDF出力'),
                trailing: _isExporting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.share),
                onTap: _isExporting ? null : _exportPdf,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '共有はOS標準のShare Sheetを使用します。\nデータはアプリ外に送信されることはありません。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
