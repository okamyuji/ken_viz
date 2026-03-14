import 'package:flutter/material.dart';
import 'package:kenviz/presentation/pages/lock_page.dart';
import 'package:kenviz/presentation/router/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kAppLockKey = 'app_lock_enabled';

/// KenViz アプリのルートWidget
class KenVizApp extends StatefulWidget {
  const KenVizApp({super.key});

  @override
  State<KenVizApp> createState() => _KenVizAppState();
}

class _KenVizAppState extends State<KenVizApp> {
  bool _locked = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _checkLock();
  }

  Future<void> _checkLock() async {
    final prefs = await SharedPreferences.getInstance();
    final lockEnabled = prefs.getBool(_kAppLockKey) ?? false;
    setState(() {
      _locked = lockEnabled;
      _initialized = true;
    });
  }

  void _unlock() {
    setState(() => _locked = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'KenViz',
      debugShowCheckedModeBanner: false,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      // ignore: avoid_redundant_argument_values
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
      builder: (context, child) {
        if (!_initialized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (_locked) {
          return LockPage(onUnlocked: _unlock);
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }

  static final _lightTheme = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: const Color(0xFF1B4F72),
    brightness: Brightness.light,
    fontFamily: 'NotoSansJP',
  );

  static final _darkTheme = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: const Color(0xFF2E86C1),
    brightness: Brightness.dark,
    fontFamily: 'NotoSansJP',
  );
}
