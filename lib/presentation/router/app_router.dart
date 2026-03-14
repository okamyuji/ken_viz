// go_router ルーティング設定
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kenviz/presentation/pages/chart_detail_page.dart';
import 'package:kenviz/presentation/pages/checkup_detail_page.dart';
import 'package:kenviz/presentation/pages/dashboard_page.dart';
import 'package:kenviz/presentation/pages/history_list_page.dart';
import 'package:kenviz/presentation/pages/manual_input_page.dart';
import 'package:kenviz/presentation/pages/ocr_confirm_page.dart';
import 'package:kenviz/presentation/pages/scan_page.dart';
import 'package:kenviz/presentation/pages/settings_page.dart';
import 'package:kenviz/presentation/pages/share_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// アプリのルーター設定
final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => _ScaffoldWithNav(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: DashboardPage()),
        ),
        GoRoute(
          path: '/history',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: HistoryListPage()),
        ),
      ],
    ),
    // push で遷移する画面（戻るボタンが自動で効く）
    GoRoute(
      path: '/scan',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ScanPage(),
    ),
    GoRoute(
      path: '/confirm',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const OcrConfirmPage(),
    ),
    GoRoute(
      path: '/checkup/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          CheckupDetailPage(checkupId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/chart/:itemCode',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          ChartDetailPage(itemCode: state.pathParameters['itemCode']!),
    ),
    GoRoute(
      path: '/share/:checkupId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          SharePage(checkupId: state.pathParameters['checkupId']!),
    ),
    GoRoute(
      path: '/manual-input',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ManualInputPage(),
    ),
    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SettingsPage(),
    ),
  ],
);

/// ボトムナビゲーション付きシェル
class _ScaffoldWithNav extends StatelessWidget {
  const _ScaffoldWithNav({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final index = _selectedIndex(context);
    final title = switch (index) {
      1 => '健診履歴',
      _ => 'KenViz',
    };

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex(context),
        onDestinationSelected: (index) => _onTap(context, index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'ダッシュボード'),
          NavigationDestination(icon: Icon(Icons.history), label: '履歴'),
          NavigationDestination(icon: Icon(Icons.settings), label: '設定'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/scan'),
        child: const Icon(Icons.camera_alt),
      ),
    );
  }

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/history')) return 1;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
      case 1:
        context.go('/history');
      case 2:
        context.push('/settings');
    }
  }
}
