import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kenviz/app.dart';
import 'package:kenviz/infrastructure/datasources/drift/database_provider.dart';
import 'package:kenviz/presentation/providers/repository_providers.dart';

/// ネットワーク通信を遮断する HttpOverrides [NFR-SEC-02]
///
/// ML Kit モデルDL用のホスト（dl.google.com等）のみ許可し、
/// その他の通信を遮断する。
class NoNetworkHttpOverrides extends HttpOverrides {
  /// ML Kit モデルDLに必要なホスト
  static const _allowedHosts = [
    'dl.google.com',
    'storage.googleapis.com',
    'firebaseml.googleapis.com',
  ];

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..findProxy = (uri) {
        if (_allowedHosts.contains(uri.host)) {
          return 'DIRECT';
        }
        // 許可リスト外のホストへの接続を遮断
        throw UnsupportedError('KenViz: ${uri.host} への通信はブロックされました。');
      };
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ネットワーク遮断（ML Kitモデルダウンロード用ホストのみ許可）[NFR-SEC-02]
  HttpOverrides.global = NoNetworkHttpOverrides();

  // DB初期化 + マスタデータシード
  final db = await openDatabase();

  runApp(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: const KenVizApp(),
    ),
  );
}
