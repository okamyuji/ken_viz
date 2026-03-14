import 'package:flutter_test/flutter_test.dart';
import 'package:kenviz/core/utils/text_normalizer.dart';

void main() {
  group('TextNormalizer', () {
    group('toHalfWidth', () {
      test('全角数字を半角に変換', () {
        expect(TextNormalizer.toHalfWidth('１２３．４'), '123.4');
      });

      test('全角英字を半角に変換', () {
        expect(TextNormalizer.toHalfWidth('ＡＳＴ'), 'AST');
      });

      test('全角スペースを半角に変換', () {
        expect(TextNormalizer.toHalfWidth('身長　170'), '身長 170');
      });

      test('混在テキストの変換', () {
        expect(TextNormalizer.toHalfWidth('ＬＤＬ−Ｃ　１４２'), 'LDL-C 142');
      });

      test('半角はそのまま', () {
        expect(TextNormalizer.toHalfWidth('AST 30'), 'AST 30');
      });
    });

    group('normalize', () {
      test('全角→半角+スペース圧縮+トリム', () {
        expect(TextNormalizer.normalize('  ＡＳＴ　　３０  '), 'AST 30');
      });
    });

    group('normalizeItemName', () {
      test('括弧の正規化', () {
        expect(TextNormalizer.normalizeItemName('ＡＳＴ（ＧＯＴ）'), 'ast(got)');
      });

      test('ガンマの表記揺れ統一', () {
        expect(TextNormalizer.normalizeItemName('ガンマGTP'), 'γgtp');
      });

      test('スペース除去', () {
        expect(TextNormalizer.normalizeItemName('LDL コレステロール'), 'ldlコレステロール');
      });
    });

    group('extractNumber', () {
      test('整数', () {
        expect(TextNormalizer.extractNumber('142'), 142.0);
      });

      test('小数', () {
        expect(TextNormalizer.extractNumber('5.6'), 5.6);
      });

      test('全角数字', () {
        expect(TextNormalizer.extractNumber('１４２'), 142.0);
      });

      test('前後に文字がある場合', () {
        expect(TextNormalizer.extractNumber('<30'), 30.0);
      });

      test('数値なし', () {
        expect(TextNormalizer.extractNumber('陰性'), null);
      });
    });

    group('extractRange', () {
      test('標準パターン: 70〜139', () {
        final result = TextNormalizer.extractRange('70〜139');
        expect(result, isNotNull);
        expect(result!.low, 70.0);
        expect(result.high, 139.0);
      });

      test('ハイフンパターン: 70-139', () {
        final result = TextNormalizer.extractRange('70-139');
        expect(result, isNotNull);
        expect(result!.low, 70.0);
        expect(result.high, 139.0);
      });

      test('チルダパターン: 70 ~ 139', () {
        final result = TextNormalizer.extractRange('70 ~ 139');
        expect(result, isNotNull);
        expect(result!.low, 70.0);
        expect(result.high, 139.0);
      });

      test('小数: 4.6〜5.9', () {
        final result = TextNormalizer.extractRange('4.6〜5.9');
        expect(result, isNotNull);
        expect(result!.low, 4.6);
        expect(result.high, 5.9);
      });

      test('全角数字: ７０〜１３９', () {
        final result = TextNormalizer.extractRange('７０〜１３９');
        expect(result, isNotNull);
        expect(result!.low, 70.0);
        expect(result.high, 139.0);
      });

      test('パターンなし', () {
        expect(TextNormalizer.extractRange('正常'), null);
      });
    });

    group('extractUnit', () {
      test('mg/dL', () {
        expect(TextNormalizer.extractUnit('142 mg/dL'), 'mg/dL');
      });

      test('U/L', () {
        expect(TextNormalizer.extractUnit('30 U/L'), 'U/L');
      });

      test('mmHg', () {
        expect(TextNormalizer.extractUnit('128mmHg'), 'mmHg');
      });

      test('%', () {
        expect(TextNormalizer.extractUnit('5.6%'), '%');
      });

      test('単位なし', () {
        expect(TextNormalizer.extractUnit('142'), null);
      });
    });

    group('extractFlag', () {
      test('Hフラグ', () {
        expect(TextNormalizer.extractFlag('H'), 'H');
      });

      test('Lフラグ', () {
        expect(TextNormalizer.extractFlag('L'), 'L');
      });

      test('A判定', () {
        expect(TextNormalizer.extractFlag('A'), 'A');
      });

      test('D1判定', () {
        expect(TextNormalizer.extractFlag('D1'), 'D1');
      });

      test('フラグなし', () {
        expect(TextNormalizer.extractFlag('142'), null);
      });
    });

    group('levenshteinDistance', () {
      test('同一文字列', () {
        expect(TextNormalizer.levenshteinDistance('abc', 'abc'), 0);
      });

      test('1文字挿入', () {
        expect(TextNormalizer.levenshteinDistance('abc', 'abcd'), 1);
      });

      test('1文字置換', () {
        expect(TextNormalizer.levenshteinDistance('abc', 'aXc'), 1);
      });

      test('空文字列', () {
        expect(TextNormalizer.levenshteinDistance('', 'abc'), 3);
      });
    });

    group('similarityScore', () {
      test('完全一致', () {
        expect(TextNormalizer.similarityScore('abc', 'abc'), 1.0);
      });

      test('類似度が高い', () {
        expect(
          TextNormalizer.similarityScore('γ-gtp', 'γgtp'),
          greaterThan(0.7),
        );
      });

      test('全く異なる', () {
        expect(TextNormalizer.similarityScore('abc', 'xyz'), lessThan(0.5));
      });
    });
  });
}
