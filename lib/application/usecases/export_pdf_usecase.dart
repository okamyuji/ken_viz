// PDF出力ユースケース [UC-10]
import 'dart:io';

import 'package:kenviz/application/services/pdf_generator_service.dart';
import 'package:kenviz/domain/repositories/repositories.dart';
import 'package:path_provider/path_provider.dart';

/// 健診結果をPDFとして出力する
class ExportPdfUseCase {
  ExportPdfUseCase({
    required this.checkupRepository,
    required this.testResultRepository,
    required this.pdfGenerator,
  });

  final CheckupRepository checkupRepository;
  final TestResultRepository testResultRepository;
  final PdfGeneratorService pdfGenerator;

  /// 指定した健診IDのPDFを生成し、ファイルパスを返す
  Future<String> execute(String checkupId) async {
    final checkup = await checkupRepository.getById(checkupId);
    if (checkup == null) {
      throw ArgumentError('健診データが見つかりません: $checkupId');
    }

    final results = await testResultRepository.getByCheckupId(checkupId);
    final pdfBytes = await pdfGenerator.generate(
      checkup: checkup,
      results: results,
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/kenviz_report_$checkupId.pdf');
    await file.writeAsBytes(pdfBytes);

    return file.path;
  }
}
