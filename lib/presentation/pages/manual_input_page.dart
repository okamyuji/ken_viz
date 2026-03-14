// 手動入力ページ [UC-02]
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kenviz/core/constants/test_item_defaults.dart';
import 'package:kenviz/domain/entities/checkup.dart';
import 'package:kenviz/domain/entities/test_result.dart';
import 'package:kenviz/infrastructure/parsers/item_matcher.dart';
import 'package:kenviz/presentation/providers/repository_providers.dart';
import 'package:uuid/uuid.dart';

/// 検査結果の手動入力画面
class ManualInputPage extends ConsumerStatefulWidget {
  const ManualInputPage({super.key});

  @override
  ConsumerState<ManualInputPage> createState() => _ManualInputPageState();
}

class _ManualInputPageState extends ConsumerState<ManualInputPage> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _rows = <_ManualRow>[];
  bool _isSaving = false;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _dateController.text = _formatDate(_selectedDate);
    _addRow();
  }

  String _formatDate(DateTime date) => '${date.year}/${date.month}/${date.day}';

  void _addRow() {
    setState(() {
      _rows.add(_ManualRow());
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      const uuid = Uuid();
      final checkupId = uuid.v4();
      final now = DateTime.now();

      final checkup = Checkup(
        id: checkupId,
        profileId: 'default',
        date: _selectedDate,
        createdAt: now,
        updatedAt: now,
      );

      final matcher = ItemMatcher(defaultTestItems);

      final results = <TestResult>[];
      for (final row in _rows) {
        final name = row.nameController.text.trim();
        if (name.isEmpty) continue;

        final value = double.tryParse(row.valueController.text);
        final matchResult = matcher.match(name);
        final itemCode = matchResult?.item.id ?? name;

        results.add(
          TestResult(
            id: uuid.v4(),
            checkupId: checkupId,
            itemCode: itemCode,
            itemName: name,
            value: value,
            valueText: value == null ? row.valueController.text : null,
            unit: row.unitController.text.isEmpty
                ? null
                : row.unitController.text,
          ),
        );
      }

      if (results.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('少なくとも1つの検査項目を入力してください')));
        return;
      }

      await ref.read(checkupRepositoryProvider).save(checkup);
      await ref.read(testResultRepositoryProvider).saveAll(results);

      if (!mounted) return;
      context.go('/');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${results.length}件の検査結果を保存しました')));
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存に失敗しました: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('手動入力'),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: const Icon(Icons.save),
            label: const Text('保存'),
          ),
        ],
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _dateController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: '受診日',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 16),
                  ..._rows.asMap().entries.map(
                    (e) => _RowInput(
                      row: e.value,
                      index: e.key,
                      onRemove: () {
                        setState(() => _rows.removeAt(e.key));
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _addRow,
                    icon: const Icon(Icons.add),
                    label: const Text('項目を追加'),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }
}

class _ManualRow {
  final nameController = TextEditingController();
  final valueController = TextEditingController();
  final unitController = TextEditingController();

  void dispose() {
    nameController.dispose();
    valueController.dispose();
    unitController.dispose();
  }
}

class _RowInput extends StatelessWidget {
  const _RowInput({
    required this.row,
    required this.index,
    required this.onRemove,
  });

  final _ManualRow row;
  final int index;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: row.nameController,
                decoration: InputDecoration(
                  labelText: '項目名 #${index + 1}',
                  isDense: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return '必須';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: row.valueController,
                decoration: const InputDecoration(
                  labelText: '結果値',
                  isDense: true,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: row.unitController,
                decoration: const InputDecoration(
                  labelText: '単位',
                  isDense: true,
                ),
              ),
            ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.remove_circle_outline),
              iconSize: 20,
            ),
          ],
        ),
      ),
    );
  }
}
