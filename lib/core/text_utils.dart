import 'dart:math';

/// Lowercases, removes punctuation (keeps letters, combining marks and digits,
/// so Bangla text stays intact) and collapses whitespace.
String normalizeText(String input) {
  final lower = input.toLowerCase();
  final cleaned =
      lower.replaceAll(RegExp(r'[^\p{L}\p{M}\p{N}\s]', unicode: true), ' ');
  return cleaned
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .join(' ');
}

int levenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  var prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final curr = List<int>.filled(b.length + 1, 0);
    curr[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      curr[j] = min(min(curr[j - 1] + 1, prev[j] + 1), prev[j - 1] + cost);
    }
    prev = curr;
  }
  return prev[b.length];
}

/// 1.0 means identical, 0.0 means completely different.
double similarity(String a, String b) {
  if (a.isEmpty && b.isEmpty) return 1.0;
  final maxLen = max(a.length, b.length);
  return 1.0 - levenshtein(a, b) / maxLen;
}

final RegExp strengthRegex = RegExp(
  r'(\d+(?:\.\d+)?)\s*(mg|mcg|g|ml|iu)(?![a-zA-Z])',
  caseSensitive: false,
);

class Strength {
  const Strength(this.value, this.unit);

  final double value;
  final String unit;

  bool sameAs(Strength other) =>
      (value - other.value).abs() < 1e-9 && unit == other.unit;
}

/// Reads the first "<number> <unit>" in [text], e.g. "500 mg".
Strength? parseStrength(String? text) {
  if (text == null) return null;
  final m = strengthRegex.firstMatch(text);
  if (m == null) return null;
  return Strength(double.parse(m.group(1)!), m.group(2)!.toLowerCase());
}
