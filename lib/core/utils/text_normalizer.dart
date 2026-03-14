/// OCRテキストの正規化ユーティリティ
class TextNormalizer {
  TextNormalizer._();

  /// 全角→半角変換（数字・英字・記号）
  static String toHalfWidth(String input) {
    final buffer = StringBuffer();
    for (final codeUnit in input.runes) {
      if (codeUnit >= 0xFF10 && codeUnit <= 0xFF19) {
        // ０-９ → 0-9
        buffer.writeCharCode(codeUnit - 0xFF10 + 0x30);
      } else if (codeUnit >= 0xFF21 && codeUnit <= 0xFF3A) {
        // Ａ-Ｚ → A-Z
        buffer.writeCharCode(codeUnit - 0xFF21 + 0x41);
      } else if (codeUnit >= 0xFF41 && codeUnit <= 0xFF5A) {
        // ａ-ｚ → a-z
        buffer.writeCharCode(codeUnit - 0xFF41 + 0x61);
      } else if (codeUnit == 0xFF0E) {
        // ．→ .
        buffer.write('.');
      } else if (codeUnit == 0xFF0F) {
        // ／→ /
        buffer.write('/');
      } else if (codeUnit == 0xFF0D || codeUnit == 0x2212) {
        // －, − → -
        buffer.write('-');
      } else if (codeUnit == 0x3000) {
        // 全角スペース → 半角スペース
        buffer.write(' ');
      } else {
        buffer.writeCharCode(codeUnit);
      }
    }
    return buffer.toString();
  }

  /// 正規化（全角→半角 + スペース圧縮 + トリム）
  static String normalize(String input) {
    final half = toHalfWidth(input);
    return half.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// 検査項目名の正規化（比較用）
  static String normalizeItemName(String input) {
    var result = normalize(input);
    // 括弧の正規化
    result = result
        .replaceAll('（', '(')
        .replaceAll('）', ')')
        .replaceAll('【', '[')
        .replaceAll('】', ']');
    // ガンマの表記揺れ統一
    result = result
        .replaceAll('γ', 'γ')
        .replaceAll('ガンマ', 'γ')
        .replaceAll('Γ', 'γ');
    // スペース除去（比較用）
    result = result.replaceAll(' ', '');
    return result.toLowerCase();
  }

  /// 数値の抽出（先頭の数値のみ）
  static double? extractNumber(String input) {
    final normalized = toHalfWidth(input).trim();
    final match = RegExp(r'^[<>≦≧≤≥]?\s*(\d+\.?\d*)').firstMatch(normalized);
    if (match != null) {
      return double.tryParse(match.group(1)!);
    }
    return null;
  }

  /// 基準範囲パターンの検出
  static ({double? low, double? high})? extractRange(String input) {
    final normalized = toHalfWidth(input).trim();

    // パターン1: "70〜139", "70-139", "70 ~ 139"
    final rangeMatch = RegExp(
      r'(\d+\.?\d*)\s*[〜~\-–—]\s*(\d+\.?\d*)',
    ).firstMatch(normalized);
    if (rangeMatch != null) {
      return (
        low: double.tryParse(rangeMatch.group(1)!),
        high: double.tryParse(rangeMatch.group(2)!),
      );
    }

    // パターン2: "≦139" or "139以下"
    final upperMatch = RegExp(
      r'[≦≤<]?\s*(\d+\.?\d*)\s*以下',
    ).firstMatch(normalized);
    if (upperMatch != null) {
      return (low: null, high: double.tryParse(upperMatch.group(1)!));
    }

    // パターン3: "≧70" or "70以上"
    final lowerMatch = RegExp(
      r'[≧≥>]?\s*(\d+\.?\d*)\s*以上',
    ).firstMatch(normalized);
    if (lowerMatch != null) {
      return (low: double.tryParse(lowerMatch.group(1)!), high: null);
    }

    return null;
  }

  /// 単位パターンの検出
  static String? extractUnit(String input) {
    final normalized = toHalfWidth(input).trim();
    final patterns = [
      'mg/dL',
      'g/dL',
      'mL/min/1.73m2',
      'U/L',
      'IU/L',
      'mmHg',
      'mm',
      'kg',
      'cm',
      '%',
      'pg',
      'fL',
      '万/μL',
      '/μL',
      '×10^4/μL',
      'mEq/L',
      'mmol/L',
      'ng/mL',
    ];
    for (final unit in patterns) {
      if (normalized.contains(unit)) return unit;
    }
    return null;
  }

  /// 判定フラグの検出
  static String? extractFlag(String input) {
    final normalized = toHalfWidth(input).trim().toUpperCase();
    // H/L フラグ
    if (RegExp(r'^[HL]$').hasMatch(normalized)) return normalized;
    // A〜D 判定
    if (RegExp(r'^[A-D][1-2]?$').hasMatch(normalized)) return normalized;
    // ※, ＊ (異常マーク)
    if (normalized.contains('※') || normalized.contains('*')) return 'H';
    return null;
  }

  /// Levenshtein距離
  static int levenshteinDistance(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final matrix = List.generate(
      a.length + 1,
      (i) => List.generate(b.length + 1, (j) => 0),
    );

    for (var i = 0; i <= a.length; i++) {
      matrix[i][0] = i;
    }
    for (var j = 0; j <= b.length; j++) {
      matrix[0][j] = j;
    }

    for (var i = 1; i <= a.length; i++) {
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[a.length][b.length];
  }

  /// 類似度スコア (0.0〜1.0)
  static double similarityScore(String a, String b) {
    if (a.isEmpty && b.isEmpty) return 1.0;
    final maxLen = a.length > b.length ? a.length : b.length;
    if (maxLen == 0) return 1.0;
    final distance = levenshteinDistance(a, b);
    return 1.0 - (distance / maxLen);
  }
}
