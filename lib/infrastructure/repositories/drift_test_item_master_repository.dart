// TestItemMasterRepository の Drift 実装
import 'package:drift/drift.dart';
import 'package:kenviz/domain/entities/test_item_master.dart' as domain;
import 'package:kenviz/domain/repositories/repositories.dart';
import 'package:kenviz/infrastructure/datasources/drift/app_database.dart';

/// [DE-04][DE-05] TestCategory + TestItemMaster の永続化
class DriftTestItemMasterRepository implements TestItemMasterRepository {
  DriftTestItemMasterRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<domain.TestItemMaster>> getAll() async {
    final rows = await (_db.select(
      _db.testItemMasters,
    )..orderBy([(t) => OrderingTerm.asc(t.displayOrder)])).get();
    return rows.map(_toEntity).toList();
  }

  @override
  Future<List<domain.TestItemMaster>> getByCategoryId(String categoryId) async {
    final rows =
        await (_db.select(_db.testItemMasters)
              ..where((t) => t.categoryId.equals(categoryId))
              ..orderBy([(t) => OrderingTerm.asc(t.displayOrder)]))
            .get();
    return rows.map(_toEntity).toList();
  }

  @override
  Future<domain.TestItemMaster?> getById(String id) async {
    final row = await (_db.select(
      _db.testItemMasters,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<List<domain.TestCategory>> getAllCategories() async {
    final rows = await (_db.select(
      _db.testCategories,
    )..orderBy([(t) => OrderingTerm.asc(t.displayOrder)])).get();
    return rows
        .map(
          (row) => domain.TestCategory(
            id: row.id,
            name: row.name,
            displayOrder: row.displayOrder,
            iconName: row.iconName,
          ),
        )
        .toList();
  }

  domain.TestItemMaster _toEntity(TestItemMaster row) {
    return domain.TestItemMaster(
      id: row.id,
      categoryId: row.categoryId,
      standardName: row.standardName,
      aliases: row.aliases.isEmpty ? const [] : row.aliases.split(','),
      unit: row.unit,
      defaultRefLow: row.defaultRefLow,
      defaultRefHigh: row.defaultRefHigh,
      displayOrder: row.displayOrder,
    );
  }
}
