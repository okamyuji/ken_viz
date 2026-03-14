// CheckupRepository の Drift 実装
import 'package:drift/drift.dart';
import 'package:kenviz/domain/entities/checkup.dart' as domain;
import 'package:kenviz/domain/repositories/repositories.dart';
import 'package:kenviz/infrastructure/datasources/drift/app_database.dart';

/// [DE-02] Checkup の永続化
class DriftCheckupRepository implements CheckupRepository {
  DriftCheckupRepository(this._db);

  final AppDatabase _db;

  @override
  Future<domain.Checkup?> getById(String id) async {
    final row = await (_db.select(
      _db.checkups,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<List<domain.Checkup>> getByProfileId(String profileId) async {
    final rows =
        await (_db.select(_db.checkups)
              ..where((t) => t.profileId.equals(profileId))
              ..orderBy([(t) => OrderingTerm.desc(t.date)]))
            .get();
    return rows.map(_toEntity).toList();
  }

  @override
  Future<domain.Checkup?> getLatestByProfileId(String profileId) async {
    final row =
        await (_db.select(_db.checkups)
              ..where((t) => t.profileId.equals(profileId))
              ..orderBy([(t) => OrderingTerm.desc(t.date)])
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<void> save(domain.Checkup checkup) async {
    await _db
        .into(_db.checkups)
        .insertOnConflictUpdate(
          CheckupsCompanion.insert(
            id: checkup.id,
            profileId: checkup.profileId,
            date: checkup.date,
            facilityName: Value(checkup.facilityName),
            sourceImagePath: Value(checkup.sourceImagePath),
            memo: Value(checkup.memo),
            createdAt: checkup.createdAt,
            updatedAt: checkup.updatedAt,
          ),
        );
  }

  @override
  Future<void> delete(String id) async {
    await (_db.delete(_db.checkups)..where((t) => t.id.equals(id))).go();
  }

  domain.Checkup _toEntity(Checkup row) {
    return domain.Checkup(
      id: row.id,
      profileId: row.profileId,
      date: row.date,
      facilityName: row.facilityName,
      sourceImagePath: row.sourceImagePath,
      memo: row.memo,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
