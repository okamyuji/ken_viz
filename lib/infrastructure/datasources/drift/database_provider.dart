// DB初期化 + マスタデータ投入
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:kenviz/core/constants/test_item_defaults.dart';
import 'package:kenviz/infrastructure/datasources/drift/app_database.dart';
import 'package:path_provider/path_provider.dart';

/// 本番用 DB インスタンスを生成
Future<AppDatabase> openDatabase() async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/kenviz.sqlite');
  final db = AppDatabase(NativeDatabase.createInBackground(file));
  await _seedMasterData(db);
  return db;
}

/// マスタデータ初期投入（カテゴリ・検査項目）
Future<void> _seedMasterData(AppDatabase db) async {
  final existingCategories = await db.select(db.testCategories).get();
  if (existingCategories.isNotEmpty) return;

  await db.batch((batch) {
    // カテゴリ投入
    batch.insertAll(
      db.testCategories,
      defaultCategories
          .map(
            (c) => TestCategoriesCompanion.insert(
              id: c.id,
              name: c.name,
              displayOrder: c.displayOrder,
              iconName: Value(c.iconName),
            ),
          )
          .toList(),
    );
  });

  await db.batch((batch) {
    // 検査項目投入
    batch.insertAll(
      db.testItemMasters,
      defaultTestItems
          .map(
            (item) => TestItemMastersCompanion.insert(
              id: item.id,
              categoryId: item.categoryId,
              standardName: item.standardName,
              aliases: Value(item.aliases.join(',')),
              unit: Value(item.unit),
              defaultRefLow: Value(item.defaultRefLow),
              defaultRefHigh: Value(item.defaultRefHigh),
              displayOrder: Value(item.displayOrder),
            ),
          )
          .toList(),
    );
  });
}
