// Repository プロバイダ
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kenviz/domain/repositories/repositories.dart';
import 'package:kenviz/infrastructure/datasources/drift/app_database.dart';
import 'package:kenviz/infrastructure/repositories/drift_checkup_repository.dart';
import 'package:kenviz/infrastructure/repositories/drift_profile_repository.dart';
import 'package:kenviz/infrastructure/repositories/drift_test_item_master_repository.dart';
import 'package:kenviz/infrastructure/repositories/drift_test_result_repository.dart';

/// AppDatabase プロバイダ（main.dart で override する）
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('appDatabaseProvider must be overridden');
});

/// ProfileRepository プロバイダ
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return DriftProfileRepository(ref.watch(appDatabaseProvider));
});

/// CheckupRepository プロバイダ
final checkupRepositoryProvider = Provider<CheckupRepository>((ref) {
  return DriftCheckupRepository(ref.watch(appDatabaseProvider));
});

/// TestResultRepository プロバイダ
final testResultRepositoryProvider = Provider<TestResultRepository>((ref) {
  return DriftTestResultRepository(ref.watch(appDatabaseProvider));
});

/// TestItemMasterRepository プロバイダ
final testItemMasterRepositoryProvider = Provider<TestItemMasterRepository>((
  ref,
) {
  return DriftTestItemMasterRepository(ref.watch(appDatabaseProvider));
});
