// KenViz Drift データベース定義
// [DE-01] Profile, [DE-02] Checkup, [DE-03] TestResult,
// [DE-04] TestCategory, [DE-05] TestItemMaster
import 'package:drift/drift.dart';

part 'app_database.g.dart';

// ── テーブル定義 ──

/// プロフィール [DE-01]
class Profiles extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get birthDate => dateTime().nullable()();
  TextColumn get sex => text().withDefault(const Constant('unspecified'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// 健診記録 [DE-02]
class Checkups extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  DateTimeColumn get date => dateTime()();
  TextColumn get facilityName => text().nullable()();
  TextColumn get sourceImagePath => text().nullable()();
  TextColumn get memo => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// 個別検査結果 [DE-03]
class TestResults extends Table {
  TextColumn get id => text()();
  TextColumn get checkupId => text().references(Checkups, #id)();
  TextColumn get itemCode => text()();
  TextColumn get itemName => text()();
  RealColumn get value => real().nullable()();
  TextColumn get valueText => text().nullable()();
  TextColumn get unit => text().nullable()();
  RealColumn get refLow => real().nullable()();
  RealColumn get refHigh => real().nullable()();
  TextColumn get flag => text().nullable()();
  RealColumn get confidence => real().withDefault(const Constant(1.0))();
  BoolColumn get isManuallyEdited =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// 検査カテゴリ [DE-04]
class TestCategories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get displayOrder => integer()();
  TextColumn get iconName => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// 検査項目マスタ [DE-05]
class TestItemMasters extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text().references(TestCategories, #id)();
  TextColumn get standardName => text()();
  TextColumn get aliases => text().withDefault(const Constant(''))();
  TextColumn get unit => text().nullable()();
  RealColumn get defaultRefLow => real().nullable()();
  RealColumn get defaultRefHigh => real().nullable()();
  IntColumn get displayOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [Profiles, Checkups, TestResults, TestCategories, TestItemMasters],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
