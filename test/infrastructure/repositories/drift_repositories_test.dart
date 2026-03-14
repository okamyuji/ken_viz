import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kenviz/domain/entities/checkup.dart';
import 'package:kenviz/domain/entities/profile.dart';
import 'package:kenviz/domain/entities/test_result.dart';
import 'package:kenviz/infrastructure/datasources/drift/app_database.dart'
    hide Checkup, Profile, TestCategory, TestItemMaster, TestResult;
import 'package:kenviz/infrastructure/repositories/drift_checkup_repository.dart';
import 'package:kenviz/infrastructure/repositories/drift_profile_repository.dart';
import 'package:kenviz/infrastructure/repositories/drift_test_item_master_repository.dart';
import 'package:kenviz/infrastructure/repositories/drift_test_result_repository.dart';

void main() {
  late AppDatabase db;
  late DriftProfileRepository profileRepo;
  late DriftCheckupRepository checkupRepo;
  late DriftTestResultRepository testResultRepo;
  late DriftTestItemMasterRepository masterRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    profileRepo = DriftProfileRepository(db);
    checkupRepo = DriftCheckupRepository(db);
    testResultRepo = DriftTestResultRepository(db);
    masterRepo = DriftTestItemMasterRepository(db);
  });

  tearDown(() => db.close());

  group('DriftProfileRepository', () {
    final now = DateTime.now();
    final profile = Profile(
      id: 'p1',
      name: 'テスト太郎',
      birthDate: DateTime(1990, 1, 15),
      sex: Sex.male,
      createdAt: now,
      updatedAt: now,
    );

    test('save & getById', () async {
      await profileRepo.save(profile);
      final result = await profileRepo.getById('p1');

      expect(result, isNotNull);
      expect(result!.id, 'p1');
      expect(result.name, 'テスト太郎');
      expect(result.sex, Sex.male);
    });

    test('getDefault は最初のプロフィールを返す', () async {
      await profileRepo.save(profile);
      final result = await profileRepo.getDefault();
      expect(result, isNotNull);
      expect(result!.id, 'p1');
    });

    test('getAll', () async {
      await profileRepo.save(profile);
      final profile2 = Profile(
        id: 'p2',
        name: 'テスト花子',
        createdAt: now,
        updatedAt: now,
      );
      await profileRepo.save(profile2);

      final all = await profileRepo.getAll();
      expect(all.length, 2);
    });

    test('delete', () async {
      await profileRepo.save(profile);
      await profileRepo.delete('p1');
      final result = await profileRepo.getById('p1');
      expect(result, isNull);
    });

    test('save で upsert される', () async {
      await profileRepo.save(profile);
      final updated = profile.copyWith(name: '更新太郎');
      await profileRepo.save(updated);

      final result = await profileRepo.getById('p1');
      expect(result!.name, '更新太郎');

      final all = await profileRepo.getAll();
      expect(all.length, 1);
    });
  });

  group('DriftCheckupRepository', () {
    final now = DateTime.now();

    setUp(() async {
      // 先にプロフィールを作成（外部キー制約）
      await profileRepo.save(
        Profile(id: 'p1', name: 'テスト太郎', createdAt: now, updatedAt: now),
      );
    });

    test('save & getById', () async {
      final checkup = Checkup(
        id: 'c1',
        profileId: 'p1',
        date: DateTime(2025, 10, 15),
        facilityName: '○○クリニック',
        createdAt: now,
        updatedAt: now,
      );
      await checkupRepo.save(checkup);

      final result = await checkupRepo.getById('c1');
      expect(result, isNotNull);
      expect(result!.facilityName, '○○クリニック');
    });

    test('getByProfileId は日付降順', () async {
      await checkupRepo.save(
        Checkup(
          id: 'c1',
          profileId: 'p1',
          date: DateTime(2024, 4),
          createdAt: now,
          updatedAt: now,
        ),
      );
      await checkupRepo.save(
        Checkup(
          id: 'c2',
          profileId: 'p1',
          date: DateTime(2025, 10, 15),
          createdAt: now,
          updatedAt: now,
        ),
      );

      final results = await checkupRepo.getByProfileId('p1');
      expect(results.length, 2);
      expect(results[0].id, 'c2'); // 新しい方が先
    });

    test('getLatestByProfileId', () async {
      await checkupRepo.save(
        Checkup(
          id: 'c1',
          profileId: 'p1',
          date: DateTime(2024, 4),
          createdAt: now,
          updatedAt: now,
        ),
      );
      await checkupRepo.save(
        Checkup(
          id: 'c2',
          profileId: 'p1',
          date: DateTime(2025, 10, 15),
          createdAt: now,
          updatedAt: now,
        ),
      );

      final latest = await checkupRepo.getLatestByProfileId('p1');
      expect(latest, isNotNull);
      expect(latest!.id, 'c2');
    });

    test('delete', () async {
      await checkupRepo.save(
        Checkup(
          id: 'c1',
          profileId: 'p1',
          date: DateTime(2025, 10, 15),
          createdAt: now,
          updatedAt: now,
        ),
      );
      await checkupRepo.delete('c1');
      final result = await checkupRepo.getById('c1');
      expect(result, isNull);
    });
  });

  group('DriftTestResultRepository', () {
    final now = DateTime.now();

    setUp(() async {
      await profileRepo.save(
        Profile(id: 'p1', name: 'テスト太郎', createdAt: now, updatedAt: now),
      );
      await checkupRepo.save(
        Checkup(
          id: 'c1',
          profileId: 'p1',
          date: DateTime(2025, 10, 15),
          createdAt: now,
          updatedAt: now,
        ),
      );
    });

    test('saveAll & getByCheckupId', () async {
      final results = [
        const TestResult(
          id: 'r1',
          checkupId: 'c1',
          itemCode: 'BMI',
          itemName: 'BMI',
          value: 22.4,
          refLow: 18.5,
          refHigh: 24.9,
        ),
        const TestResult(
          id: 'r2',
          checkupId: 'c1',
          itemCode: 'LDL_C',
          itemName: 'LDL-C',
          value: 142,
          unit: 'mg/dL',
          refLow: 70,
          refHigh: 139,
          flag: 'H',
        ),
      ];
      await testResultRepo.saveAll(results);

      final fetched = await testResultRepo.getByCheckupId('c1');
      expect(fetched.length, 2);
    });

    test('getByItemCode（トレンド取得）', () async {
      // 2つの健診にまたがるデータ
      await checkupRepo.save(
        Checkup(
          id: 'c2',
          profileId: 'p1',
          date: DateTime(2024, 4),
          createdAt: now,
          updatedAt: now,
        ),
      );

      await testResultRepo.saveAll([
        const TestResult(
          id: 'r1',
          checkupId: 'c1',
          itemCode: 'BMI',
          itemName: 'BMI',
          value: 22.4,
        ),
        const TestResult(
          id: 'r2',
          checkupId: 'c2',
          itemCode: 'BMI',
          itemName: 'BMI',
          value: 23.1,
        ),
      ]);

      final trend = await testResultRepo.getByItemCode(
        profileId: 'p1',
        itemCode: 'BMI',
      );
      expect(trend.length, 2);
      // 日付昇順
      expect(trend[0].value, 23.1); // c2: 2024-04
      expect(trend[1].value, 22.4); // c1: 2025-10
    });

    test('update', () async {
      await testResultRepo.saveAll([
        const TestResult(
          id: 'r1',
          checkupId: 'c1',
          itemCode: 'BMI',
          itemName: 'BMI',
          value: 22.4,
        ),
      ]);

      await testResultRepo.update(
        const TestResult(
          id: 'r1',
          checkupId: 'c1',
          itemCode: 'BMI',
          itemName: 'BMI',
          value: 23.0,
          isManuallyEdited: true,
        ),
      );

      final fetched = await testResultRepo.getByCheckupId('c1');
      expect(fetched[0].value, 23.0);
      expect(fetched[0].isManuallyEdited, true);
    });

    test('deleteByCheckupId', () async {
      await testResultRepo.saveAll([
        const TestResult(
          id: 'r1',
          checkupId: 'c1',
          itemCode: 'BMI',
          itemName: 'BMI',
          value: 22.4,
        ),
      ]);

      await testResultRepo.deleteByCheckupId('c1');
      final fetched = await testResultRepo.getByCheckupId('c1');
      expect(fetched, isEmpty);
    });
  });

  group('DriftTestItemMasterRepository', () {
    test('マスタデータ投入と取得', () async {
      // マスタデータをシード
      await _seedTestMasterData(db);

      final all = await masterRepo.getAll();
      expect(all.length, 28);
    });

    test('カテゴリ取得', () async {
      await _seedTestMasterData(db);

      final categories = await masterRepo.getAllCategories();
      expect(categories.length, 8);
      expect(categories[0].name, '身体計測');
    });

    test('カテゴリIDで検査項目を絞り込み', () async {
      await _seedTestMasterData(db);

      final lipidItems = await masterRepo.getByCategoryId('lipid');
      expect(lipidItems.length, 4);
      expect(lipidItems[0].id, 'LDL_C');
    });

    test('IDで検査項目を取得', () async {
      await _seedTestMasterData(db);

      final item = await masterRepo.getById('BMI');
      expect(item, isNotNull);
      expect(item!.standardName, 'BMI');
      expect(item.aliases, contains('体格指数'));
    });

    test('存在しないIDはnull', () async {
      await _seedTestMasterData(db);

      final item = await masterRepo.getById('NONEXISTENT');
      expect(item, isNull);
    });
  });
}

