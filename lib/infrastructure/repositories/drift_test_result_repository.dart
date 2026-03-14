// TestResultRepository の Drift 実装
import 'package:drift/drift.dart';
import 'package:kenviz/domain/entities/test_result.dart' as domain;
import 'package:kenviz/domain/repositories/repositories.dart';
import 'package:kenviz/infrastructure/datasources/drift/app_database.dart';

/// [DE-03] TestResult の永続化
class DriftTestResultRepository implements TestResultRepository {
  DriftTestResultRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<domain.TestResult>> getByCheckupId(String checkupId) async {
    final rows = await (_db.select(
      _db.testResults,
    )..where((t) => t.checkupId.equals(checkupId))).get();
    return rows.map(_toEntity).toList();
  }

  @override
  Future<List<domain.TestResult>> getByItemCode({
    required String profileId,
    required String itemCode,
  }) async {
    // checkups テーブルと JOIN して profileId で絞り込み
    final query =
        _db.select(_db.testResults).join([
            innerJoin(
              _db.checkups,
              _db.checkups.id.equalsExp(_db.testResults.checkupId),
            ),
          ])
          ..where(_db.checkups.profileId.equals(profileId))
          ..where(_db.testResults.itemCode.equals(itemCode))
          ..orderBy([OrderingTerm.asc(_db.checkups.date)]);

    final rows = await query.get();
    return rows
        .map((row) => _toEntity(row.readTable(_db.testResults)))
        .toList();
  }

  @override
  Future<void> saveAll(List<domain.TestResult> results) async {
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _db.testResults,
        results.map(_toCompanion).toList(),
      );
    });
  }

  @override
  Future<void> update(domain.TestResult result) async {
    await _db
        .into(_db.testResults)
        .insertOnConflictUpdate(_toCompanion(result));
  }

  @override
  Future<void> deleteByCheckupId(String checkupId) async {
    await (_db.delete(
      _db.testResults,
    )..where((t) => t.checkupId.equals(checkupId))).go();
  }

  TestResultsCompanion _toCompanion(domain.TestResult r) {
    return TestResultsCompanion.insert(
      id: r.id,
      checkupId: r.checkupId,
      itemCode: r.itemCode,
      itemName: r.itemName,
      value: Value(r.value),
      valueText: Value(r.valueText),
      unit: Value(r.unit),
      refLow: Value(r.refLow),
      refHigh: Value(r.refHigh),
      flag: Value(r.flag),
      confidence: Value(r.confidence),
      isManuallyEdited: Value(r.isManuallyEdited),
    );
  }

  domain.TestResult _toEntity(TestResult row) {
    return domain.TestResult(
      id: row.id,
      checkupId: row.checkupId,
      itemCode: row.itemCode,
      itemName: row.itemName,
      value: row.value,
      valueText: row.valueText,
      unit: row.unit,
      refLow: row.refLow,
      refHigh: row.refHigh,
      flag: row.flag,
      confidence: row.confidence,
      isManuallyEdited: row.isManuallyEdited,
    );
  }
}
