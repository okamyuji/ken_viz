// 健診履歴リスト [UC-05]
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kenviz/domain/entities/checkup.dart';
import 'package:kenviz/presentation/providers/dashboard_providers.dart';
import 'package:kenviz/presentation/providers/repository_providers.dart';

/// 過去の健診一覧を表示するページ
class HistoryListPage extends ConsumerStatefulWidget {
  const HistoryListPage({super.key});

  @override
  ConsumerState<HistoryListPage> createState() => _HistoryListPageState();
}

class _HistoryListPageState extends ConsumerState<HistoryListPage> {
  List<Checkup>? _checkups;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCheckups();
  }

  Future<void> _loadCheckups() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = ref.read(checkupRepositoryProvider);
      final data = await repo.getByProfileId('default');
      if (mounted) setState(() => _checkups = data);
    } on Exception catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCheckup(Checkup checkup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除確認'),
        content: Text(
          '${DateFormat('yyyy年M月d日').format(checkup.date)} の健診データを削除しますか？\nこの操作は取り消せません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final resultRepo = ref.read(testResultRepositoryProvider);
    final checkupRepo = ref.read(checkupRepositoryProvider);

    await resultRepo.deleteByCheckupId(checkup.id);
    await checkupRepo.delete(checkup.id);

    ref.invalidate(dashboardSummaryProvider);
    await _loadCheckups();

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('健診データを削除しました')));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('エラー: $_error'));
    }

    final checkups = _checkups ?? [];
    if (checkups.isEmpty) {
      return const Center(child: Text('健診データがありません'));
    }

    final dateFormat = DateFormat('yyyy年M月d日');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: checkups.length,
      itemBuilder: (context, index) {
        final checkup = checkups[index];
        return Dismissible(
          key: Key(checkup.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) async {
            await _deleteCheckup(checkup);
            return false; // _deleteCheckupがリロードするのでDismissible側では消さない
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          child: Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.assignment),
              title: Text(dateFormat.format(checkup.date)),
              subtitle: checkup.facilityName != null
                  ? Text(checkup.facilityName!)
                  : null,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/checkup/${checkup.id}'),
            ),
          ),
        );
      },
    );
  }
}
