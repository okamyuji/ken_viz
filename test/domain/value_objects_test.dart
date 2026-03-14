import 'package:flutter_test/flutter_test.dart';
import 'package:kenviz/domain/entities/test_result.dart';
import 'package:kenviz/domain/value_objects/value_objects.dart';

void main() {
  group('ReferenceRange', () {
    test('正常範囲内の判定', () {
      const range = ReferenceRange(low: 70, high: 139);
      expect(range.judge(100), JudgmentFlag.normal);
    });

    test('高値の判定', () {
      const range = ReferenceRange(low: 70, high: 139);
      expect(range.judge(142), JudgmentFlag.high);
    });

    test('低値の判定', () {
      const range = ReferenceRange(low: 70, high: 139);
      expect(range.judge(60), JudgmentFlag.low);
    });

    test('上限のみの基準値', () {
      const range = ReferenceRange(high: 129);
      expect(range.judge(128), JudgmentFlag.normal);
      expect(range.judge(130), JudgmentFlag.high);
    });

    test('下限のみの基準値', () {
      const range = ReferenceRange(low: 40);
      expect(range.judge(55), JudgmentFlag.normal);
      expect(range.judge(35), JudgmentFlag.low);
    });

    test('境界値: ちょうど上限', () {
      const range = ReferenceRange(low: 70, high: 139);
      // 上限ぴったりは正常 (> で判定)
      expect(range.judge(139), JudgmentFlag.normal);
    });

    test('境界値: 上限を超える', () {
      const range = ReferenceRange(low: 70, high: 139);
      expect(range.judge(139.1), JudgmentFlag.high);
    });

    group('isNearBoundary', () {
      test('上限境界付近', () {
        const range = ReferenceRange(low: 70, high: 139);
        // 139の10% = 13.9 → 125.1以上139以下が境界付近
        expect(range.isNearBoundary(135), true);
        expect(range.isNearBoundary(100), false);
      });

      test('下限境界付近', () {
        const range = ReferenceRange(low: 70, high: 139);
        // 70の10% = 7 → 70以上77以下が境界付近
        expect(range.isNearBoundary(72), true);
        expect(range.isNearBoundary(100), false);
      });
    });

    group('midpoint', () {
      test('両方ある場合', () {
        const range = ReferenceRange(low: 70, high: 139);
        expect(range.midpoint, 104.5);
      });

      test('片方のみ', () {
        const range = ReferenceRange(high: 139);
        expect(range.midpoint, isNull);
      });
    });

    group('toString', () {
      test('両方ある場合', () {
        const range = ReferenceRange(low: 70.0, high: 139.0);
        expect(range.toString(), '70.0〜139.0');
      });

      test('上限のみ', () {
        const range = ReferenceRange(high: 129.0);
        expect(range.toString(), '129.0以下');
      });

      test('下限のみ', () {
        const range = ReferenceRange(low: 40.0);
        expect(range.toString(), '40.0以上');
      });
    });
  });

  group('ConfidenceScore', () {
    test('高信頼度', () {
      const score = ConfidenceScore(0.95);
      expect(score.level, ConfidenceLevel.high);
      expect(score.needsUserConfirmation, false);
    });

    test('中信頼度', () {
      const score = ConfidenceScore(0.8);
      expect(score.level, ConfidenceLevel.medium);
      expect(score.needsUserConfirmation, false);
    });

    test('低信頼度', () {
      const score = ConfidenceScore(0.5);
      expect(score.level, ConfidenceLevel.low);
      expect(score.needsUserConfirmation, true);
    });

    test('境界値: 0.7', () {
      const score = ConfidenceScore(0.7);
      expect(score.level, ConfidenceLevel.medium);
      expect(score.needsUserConfirmation, false);
    });

    test('toString', () {
      const score = ConfidenceScore(0.85);
      expect(score.toString(), '85%');
    });
  });

  group('TestResult', () {
    test('定量検査の判定', () {
      const result = TestResult(
        id: '1',
        checkupId: 'c1',
        itemCode: 'LDL_C',
        itemName: 'LDL-C',
        value: 142,
        unit: 'mg/dL',
        refLow: 70,
        refHigh: 139,
      );

      expect(result.isQuantitative, true);
      expect(result.isQualitative, false);
      expect(result.judgment, JudgmentFlag.high);
    });

    test('定性検査', () {
      const result = TestResult(
        id: '2',
        checkupId: 'c1',
        itemCode: 'U_GLU',
        itemName: '尿糖',
        valueText: '陰性(-)',
      );

      expect(result.isQuantitative, false);
      expect(result.isQualitative, true);
      expect(result.judgment, JudgmentFlag.unknown);
    });

    test('正常値の判定', () {
      const result = TestResult(
        id: '3',
        checkupId: 'c1',
        itemCode: 'BMI',
        itemName: 'BMI',
        value: 22.4,
        refLow: 18.5,
        refHigh: 24.9,
      );

      expect(result.judgment, JudgmentFlag.normal);
    });

    test('信頼度による確認必要判定', () {
      const highConf = TestResult(
        id: '4',
        checkupId: 'c1',
        itemCode: 'BMI',
        itemName: 'BMI',
        value: 22.4,
        confidence: 0.95,
      );
      expect(highConf.needsConfirmation, false);

      const lowConf = TestResult(
        id: '5',
        checkupId: 'c1',
        itemCode: 'BMI',
        itemName: 'BMI',
        value: 22.4,
        confidence: 0.5,
      );
      expect(lowConf.needsConfirmation, true);
    });
  });
}
