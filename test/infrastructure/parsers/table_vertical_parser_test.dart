import 'package:flutter_test/flutter_test.dart';
import 'package:kenviz/core/constants/test_item_defaults.dart';
import 'package:kenviz/infrastructure/parsers/parsed_checkup_result.dart';
import 'package:kenviz/infrastructure/parsers/parser_strategy.dart';
import 'package:kenviz/infrastructure/parsers/table_vertical_parser.dart';

/// テスト用ヘルパー: テキスト行からOcrTextResultを生成
OcrTextResult _makeOcrResult(List<String> lines) {
  final ocrLines = lines
      .map(
        (text) => OcrTextLine(
          text: text,
          elements: text
              .split(' ')
              .map((e) => OcrTextElement(text: e))
              .toList(),
        ),
      )
      .toList();

  return OcrTextResult(
    blocks: [OcrTextBlock(lines: ocrLines)],
    fullText: lines.join('\n'),
  );
}

void main() {
  late TableVerticalParser parser;

  setUp(() {
    parser = TableVerticalParser(defaultTestItems);
  });

  group('TableVerticalParser', () {
    group('canParse', () {
      test('タブ区切り表はスコアが高い', () {
        final ocr = _makeOcrResult([
          '身長\t170.5\tcm',
          '体重\t65.0\tkg',
          'BMI\t22.4\t18.5〜24.9\tA',
          'LDL-C\t142\tmg/dL\t70〜139\tH',
        ]);
        expect(parser.canParse(ocr), greaterThan(0.5));
      });

      test('テーブル構造でないテキストはスコアが低い', () {
        final ocr = _makeOcrResult([
          'あなたの健康診断結果をお知らせします。',
          '受診日: 2025年10月15日',
          '受診機関: ○○クリニック',
        ]);
        expect(parser.canParse(ocr), lessThan(0.3));
      });
    });

    group('parse - タブ区切り', () {
      test('基本的な健診結果をパースできる', () {
        final ocr = _makeOcrResult([
          '身長\t170.5\tcm',
          '体重\t65.0\tkg',
          'BMI\t22.4\t18.5〜24.9\tA',
        ]);

        final result = parser.parse(ocr);

        expect(result.rows.length, 3);
        expect(result.detectedFormat, CheckupFormat.tableVertical);

        // 身長
        final height = result.rows[0];
        expect(height.matchedItemCode, 'HEIGHT');
        expect(height.value!.value, 170.5);

        // BMI
        final bmi = result.rows[2];
        expect(bmi.matchedItemCode, 'BMI');
        expect(bmi.value!.value, 22.4);
      });

      test('脂質項目のパース', () {
        final ocr = _makeOcrResult([
          'LDL-C\t142\tmg/dL\t70〜139\tH',
          'HDL-C\t55\tmg/dL\t40以上',
          '中性脂肪\t120\tmg/dL\t30〜149',
        ]);

        final result = parser.parse(ocr);

        expect(result.rows.length, 3);

        final ldl = result.rows[0];
        expect(ldl.matchedItemCode, 'LDL_C');
        expect(ldl.value!.value, 142.0);
        expect(ldl.flag?.value, 'H');

        final hdl = result.rows[1];
        expect(hdl.matchedItemCode, 'HDL_C');
        expect(hdl.value!.value, 55.0);
      });

      test('糖代謝のパース (小数値)', () {
        final ocr = _makeOcrResult([
          '空腹時血糖\t98\tmg/dL\t70〜99\tA',
          'HbA1c\t5.6\t%\t4.6〜5.9\tA',
        ]);

        final result = parser.parse(ocr);

        expect(result.rows.length, 2);

        final hba1c = result.rows[1];
        expect(hba1c.matchedItemCode, 'HBA1C');
        expect(hba1c.value!.value, 5.6);
      });
    });

    group('parse - スペース区切り', () {
      test('複数スペースで区切られた行をパース', () {
        final ocr = _makeOcrResult([
          'BMI         22.4     18.5〜24.9     A',
          'LDL-C       142      70〜139        H',
        ]);

        final result = parser.parse(ocr);

        expect(result.rows.length, 2);
        expect(result.rows[0].matchedItemCode, 'BMI');
        expect(result.rows[0].value!.value, 22.4);
        expect(result.rows[1].matchedItemCode, 'LDL_C');
        expect(result.rows[1].value!.value, 142.0);
      });
    });

    group('parse - パイプ区切り', () {
      test('パイプ文字で区切られた行をパース', () {
        final ocr = _makeOcrResult(['身長 | 170.5 | cm', '体重 | 65.0 | kg']);

        final result = parser.parse(ocr);

        expect(result.rows.length, 2);
        expect(result.rows[0].matchedItemCode, 'HEIGHT');
        expect(result.rows[0].value!.value, 170.5);
      });
    });

    group('parse - 全角数字', () {
      test('全角数字を正しくパース', () {
        final ocr = _makeOcrResult(['ＢＭＩ\t２２．４\t１８．５〜２４．９']);

        final result = parser.parse(ocr);

        expect(result.rows.length, 1);
        expect(result.rows[0].value!.value, 22.4);
      });
    });

    group('parse - 信頼度', () {
      test('マスタ一致項目は高信頼度', () {
        final ocr = _makeOcrResult(['BMI\t22.4\t18.5〜24.9']);

        final result = parser.parse(ocr);
        expect(result.rows[0].overallConfidence.value, greaterThan(0.7));
      });

      test('全行の平均信頼度が計算される', () {
        final ocr = _makeOcrResult([
          'BMI\t22.4\t18.5〜24.9',
          'LDL-C\t142\t70〜139',
        ]);

        final result = parser.parse(ocr);
        expect(result.averageConfidence, greaterThan(0.0));
        expect(result.averageConfidence, lessThanOrEqualTo(1.0));
      });
    });

    group('parse - エッジケース', () {
      test('空の入力', () {
        final ocr = _makeOcrResult([]);
        final result = parser.parse(ocr);
        expect(result.rows, isEmpty);
      });

      test('数値のない行はスキップ', () {
        final ocr = _makeOcrResult([
          '検査項目\t結果\t基準値\t判定', // ヘッダー行
          'BMI\t22.4\t18.5〜24.9\tA',
        ]);

        final result = parser.parse(ocr);
        // ヘッダー行は数値がないのでスキップされ、BMI行のみ
        expect(result.rows.length, 1);
        expect(result.rows[0].matchedItemCode, 'BMI');
      });

      test('1列しかない行はスキップ', () {
        final ocr = _makeOcrResult(['血液検査', 'BMI\t22.4']);

        final result = parser.parse(ocr);
        expect(result.rows.length, 1);
      });
    });

    group('parse - 総合テスト', () {
      test('典型的な企業健診結果', () {
        final ocr = _makeOcrResult([
          '検査項目\t結果\t単位\t基準値\t判定',
          '身長\t170.5\tcm\t-\tA',
          '体重\t65.0\tkg\t-\tA',
          'BMI\t22.4\t-\t18.5〜24.9\tA',
          '収縮期血圧\t128\tmmHg\t〜129\tA',
          '拡張期血圧\t78\tmmHg\t〜84\tA',
          'LDL-C\t142\tmg/dL\t70〜139\tH',
          'HDL-C\t55\tmg/dL\t40以上\tA',
          '中性脂肪\t120\tmg/dL\t30〜149\tA',
          '空腹時血糖\t98\tmg/dL\t70〜99\tA',
          'HbA1c\t5.6\t%\t4.6〜5.9\tA',
          'AST(GOT)\t25\tU/L\t10〜30\tA',
          'ALT(GPT)\t22\tU/L\t6〜30\tA',
          'γ-GTP\t85\tU/L\t〜50\tH',
          'クレアチニン\t0.85\tmg/dL\t0.6〜1.1\tA',
          'eGFR\t78.5\tmL/min/1.73m2\t60以上\tA',
          '尿酸\t6.2\tmg/dL\t2.1〜7.0\tA',
        ]);

        final result = parser.parse(ocr);

        // ヘッダー行除外で16項目
        expect(result.rows.length, 16);

        // 全項目がマスタにマッチ
        for (final row in result.rows) {
          expect(
            row.matchedItemCode,
            isNotNull,
            reason: '${row.itemName.value} がマッチしない',
          );
        }

        // LDLがHフラグ
        final ldl = result.rows.firstWhere((r) => r.matchedItemCode == 'LDL_C');
        expect(ldl.flag?.value, 'H');

        // γ-GTPがHフラグ
        final ggt = result.rows.firstWhere((r) => r.matchedItemCode == 'GGT');
        expect(ggt.value!.value, 85.0);
        expect(ggt.flag?.value, 'H');

        // 平均信頼度が高い
        expect(result.averageConfidence, greaterThan(0.7));
      });
    });
  });
}
