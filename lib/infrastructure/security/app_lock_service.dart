// アプリロックサービス [NFR-SEC-01]
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// バイオメトリクス/PINによるアプリロック
class AppLockService {
  AppLockService({LocalAuthentication? auth})
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  /// デバイスが生体認証をサポートしているか
  Future<bool> isSupported() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  /// 認証を実行
  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'KenVizのロックを解除してください',
        options: const AuthenticationOptions(stickyAuth: true),
      );
    } on PlatformException {
      return false;
    }
  }
}
