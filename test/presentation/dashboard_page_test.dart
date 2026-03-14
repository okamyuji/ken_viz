// DashboardPage Widgetテスト [UC-04]
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kenviz/domain/entities/checkup.dart';
import 'package:kenviz/domain/entities/test_item_master.dart';
import 'package:kenviz/domain/entities/test_result.dart';
import 'package:kenviz/domain/repositories/repositories.dart';
import 'package:kenviz/presentation/pages/dashboard_page.dart';
import 'package:kenviz/presentation/providers/repository_providers.dart';

// --- Fakeリポジトリ ---

class _FakeCheckupRepository implements CheckupRepository {
  _FakeCheckupRepository({this.checkups = const []});

  final List<Checkup> checkups;

  @override
  Future<Checkup?> getLatestByProfileId(String profileId) async =>
      checkups.isNotEmpty ? checkups.first : null;

  @override
  Future<List<Checkup>> getByProfileId(String profileId) async => checkups;

  @override
  Future<Checkup?> getById(String id) async =>
      checkups.where((c) => c.id == id).firstOrNull;

  @override
  Future<void> save(Checkup checkup) async {}

  @override
  Future<void> delete(String id) async {}
}

class _FakeTestResultRepository implements TestResultRepository {
  _FakeTestResultRepository({this.results = const []});

  final List<TestResult> results;

  @override
  Future<List<TestResult>> getByCheckupId(String checkupId) async =>
      results.where((r) => r.checkupId == checkupId).toList();

  @override
  Future<List<TestResult>> getByItemCode({
    required String profileId,
    required String itemCode,
  }) async => results.where((r) => r.itemCode == itemCode).toList();

  @override
  Future<void> saveAll(List<TestResult> results) async {}

  @override
  Future<void> update(TestResult result) async {}

  @override
  Future<void> deleteByCheckupId(String checkupId) async {}
}

class _FakeTestItemMasterRepository implements TestItemMasterRepository {
  @override
  Future<List<TestItemMaster>> getAll() async => [];

  @override
  Future<List<TestItemMaster>> getByCategoryId(String categoryId) async => [];

  @override
  Future<TestItemMaster?> getById(String id) async => null;

  @override
  Future<List<TestCategory>> getAllCategories() async => [
    const TestCategory(
      id: 'bp',
      name: '血圧',
      displayOrder: 1,
      iconName: 'favorite',
    ),
  ];
}

void main() {
  group('DashboardPage', () {
    testWidgets('データなし時に空状態を表示', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            checkupRepositoryProvider.overrideWithValue(
              _FakeCheckupRepository(),
            ),
            testResultRepositoryProvider.overrideWithValue(
              _FakeTestResultRepository(),
            ),
            testItemMasterRepositoryProvider.overrideWithValue(
              _FakeTestItemMasterRepository(),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: DashboardPage())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('まだ健診データがありません'), findsOneWidget);
      expect(find.text('スキャン'), findsOneWidget);
    });

    testWidgets('データあり時にカテゴリカードを表示', (tester) async {
      final now = DateTime.now();
      final checkup = Checkup(
        id: 'c1',
        profileId: 'default',
        date: now,
        createdAt: now,
        updatedAt: now,
      );
      final results = [
        const TestResult(
          id: 'r1',
          checkupId: 'c1',
          itemCode: 'BP_SYS',
          itemName: '収縮期血圧',
          value: 120,
          unit: 'mmHg',
          refLow: 90,
          refHigh: 139,
        ),
        const TestResult(
          id: 'r2',
          checkupId: 'c1',
          itemCode: 'BP_DIA',
          itemName: '拡張期血圧',
          value: 80,
          unit: 'mmHg',
          refLow: 50,
          refHigh: 89,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            checkupRepositoryProvider.overrideWithValue(
              _FakeCheckupRepository(checkups: [checkup]),
            ),
            testResultRepositoryProvider.overrideWithValue(
              _FakeTestResultRepository(results: results),
            ),
            testItemMasterRepositoryProvider.overrideWithValue(
              _FakeTestItemMasterRepository(),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: DashboardPage())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('血圧'), findsOneWidget);
      expect(find.text('収縮期血圧'), findsOneWidget);
      expect(find.text('拡張期血圧'), findsOneWidget);
    });
  });
}
