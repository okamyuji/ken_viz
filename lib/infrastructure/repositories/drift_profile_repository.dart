// ProfileRepository の Drift 実装
import 'package:drift/drift.dart';
import 'package:kenviz/domain/entities/profile.dart' as domain;
import 'package:kenviz/domain/repositories/repositories.dart';
import 'package:kenviz/infrastructure/datasources/drift/app_database.dart';

/// [DE-01] Profile の永続化
class DriftProfileRepository implements ProfileRepository {
  DriftProfileRepository(this._db);

  final AppDatabase _db;

  @override
  Future<domain.Profile?> getById(String id) async {
    final row = await (_db.select(
      _db.profiles,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<domain.Profile?> getDefault() async {
    final row = await (_db.select(_db.profiles)..limit(1)).getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<List<domain.Profile>> getAll() async {
    final rows = await _db.select(_db.profiles).get();
    return rows.map(_toEntity).toList();
  }

  @override
  Future<void> save(domain.Profile profile) async {
    await _db
        .into(_db.profiles)
        .insertOnConflictUpdate(
          ProfilesCompanion.insert(
            id: profile.id,
            name: profile.name,
            birthDate: Value(profile.birthDate),
            sex: Value(profile.sex.name),
            createdAt: profile.createdAt,
            updatedAt: profile.updatedAt,
          ),
        );
  }

  @override
  Future<void> delete(String id) async {
    await (_db.delete(_db.profiles)..where((t) => t.id.equals(id))).go();
  }

  domain.Profile _toEntity(Profile row) {
    return domain.Profile(
      id: row.id,
      name: row.name,
      birthDate: row.birthDate,
      sex: domain.Sex.values.firstWhere(
        (s) => s.name == row.sex,
        orElse: () => domain.Sex.unspecified,
      ),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
