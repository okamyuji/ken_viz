// PDF生成サービス [UC-10]
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:kenviz/domain/entities/checkup.dart';
import 'package:kenviz/domain/entities/test_result.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// 健診結果PDFレポートを生成するサービス
class PdfGeneratorService {
  /// 健診結果をPDFに変換
  Future<Uint8List> generate({
    required Checkup checkup,
    required List<TestResult> results,
    bool includePersonalInfo = true,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('yyyy年M月d日');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              '健康診断結果レポート',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Paragraph(text: '受診日: ${dateFormat.format(checkup.date)}'),
          if (checkup.facilityName != null)
            pw.Paragraph(text: '医療機関: ${checkup.facilityName}'),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            headers: ['検査項目', '結果', '単位', '基準値', '判定'],
            data: results.map((r) {
              final refRange = _formatRefRange(r.refLow, r.refHigh);
              return [
                r.itemName,
                r.value?.toString() ?? r.valueText ?? '-',
                r.unit ?? '',
                refRange,
                r.judgment.label,
              ];
            }).toList(),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  String _formatRefRange(double? low, double? high) {
    if (low == null && high == null) return '';
    if (low != null && high != null) return '$low〜$high';
    if (low != null) return '$low以上';
    return '$high以下';
  }
}
