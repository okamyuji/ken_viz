// 健診詳細ページ [UC-05]
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kenviz/domain/entities/test_result.dart';
import 'package:kenviz/presentation/providers/repository_providers.dart';

/// 1回の健診の全検査結果を表示するページ
class CheckupDetailPage extends ConsumerWidget {
  const CheckupDetailPage({required this.checkupId, super.key});

  final String checkupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultRepo = ref.watch(testResultRepositoryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('検査結果一覧')),
      body: FutureBuilder<List<TestResult>>(
        future: resultRepo.getByCheckupId(checkupId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('エラー: ${snapshot.error}'));
          }

          final rawResults = snapshot.data ?? [];
          if (rawResults.isEmpty) {
            return const Center(child: Text('検査結果がありません'));
          }

          // 同一itemCodeの重複を除去し、異常値をフィルタ
          final seen = <String>{};
          final results = <TestResult>[];
          for (final r in rawResults) {
            if (seen.contains(r.itemCode)) continue;
            seen.add(r.itemCode);
            // 血圧30未満など明らかに異常な値を除外
            if ((r.itemCode == 'BP_SYS' || r.itemCode == 'BP_DIA') &&
                r.value != null &&
                r.value! < 30) {
              continue;
            }
            results.add(r);
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: results.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final result = results[index];
              final color = switch (result.judgment) {
                JudgmentFlag.normal => Colors.green,
                JudgmentFlag.high => Colors.red,
                JudgmentFlag.low => Colors.orange,
                JudgmentFlag.unknown => Colors.grey,
              };

              return ListTile(
                leading: Icon(Icons.circle, size: 12, color: color),
                title: Text(result.itemName),
                subtitle: _buildRefRange(result, theme),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      result.value != null
                          ? result.value.toString()
                          : result.valueText ?? '-',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (result.unit != null)
                      Text(result.unit!, style: theme.textTheme.bodySmall),
                  ],
                ),
                onTap: result.isQuantitative
                    ? () => context.push('/chart/${result.itemCode}')
                    : null,
              );
            },
          );
        },
      ),
    );
  }

  Widget? _buildRefRange(TestResult result, ThemeData theme) {
    if (result.refLow == null && result.refHigh == null) return null;
    final low = result.refLow?.toString() ?? '';
    final high = result.refHigh?.toString() ?? '';
    return Text(
      '基準値: $low〜$high',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
