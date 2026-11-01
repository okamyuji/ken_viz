import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kenviz/infrastructure/security/app_lock_service.dart';
import 'package:local_auth/local_auth.dart';

class _FakeAuth extends LocalAuthentication {
  _FakeAuth(this._result);

  final Future<bool> Function() _result;
  bool? persistAcrossBackgrounding;

  @override
  Future<bool> authenticate({
    required String localizedReason,
    Iterable<Object?> authMessages = const <Object?>[],
    bool biometricOnly = false,
    bool sensitiveTransaction = true,
    bool persistAcrossBackgrounding = false,
  }) {
    this.persistAcrossBackgrounding = persistAcrossBackgrounding;
    return _result();
  }
}

void main() {
  test('returns the platform result and keeps the prompt across backgrounding', () async {
    final auth = _FakeAuth(() async => true);

    expect(await AppLockService(auth: auth).authenticate(), isTrue);
    expect(auth.persistAcrossBackgrounding, isTrue);
  });

  test('returns false when local_auth throws LocalAuthException', () async {
    final auth = _FakeAuth(
      () => Future<bool>.error(
        const LocalAuthException(code: LocalAuthExceptionCode.userCanceled),
      ),
    );

    expect(await AppLockService(auth: auth).authenticate(), isFalse);
  });

  test('returns false when the platform throws PlatformException', () async {
    final auth = _FakeAuth(
      () => Future<bool>.error(PlatformException(code: 'NotAvailable')),
    );

    expect(await AppLockService(auth: auth).authenticate(), isFalse);
  });
}
