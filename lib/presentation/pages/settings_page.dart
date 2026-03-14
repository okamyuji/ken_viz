// 設定ページ [UC-11]
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kenviz/presentation/providers/repository_providers.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kAppLockKey = 'app_lock_enabled';

/// アプリ設定画面
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _appLockEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _appLockEnabled = prefs.getBool(_kAppLockKey) ?? false;
    });
  }

  Future<void> _setAppLock(bool value) async {
    if (value) {
      // ONにする前に生体認証が使えるか確認
      final auth = LocalAuthentication();
      try {
        final canAuth = await auth.canCheckBiometrics ||
            await auth.isDeviceSupported();
        if (!canAuth) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('この端末では生体認証が利用できません')),
          );
          return;
        }
        // 実際に認証して本人確認
        final authenticated = await auth.authenticate(
          localizedReason: 'アプリロックを有効にするには認証が必要です',
        );
        if (!authenticated) return;
      } on PlatformException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('認証エラー: ${e.message}')),
        );
        return;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAppLockKey, value);
    if (!mounted) return;
    setState(() => _appLockEnabled = value);
  }

  Future<void> _confirmDeleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('全データ削除'),
        content: const Text('すべての健診データを削除します。\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final checkupRepo = ref.read(checkupRepositoryProvider);
      final resultRepo = ref.read(testResultRepositoryProvider);

      final checkups = await checkupRepo.getByProfileId('default');
      for (final c in checkups) {
        await resultRepo.deleteByCheckupId(c.id);
        await checkupRepo.delete(c.id);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('すべてのデータを削除しました')));
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('削除に失敗しました: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          const _SectionHeader(title: 'セキュリティ'),
          SwitchListTile(
            title: const Text('アプリロック'),
            subtitle: const Text('起動時に生体認証/PINで保護'),
            value: _appLockEnabled,
            onChanged: _setAppLock,
          ),
          const Divider(),
          const _SectionHeader(title: 'データ管理'),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('全データ削除'),
            subtitle: const Text('すべての健診データを削除します'),
            onTap: _confirmDeleteAll,
          ),
          const Divider(),
          const _SectionHeader(title: 'アプリ情報'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('バージョン'),
            subtitle: Text('1.0.0'),
          ),
          const ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('プライバシー'),
            subtitle: Text('すべてのデータは端末内にのみ保存されます'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
