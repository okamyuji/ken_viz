// ダッシュボードページ [UC-04]
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kenviz/domain/entities/test_result.dart';
import 'package:kenviz/presentation/providers/dashboard_providers.dart';

/// カテゴリ別サマリーを表示するダッシュボード
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('エラー: $e')),
      data: (summary) {
        if (summary.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.health_and_safety,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                const Text('まだ健診データがありません'),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () => context.push('/scan'),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('スキャン'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: summary.length,
          itemBuilder: (context, index) {
            final category = summary[index];
            return _CategoryCard(
              categoryName: category.categoryName,
              items: category.items,
              onTap: () => context.go('/history', extra: category.categoryId),
            );
          },
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.categoryName,
    required this.items,
    required this.onTap,
  });

  final String categoryName;
  final List<DashboardItem> items;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                categoryName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...items.map((item) => _ItemRow(item: item)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final DashboardItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (item.judgment) {
      JudgmentFlag.normal => Colors.green,
      JudgmentFlag.high => Colors.red,
      JudgmentFlag.low => Colors.orange,
      JudgmentFlag.unknown => Colors.grey,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(item.itemName, style: theme.textTheme.bodyMedium),
          ),
          Text(
            item.value != null
                ? '${item.value}${item.unit != null ? " ${item.unit}" : ""}'
                : item.valueText ?? '-',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          if (item.changeArrow != null) ...[
            const SizedBox(width: 4),
            Icon(
              item.changeArrow == ChangeDirection.up
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
              size: 16,
              color: color,
            ),
          ],
        ],
      ),
    );
  }
}
