import 'package:kenviz/domain/entities/checkup.dart';
import 'package:kenviz/domain/entities/profile.dart';
import 'package:kenviz/domain/entities/test_item_master.dart';
import 'package:kenviz/domain/entities/test_result.dart';

/// プロフィールリポジトリ
abstract class ProfileRepository {
  Future<Profile?> getById(String id);
  Future<Profile?> getDefault();
  Future<List<Profile>> getAll();
  Future<void> save(Profile profile);
  Future<void> delete(String id);
}

/// 健診記録リポジトリ
abstract class CheckupRepository {
  Future<Checkup?> getById(String id);
  Future<List<Checkup>> getByProfileId(String profileId);
  Future<Checkup?> getLatestByProfileId(String profileId);
  Future<void> save(Checkup checkup);
  Future<void> delete(String id);
}

/// 検査結果リポジトリ
abstract class TestResultRepository {
  Future<List<TestResult>> getByCheckupId(String checkupId);
  Future<List<TestResult>> getByItemCode({
    required String profileId,
    required String itemCode,
  });
  Future<void> saveAll(List<TestResult> results);
  Future<void> update(TestResult result);
  Future<void> deleteByCheckupId(String checkupId);
}

/// 検査項目マスタリポジトリ
abstract class TestItemMasterRepository {
  Future<List<TestItemMaster>> getAll();
  Future<List<TestItemMaster>> getByCategoryId(String categoryId);
  Future<TestItemMaster?> getById(String id);
  Future<List<TestCategory>> getAllCategories();
}
