// ManualInputPage Widgetテスト [UC-02]
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kenviz/domain/entities/checkup.dart';
import 'package:kenviz/domain/entities/test_result.dart';
import 'package:kenviz/domain/repositories/repositories.dart';
import 'package:kenviz/presentation/pages/manual_input_page.dart';
import 'package:kenviz/presentation/providers/repository_providers.dart';

class _FakeCheckupRepository implements CheckupRepository {
  final saved = <Checkup>[];

  @override
  Future<void> save(Checkup checkup) async => saved.add(checkup);

  @override
  Future<Checkup?> getById(String id) async => null;

  @override
  Future<List<Checkup>> getByProfileId(String profileId) async => [];

  @override
  Future<Checkup?> getLatestByProfileId(String profileId) async => null;

  @override
  Future<void> delete(String id) async {}
}

class _FakeTestResultRepository implements TestResultRepository {
  final saved = <TestResult>[];

  @override
  Future<void> saveAll(List<TestResult> results) async => saved.addAll(results);

  @override
  Future<List<TestResult>> getByCheckupId(String checkupId) async => [];

  @override
  Future<List<TestResult>> getByItemCode({
    required String profileId,
    required String itemCode,
  }) async => [];

  @override
  Future<void> update(TestResult result) async {}

  @override
  Future<void> deleteByCheckupId(String checkupId) async {}
}

void main() {
  group('ManualInputPage', () {
    testWidgets('初期表示で受診日と1行の入力欄が表示される', (tester) async {
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
          child: const MaterialApp(home: ManualInputPage()),
        ),
      );

      expect(find.text('手動入力'), findsOneWidget);
      expect(find.text('受診日'), findsOneWidget);
      expect(find.text('項目名 #1'), findsOneWidget);
      expect(find.text('結果値'), findsOneWidget);
      expect(find.text('単位'), findsOneWidget);
    });

    testWidgets('「項目を追加」で入力行が増える', (tester) async {
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
          child: const MaterialApp(home: ManualInputPage()),
        ),
      );

      expect(find.text('項目名 #1'), findsOneWidget);
      expect(find.text('項目名 #2'), findsNothing);

      await tester.tap(find.text('項目を追加'));
      await tester.pump();

      expect(find.text('項目名 #2'), findsOneWidget);
    });
  });
}
