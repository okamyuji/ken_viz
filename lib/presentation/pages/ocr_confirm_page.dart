// OCR結果 確認・修正ページ [UC-03]
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kenviz/core/constants/test_item_defaults.dart';
import 'package:kenviz/domain/entities/checkup.dart';
import 'package:kenviz/domain/entities/test_result.dart' as domain;
import 'package:kenviz/infrastructure/parsers/item_matcher.dart';
import 'package:kenviz/presentation/providers/dashboard_providers.dart';
import 'package:kenviz/presentation/providers/ocr_providers.dart';
import 'package:kenviz/presentation/providers/repository_providers.dart';
import 'package:uuid/uuid.dart';

/// OCR結果の確認・修正画面
class OcrConfirmPage extends ConsumerStatefulWidget {
  const OcrConfirmPage({super.key});

  @override
  ConsumerState<OcrConfirmPage> createState() => _OcrConfirmPageState();
}

class _OcrConfirmPageState extends ConsumerState<OcrConfirmPage> {
  late List<_EditableRow> _rows;
  String _rawOcrText = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final result = ref.read(parsedResultProvider);
    _rawOcrText = result?.rawOcrText ?? '';
    _rows =
        result?.rows
            .map(
              (r) => _EditableRow(
                itemName: r.itemName.value,
                matchedItemCode: r.matchedItemCode,
                value: r.value?.value.toString() ?? '',
                unit: r.unit?.value ?? '',
                refRange: r.refRange?.value ?? '',
                flag: r.flag?.value ?? '',
                confidence: r.overallConfidence.value,
              ),
            )
            .toList() ??
        [];
  }

  /// スキャン画面に戻って撮り直し
  void _retake() {
    ref.read(parsedResultProvider.notifier).clear();
    // confirm → scan の2画面分 pop して scan に戻る
    context.pop(); // confirm → scan
  }

  Future<void> _save() async {
    // 既存checkupがある場合、上書きか新規か選択
    final checkupRepo = ref.read(checkupRepositoryProvider);
    final existing = await checkupRepo.getByProfileId('default');

    if (!mounted) return;

    String? overwriteCheckupId;
    if (existing.isNotEmpty) {
      final dialogResult = await _showSaveOptionDialog(existing);
      if (!mounted) return;
      // キャンセルまたはバックキーで閉じた場合
      if (dialogResult == '_cancelled' || dialogResult == '_dismissed') return;
      // '_new' = 新規保存、それ以外 = 上書き対象のcheckupId
      if (dialogResult != '_new') {
        overwriteCheckupId = dialogResult;
      }
    }

    setState(() => _isSaving = true);

    try {
      const uuid = Uuid();
      final now = DateTime.now();

      final isOverwrite = overwriteCheckupId != null;
      final checkupId = overwriteCheckupId ?? uuid.v4();

      if (isOverwrite) {
        // 上書き: 既存の検査結果を削除
        await ref
            .read(testResultRepositoryProvider)
            .deleteByCheckupId(checkupId);
        // checkupのupdatedAtを更新
        final old = existing.firstWhere((c) => c.id == checkupId);
        await checkupRepo.save(old.copyWith(updatedAt: now));
      } else {
        final checkup = Checkup(
          id: checkupId,
          profileId: 'default',
          date: now,
          createdAt: now,
          updatedAt: now,
        );
        await checkupRepo.save(checkup);
      }

      // 保存時にItemMatcherで再マッチングし、一貫したitemCodeを付与
      final matcher = ItemMatcher(defaultTestItems);

      final testResults = <domain.TestResult>[];
      for (final row in _rows) {
        final value = double.tryParse(row.valueController.text);
        if (value == null && row.valueController.text.isEmpty) continue;

        // matchedItemCodeがない場合、項目名から再マッチング
        final itemName = row.itemNameController.text;
        String itemCode;
        if (row.matchedItemCode != null) {
          itemCode = row.matchedItemCode!;
        } else {
          final matchResult = matcher.match(itemName);
          itemCode = matchResult?.item.id ?? itemName;
        }

        final refRange = _parseRefRange(row.refRangeController.text);
        testResults.add(
          domain.TestResult(
            id: uuid.v4(),
            checkupId: checkupId,
            itemCode: itemCode,
            itemName: itemName,
            value: value,
            valueText: value == null ? row.valueController.text : null,
            unit: row.unitController.text.isEmpty
                ? null
                : row.unitController.text,
            refLow: refRange?.$1,
            refHigh: refRange?.$2,
            flag: row.flagController.text.isEmpty
                ? null
                : row.flagController.text,
            confidence: row.confidence,
          ),
        );
      }

      await ref.read(testResultRepositoryProvider).saveAll(testResults);

      if (!mounted) return;
      ref.read(parsedResultProvider.notifier).clear();
      ref.invalidate(dashboardSummaryProvider);
      context.go('/');
      final msg = isOverwrite
          ? '既存データを上書きしました'
          : '${testResults.length}件の検査結果を保存しました';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存に失敗しました: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// 新規保存 or 既存上書きを選択するダイアログ
  /// 戻り値: '_new'=新規, checkupId=上書き対象,
  ///         '_cancelled'=キャンセル, null=バックキー
  Future<String?> _showSaveOptionDialog(List<Checkup> checkups) async {
    final dateFormat = DateFormat('yyyy/M/d HH:mm');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('保存方法を選択'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop('_new'),
            child: const ListTile(
              leading: Icon(Icons.add_circle_outline),
              title: Text('新規として保存'),
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text('既存データを上書き:', style: TextStyle(fontSize: 12)),
          ),
          ...checkups.map(
            (c) => SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(c.id),
              child: ListTile(
                leading: const Icon(Icons.refresh),
                title: Text(dateFormat.format(c.date)),
                subtitle: c.facilityName != null ? Text(c.facilityName!) : null,
              ),
            ),
          ),
          const Divider(),
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop('_cancelled'),
            child: const Center(child: Text('キャンセル')),
          ),
        ],
      ),
    );
    return result ?? '_dismissed';
  }

  (double?, double?)? _parseRefRange(String text) {
    if (text.isEmpty) return null;
    final rangeMatch = RegExp(
      r'(\d+\.?\d*)\s*[〜~\-–—]\s*(\d+\.?\d*)',
    ).firstMatch(text);
    if (rangeMatch != null) {
      return (
        double.tryParse(rangeMatch.group(1)!),
        double.tryParse(rangeMatch.group(2)!),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('確認・修正'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _retake,
            icon: const Icon(Icons.camera_alt),
            label: const Text('撮り直し'),
          ),
          TextButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: const Icon(Icons.save),
            label: const Text('保存'),
          ),
        ],
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : _rows.isEmpty
          ? _buildEmptyState(theme)
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _rows.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final row = _rows[index];
                final isLowConf = row.confidence < 0.7;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isLowConf
                        ? theme.colorScheme.errorContainer.withAlpha(50)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    border: isLowConf
                        ? Border.all(color: theme.colorScheme.error)
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: row.itemNameController,
                              decoration: const InputDecoration(
                                labelText: '検査項目',
                                isDense: true,
                              ),
                            ),
                          ),
                          if (isLowConf)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Chip(
                                label: Text(
                                  '要確認 ${(row.confidence * 100).toInt()}%',
                                ),
                                backgroundColor:
                                    theme.colorScheme.errorContainer,
                                labelStyle: TextStyle(
                                  color: theme.colorScheme.onErrorContainer,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: row.valueController,
                              decoration: const InputDecoration(
                                labelText: '結果値',
                                isDense: true,
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: row.unitController,
                              decoration: const InputDecoration(
                                labelText: '単位',
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: row.refRangeController,
                              decoration: const InputDecoration(
                                labelText: '基準値',
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 48,
                            child: TextField(
                              controller: row.flagController,
                              decoration: const InputDecoration(
                                labelText: '判定',
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('検査項目を読み取れませんでした'),
            ),
          ),
          if (_rawOcrText.isNotEmpty) ...[
            const Divider(),
            Text('OCR生テキスト（デバッグ用）', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _rawOcrText,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }
}

class _EditableRow {
  _EditableRow({
    required String itemName,
    required this.matchedItemCode,
    required String value,
    required String unit,
    required String refRange,
    required String flag,
    required this.confidence,
  }) : itemNameController = TextEditingController(text: itemName),
       valueController = TextEditingController(text: value),
       unitController = TextEditingController(text: unit),
       refRangeController = TextEditingController(text: refRange),
       flagController = TextEditingController(text: flag);

  final String? matchedItemCode;
  final double confidence;
  final TextEditingController itemNameController;
  final TextEditingController valueController;
  final TextEditingController unitController;
  final TextEditingController refRangeController;
  final TextEditingController flagController;

  void dispose() {
    itemNameController.dispose();
    valueController.dispose();
    unitController.dispose();
    refRangeController.dispose();
    flagController.dispose();
  }
}
