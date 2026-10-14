import 'dart:math';

import 'package:medicine_app/core/config.dart';
import 'package:medicine_app/core/text_utils.dart';
import 'package:medicine_app/data/models.dart';
import 'package:medicine_app/logic/matcher.dart';
import 'package:medicine_app/ocr/ocr_service.dart';

enum PhotoMatchKind { confident, ambiguous, notFound, unreadable }

/// What we read from the package, shown to the user for transparency.
class PackageClues {
  const PackageClues({
    required this.text,
    this.strengths = const [],
    this.forms = const [],
  });

  final String text;
  final List<Strength> strengths;
  final List<String> forms;
}

class PhotoMatch {
  const PhotoMatch({
    required this.kind,
    required this.candidates,
    required this.clues,
  });

  final PhotoMatchKind kind;
  final List<Candidate> candidates;
  final PackageClues clues;

  /// Used with ConfirmedMedicine.fromMatch. Only a confident photo match can
  /// become a confirmed medicine.
  MatchResult toMatchResult() {
    switch (kind) {
      case PhotoMatchKind.confident:
        return MatchResult(MatchStatus.confident, candidates);
      case PhotoMatchKind.ambiguous:
        return MatchResult(MatchStatus.ambiguous, candidates);
      case PhotoMatchKind.notFound:
      case PhotoMatchKind.unreadable:
        return const MatchResult(MatchStatus.notFound, []);
    }
  }
}

class _Scored {
  _Scored(this.medicine, this.score, this.manufacturerMatched);

  final Medicine medicine;
  double score;
  final bool manufacturerMatched;
}

/// Matches text read from a package photo against the medicine records. Only
/// the printed text is used. A pill is never identified by appearance.
class PackageMatcher {
  static const List<String> _forms = [
    'tablet',
    'capsule',
    'syrup',
    'suspension',
    'injection',
    'drops',
    'cream',
    'ointment',
  ];

  static PhotoMatch match(OcrResult ocr, List<Medicine> medicines) {
    final norm = normalizeText(ocr.text);
    final tokens = norm.isEmpty ? <String>[] : norm.split(' ');
    final clues = PackageClues(
      text: ocr.text.trim(),
      strengths: _strengths(ocr.text),
      forms: _formsIn(norm),
    );

    // No word of at least 3 characters means there is nothing to match.
    if (!tokens.any((t) => t.length >= 3)) {
      return PhotoMatch(
        kind: PhotoMatchKind.unreadable,
        candidates: const [],
        clues: clues,
      );
    }

    final scored = <_Scored>[];
    for (final m in medicines) {
      var s = _nameScore(tokens, m);
      if (s <= 0) continue;
      s = _applyStrength(s, clues, m);
      s = _applyForm(s, clues, m);
      if (s < MatchConfig.candidateMinScore) continue;
      scored.add(_Scored(m, s, _manufacturerMatched(tokens, m)));
    }

    // If the manufacturer printed on the package matches some candidates,
    // candidates from other manufacturers are less likely.
    if (scored.any((c) => c.manufacturerMatched)) {
      for (final c in scored) {
        if (!c.manufacturerMatched && c.medicine.manufacturer != null) {
          c.score *= 0.85;
        }
      }
      scored.removeWhere((c) => c.score < MatchConfig.candidateMinScore);
    }

    if (scored.isEmpty) {
      return PhotoMatch(
        kind: PhotoMatchKind.notFound,
        candidates: const [],
        clues: clues,
      );
    }

    scored.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return a.medicine.brandName.compareTo(b.medicine.brandName);
    });
    final trimmed = scored.length > MatchConfig.maxCandidates
        ? scored.sublist(0, MatchConfig.maxCandidates)
        : scored;
    final candidates = [for (final c in trimmed) Candidate(c.medicine, c.score)];

    final top = candidates.first.score;
    final second = candidates.length > 1 ? candidates[1].score : 0.0;
    final confident = top >= MatchConfig.confidentMinScore &&
        (top - second) >= MatchConfig.confidentMinMargin - 1e-9;
    return PhotoMatch(
      kind: confident ? PhotoMatchKind.confident : PhotoMatchKind.ambiguous,
      candidates: candidates,
      clues: clues,
    );
  }

  static List<Strength> _strengths(String text) {
    return [
      for (final m in strengthRegex.allMatches(text.toLowerCase()))
        Strength(double.parse(m.group(1)!), m.group(2)!.toLowerCase()),
    ];
  }

  static List<String> _formsIn(String norm) =>
      [for (final f in _forms) if (norm.contains(f)) f];

  /// Best score of [field] against any run of consecutive OCR words. Very
  /// short names (under 4 characters) must match exactly, because fuzzy
  /// matching on short text produces false matches.
  static double _windowScore(List<String> tokens, String field) {
    final nf = normalizeText(field);
    if (nf.isEmpty) return 0.0;
    final n = nf.split(' ').length;
    if (tokens.length < n) return 0.0;
    var best = 0.0;
    for (var i = 0; i + n <= tokens.length; i++) {
      final window = tokens.sublist(i, i + n).join(' ');
      double s;
      if (window == nf) {
        s = 1.0;
      } else if (nf.length < 4) {
        s = 0.0;
      } else {
        s = similarity(window, nf);
      }
      best = max(best, s);
    }
    return best;
  }

  static double _nameScore(List<String> tokens, Medicine m) {
    var best = 0.0;
    for (final b in [m.brandName, ...m.aliases]) {
      best = max(best, _windowScore(tokens, b));
    }
    best = max(best, _windowScore(tokens, m.genericName) * 0.95);
    for (final i in m.ingredients) {
      best = max(best, _windowScore(tokens, i) * 0.95);
    }
    return best;
  }

  static bool _manufacturerMatched(List<String> tokens, Medicine m) {
    final maker = m.manufacturer;
    if (maker == null) return false;
    return _windowScore(tokens, maker) >= 0.85;
  }

  static double _applyStrength(double s, PackageClues clues, Medicine m) {
    if (clues.strengths.isEmpty) return s;
    final ms = parseStrength(m.strength);
    if (ms == null) return s * 0.8;
    return clues.strengths.any(ms.sameAs) ? s : s * 0.5;
  }

  static double _applyForm(double s, PackageClues clues, Medicine m) {
    if (clues.forms.isEmpty) return s;
    final form = m.dosageForm?.toLowerCase();
    if (form == null) return s * 0.8;
    return clues.forms.any((f) => form.contains(f)) ? s : s * 0.6;
  }
}
