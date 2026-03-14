// トレンドチャート取得ユースケース [UC-06]
import 'package:kenviz/domain/entities/test_result.dart';
import 'package:kenviz/domain/repositories/repositories.dart';

/// 指定した検査項目の経時変化データを取得する
class GetTrendChartUseCase {
  GetTrendChartUseCase({required this.testResultRepository});

  final TestResultRepository testResultRepository;

  /// profileId + itemCode で過去の検査結果を取得
  Future<TrendChartData> execute({
    required String profileId,
    required String itemCode,
  }) async {
    final results = await testResultRepository.getByItemCode(
      profileId: profileId,
      itemCode: itemCode,
    );

    if (results.isEmpty) {
      return TrendChartData(itemCode: itemCode, points: []);
    }

    final first = results.first;
    return TrendChartData(
      itemCode: itemCode,
      itemName: first.itemName,
      unit: first.unit,
      refLow: first.refLow,
      refHigh: first.refHigh,
      points: results
          .where((r) => r.value != null)
          .map(
            (r) => TrendPoint(
              checkupId: r.checkupId,
              value: r.value!,
              judgment: r.judgment,
            ),
          )
          .toList(),
    );
  }
}

/// トレンドチャートデータ
class TrendChartData {
  const TrendChartData({
    required this.itemCode,
    this.itemName,
    this.unit,
    this.refLow,
    this.refHigh,
    required this.points,
  });

  final String itemCode;
  final String? itemName;
  final String? unit;
  final double? refLow;
  final double? refHigh;
  final List<TrendPoint> points;

  bool get isEmpty => points.isEmpty;
}

/// トレンドの1データポイント
class TrendPoint {
  const TrendPoint({
    required this.checkupId,
    required this.value,
    required this.judgment,
  });

  final String checkupId;
  final double value;
  final JudgmentFlag judgment;
}
