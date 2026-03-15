// SettingsPage Widgetテスト [UC-11]
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kenviz/domain/entities/checkup.dart';
import 'package:kenviz/domain/entities/test_result.dart';
import 'package:kenviz/domain/repositories/repositories.dart';
import 'package:kenviz/presentation/pages/settings_page.dart';
import 'package:kenviz/presentation/providers/repository_providers.dart';

class _FakeCheckupRepository implements CheckupRepository {
  @override
  Future<Checkup?> getById(String id) async => null;

  @override
  Future<List<Checkup>> getByProfileId(String profileId) async => [];

  @override
  Future<Checkup?> getLatestByProfileId(String profileId) async => null;

  @override
  Future<void> save(Checkup checkup) async {}

  @override
  Future<void> delete(String id) async {}
}

class _FakeTestResultRepository implements TestResultRepository {
  @override
  Future<List<TestResult>> getByCheckupId(String checkupId) async => [];

  @override
  Future<List<TestResult>> getByItemCode({
    required String profileId,
    required String itemCode,
  }) async => [];

  @override
  Future<void> saveAll(List<TestResult> results) async {}

  @override
  Future<void> update(TestResult result) async {}

  @override
  Future<void> deleteByCheckupId(String checkupId) async {}
}

void main() {
  group('SettingsPage', () {
    testWidgets('主要な設定項目が表示される', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            checkupRepositoryProvider.overrideWithValue(
              _FakeCheckupRepository(),
            ),
            testResultRepositoryProvider.overrideWithValue(
              _FakeTestResultRepository(),
            ),
          ],
          child: const MaterialApp(home: SettingsPage()),
        ),
      );

      expect(find.text('設定'), findsOneWidget);
      expect(find.text('セキュリティ'), findsOneWidget);
      expect(find.text('アプリロック'), findsOneWidget);
      expect(find.text('データ管理'), findsOneWidget);
      expect(find.text('全データ削除'), findsOneWidget);
      expect(find.text('アプリ情報'), findsOneWidget);
      expect(find.text('バージョン'), findsOneWidget);
      expect(find.text('プライバシー'), findsOneWidget);
    });

    testWidgets('全データ削除で確認ダイアログが表示される', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            checkupRepositoryProvider.overrideWithValue(
              _FakeCheckupRepository(),
            ),
            testResultRepositoryProvider.overrideWithValue(
              _FakeTestResultRepository(),
            ),
          ],
          child: const MaterialApp(home: SettingsPage()),
        ),
      );

      await tester.tap(find.text('全データ削除'));
      await tester.pumpAndSettle();

      expect(find.text('すべての健診データを削除します。\nこの操作は取り消せません。'), findsOneWidget);
      expect(find.text('キャンセル'), findsOneWidget);
      expect(find.text('削除'), findsOneWidget);
    });
  });
}
