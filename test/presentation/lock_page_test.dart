import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kenviz/presentation/pages/lock_page.dart';
import 'package:local_auth/local_auth.dart';

void main() {
  test('uses the local_auth description when there is one', () {
    const e = LocalAuthException(
      code: LocalAuthExceptionCode.noBiometricsEnrolled,
      description: '生体情報が登録されていません',
    );
    expect(authErrorMessage(e), '生体情報が登録されていません');
  });

  test('uses the platform message when there is one', () {
    expect(
      authErrorMessage(PlatformException(code: 'x', message: '端末エラー')),
      '端末エラー',
    );
  });

  test('falls back to a fixed message when the error has no text', () {
    const e = LocalAuthException(code: LocalAuthExceptionCode.userCanceled);
    expect(authErrorMessage(e), '認証に失敗しました');
    expect(authErrorMessage(PlatformException(code: 'x')), '認証に失敗しました');
    expect(authErrorMessage(Exception('other')), '認証に失敗しました');
  });
}
