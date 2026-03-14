// ロック画面 [NFR-SEC-01]
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// アプリ起動時の生体認証ロック画面
class LockPage extends StatefulWidget {
  const LockPage({required this.onUnlocked, super.key});

  final VoidCallback onUnlocked;

  @override
  State<LockPage> createState() => _LockPageState();
}

class _LockPageState extends State<LockPage> {
  final _auth = LocalAuthentication();
  String? _error;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    // 起動直後に自動で認証ダイアログを表示
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    setState(() {
      _isAuthenticating = true;
      _error = null;
    });

    try {
      final canAuth = await _auth.canCheckBiometrics ||
          await _auth.isDeviceSupported();
      if (!canAuth) {
        // 生体認証非対応の端末はそのまま解除
        if (mounted) widget.onUnlocked();
        return;
      }

      final authenticated = await _auth.authenticate(
        localizedReason: '健診データにアクセスするには認証が必要です',
        options: const AuthenticationOptions(
          stickyAuth: true,
        ),
      );

      if (!mounted) return;
      if (authenticated) {
        widget.onUnlocked();
      } else {
        setState(() => _error = '認証がキャンセルされました');
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message ?? '認証に失敗しました');
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('KenViz', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              '認証してロックを解除してください',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isAuthenticating ? null : _authenticate,
              icon: const Icon(Icons.fingerprint),
              label: const Text('ロック解除'),
            ),
          ],
        ),
      ),
    );
  }
}