/// テスト用マスタデータ投入
Future<void> _seedTestMasterData(AppDatabase db) async {
  // database_provider.dart の _seedMasterData と同等だが、
  // テスト用にインポートなしで直接投入
  final categories = [
    ('body', '身体計測', 1, 'straighten'),
    ('bp', '血圧', 2, 'favorite'),
    ('blood', '血液一般', 3, 'water_drop'),
    ('lipid', '脂質', 4, 'science'),
    ('sugar', '糖代謝', 5, 'cookie'),
    ('liver', '肝機能', 6, 'local_hospital'),
    ('kidney', '腎機能', 7, 'water'),
    ('urine', '尿検査', 8, 'biotech'),
  ];

  for (final (id, name, order, icon) in categories) {
    await db
        .into(db.testCategories)
        .insert(
          TestCategoriesCompanion.insert(
            id: id,
            name: name,
            displayOrder: order,
            iconName: Value(icon),
          ),
        );
  }

  // defaultTestItems から投入
  final items = [
    ('HEIGHT', 'body', '身長', '身長(cm)', 'cm', null, null, 1),
    ('WEIGHT', 'body', '体重', '体重(kg)', 'kg', null, null, 2),
    ('BMI', 'body', 'BMI', 'BMI,体格指数', null, 18.5, 24.9, 3),
    ('WAIST', 'body', '腹囲', '腹囲(cm),ウエスト', 'cm', null, null, 4),
    ('BP_SYS', 'bp', '収縮期血圧', '最高血圧,血圧(上)', 'mmHg', null, 129.0, 1),
    ('BP_DIA', 'bp', '拡張期血圧', '最低血圧,血圧(下)', 'mmHg', null, 84.0, 2),
    ('RBC', 'blood', '赤血球', '赤血球数,RBC', '万/μL', 400.0, 539.0, 1),
    ('WBC', 'blood', '白血球', '白血球数,WBC', '/μL', 3500.0, 9000.0, 2),
    ('HB', 'blood', 'ヘモグロビン', 'Hb,Hgb,血色素量', 'g/dL', 13.0, 17.0, 3),
    ('HCT', 'blood', 'ヘマトクリット', 'Ht,Hct', '%', 39.0, 52.0, 4),
    ('PLT', 'blood', '血小板', '血小板数,PLT', '万/μL', 15.0, 35.0, 5),
    (
      'LDL_C',
      'lipid',
      'LDL-コレステロール',
      'LDL-C,LDLコレステロール',
      'mg/dL',
      70.0,
      139.0,
      1,
    ),
    (
      'HDL_C',
      'lipid',
      'HDL-コレステロール',
      'HDL-C,HDLコレステロール',
      'mg/dL',
      40.0,
      null,
      2,
    ),
    ('TG', 'lipid', '中性脂肪', 'TG,トリグリセリド', 'mg/dL', 30.0, 149.0, 3),
    ('TC', 'lipid', '総コレステロール', 'T-Cho,TC', 'mg/dL', 150.0, 219.0, 4),
    ('FPG', 'sugar', '空腹時血糖', 'FPG,血糖,FBS', 'mg/dL', 70.0, 99.0, 1),
    ('HBA1C', 'sugar', 'HbA1c', 'HbA1c(NGSP),ヘモグロビンA1c', '%', 4.6, 5.9, 2),
    ('AST', 'liver', 'AST', 'AST(GOT),GOT', 'U/L', 10.0, 30.0, 1),
    ('ALT', 'liver', 'ALT', 'ALT(GPT),GPT', 'U/L', 6.0, 30.0, 2),
    ('GGT', 'liver', 'γ-GTP', 'γGTP,ガンマGTP', 'U/L', null, 50.0, 3),
    ('ALP', 'liver', 'ALP', 'ALP,アルカリフォスファターゼ', 'U/L', 38.0, 113.0, 4),
    ('CRE', 'kidney', 'クレアチニン', 'Cr,CRE,Cre', 'mg/dL', 0.6, 1.1, 1),
    ('EGFR', 'kidney', 'eGFR', '推算GFR,eGFR', 'mL/min/1.73m2', 60.0, null, 2),
    ('BUN', 'kidney', 'BUN', '尿素窒素,UN', 'mg/dL', 8.0, 20.0, 3),
    ('UA', 'kidney', '尿酸', 'UA,尿酸(UA)', 'mg/dL', 2.1, 7.0, 4),
    ('U_GLU', 'urine', '尿糖', '尿糖(定性)', null, null, null, 1),
    ('U_PRO', 'urine', '尿蛋白', '尿蛋白(定性),尿たんぱく', null, null, null, 2),
    ('U_OB', 'urine', '尿潜血', '尿潜血(定性)', null, null, null, 3),
  ];

  for (final (id, catId, name, aliases, unit, refLow, refHigh, order)
      in items) {
    await db
        .into(db.testItemMasters)
        .insert(
          TestItemMastersCompanion.insert(
            id: id,
            categoryId: catId,
            standardName: name,
            aliases: Value(aliases),
            unit: Value(unit),
            defaultRefLow: Value(refLow),
            defaultRefHigh: Value(refHigh),
            displayOrder: Value(order),
          ),
        );
  }
}
