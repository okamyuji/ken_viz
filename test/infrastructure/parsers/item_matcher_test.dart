import 'package:flutter_test/flutter_test.dart';
import 'package:kenviz/core/constants/test_item_defaults.dart';
import 'package:kenviz/infrastructure/parsers/item_matcher.dart';

void main() {
  late ItemMatcher matcher;

  setUp(() {
    matcher = ItemMatcher(defaultTestItems);
  });

  group('ItemMatcher', () {
    group('Phase 1: 完全一致', () {
      test('standardNameで完全一致', () {
        final result = matcher.match('BMI');
        expect(result, isNotNull);
        expect(result!.item.id, 'BMI');
        expect(result.confidence, 1.0);
      });

      test('aliasで完全一致', () {
        final result = matcher.match('GOT');
        expect(result, isNotNull);
        expect(result!.item.id, 'AST');
        expect(result.confidence, 1.0);
      });

      test('LDL-C alias一致', () {
        final result = matcher.match('LDL-C');
        expect(result, isNotNull);
        expect(result!.item.id, 'LDL_C');
        expect(result.confidence, 1.0);
      });

      test('HbA1c一致', () {
        final result = matcher.match('HbA1c');
        expect(result, isNotNull);
        expect(result!.item.id, 'HBA1C');
        expect(result.confidence, 1.0);
      });
    });

    group('Phase 2: 正規化後一致', () {
      test('全角英数字', () {
        final result = matcher.match('ＢＭＩ');
        expect(result, isNotNull);
        expect(result!.item.id, 'BMI');
        expect(result.confidence, 0.95);
      });

      test('全角括弧付き', () {
        final result = matcher.match('ＡＳＴ（ＧＯＴ）');
        expect(result, isNotNull);
        expect(result!.item.id, 'AST');
        expect(result.confidence, 0.95);
      });

      test('スペースの有無の違い', () {
        final result = matcher.match('LDL コレステロール');
        expect(result, isNotNull);
        expect(result!.item.id, 'LDL_C');
        expect(result.confidence, 0.95);
      });
    });

    group('Phase 3: ファジーマッチ', () {
      test('ガンマGTP → γ-GTP', () {
        final result = matcher.match('ガンマGTP');
        expect(result, isNotNull);
        expect(result!.item.id, 'GGT');
        // ガンマ→γ変換は normalizeItemName で処理されるので Phase 2
        expect(result.confidence, greaterThanOrEqualTo(0.9));
      });

      test('悪玉コレステロール → LDL-C', () {
        final result = matcher.match('悪玉コレステロール');
        expect(result, isNotNull);
        expect(result!.item.id, 'LDL_C');
      });

      test('善玉コレステロール → HDL-C', () {
        final result = matcher.match('善玉コレステロール');
        expect(result, isNotNull);
        expect(result!.item.id, 'HDL_C');
      });
    });

    group('マッチ失敗', () {
      test('空文字列', () {
        expect(matcher.match(''), isNull);
      });

      test('全く無関係な文字列', () {
        final result = matcher.match('受診日');
        // マッチしないか、信頼度が非常に低い
        if (result != null) {
          expect(result.confidence, lessThan(0.7));
        }
      });
    });

    group('表記揺れカバレッジ', () {
      final testCases = {
        '最高血圧': 'BP_SYS',
        '血圧(上)': 'BP_SYS',
        '最低血圧': 'BP_DIA',
        'ヘモグロビン': 'HB',
        'Hb': 'HB',
        '血色素量': 'HB',
        '中性脂肪': 'TG',
        'トリグリセリド': 'TG',
        '空腹時血糖': 'FPG',
        'FBS': 'FPG',
        'クレアチニン': 'CRE',
        'eGFR': 'EGFR',
        '尿素窒素': 'BUN',
        '尿酸': 'UA',
      };

      for (final entry in testCases.entries) {
        test('${entry.key} → ${entry.value}', () {
          final result = matcher.match(entry.key);
          expect(result, isNotNull, reason: '${entry.key} がマッチしない');
          expect(result!.item.id, entry.value);
        });
      }
    });
  });
}
