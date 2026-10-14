import 'dart:math';

import 'package:medicine_app/core/config.dart';
import 'package:medicine_app/core/text_utils.dart';
import 'package:medicine_app/data/models.dart';
import 'package:medicine_app/logic/query_parser.dart';

enum MatchStatus { confident, ambiguous, notFound }

class Candidate {
  const Candidate(this.medicine, this.score);

  final Medicine medicine;
  final double score;
}

class MatchResult {
  const MatchResult(this.status, this.candidates);

  final MatchStatus status;
  final List<Candidate> candidates;

  Candidate? get top => candidates.isEmpty ? null : candidates.first;
}

class MedicineMatcher {
  static MatchResult match(ParsedQuery q, List<Medicine> medicines) {
    final nameQuery = normalizeText(q.nameText);

    // Strength-only search such as "500 mg": always ask the user to choose.
    if (nameQuery.isEmpty) {
      final qs = q.strength;
      if (qs == null) return const MatchResult(MatchStatus.notFound, []);
      final found = <Candidate>[];
      for (final m in medicines) {
        final ms = parseStrength(m.strength);
        if (ms != null && ms.sameAs(qs)) found.add(Candidate(m, 0.7));
      }
      if (found.isEmpty) return const MatchResult(MatchStatus.notFound, []);
      return MatchResult(MatchStatus.ambiguous, _trim(found));
    }

    final scored = <Candidate>[];
    for (final m in medicines) {
      var s = _nameScore(nameQuery, m);
      if (s <= 0) continue;
      s = _applyStrength(s, q, m);
      s = _applyForm(s, q, m);
      if (s >= MatchConfig.candidateMinScore) scored.add(Candidate(m, s));
    }
    if (scored.isEmpty) return const MatchResult(MatchStatus.notFound, []);

    final candidates = _trim(scored);
    final top = candidates.first.score;
    final second = candidates.length > 1 ? candidates[1].score : 0.0;
    final confident = top >= MatchConfig.confidentMinScore &&
        (top - second) >= MatchConfig.confidentMinMargin - 1e-9;
    return MatchResult(
      confident ? MatchStatus.confident : MatchStatus.ambiguous,
      candidates,
    );
  }

  static List<Candidate> _trim(List<Candidate> list) {
    list.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return a.medicine.brandName.compareTo(b.medicine.brandName);
    });
    if (list.length > MatchConfig.maxCandidates) {
      return list.sublist(0, MatchConfig.maxCandidates);
    }
    return list;
  }

  static double _nameScore(String nq, Medicine m) {
    var best = 0.0;
    for (final b in [m.brandName, ...m.aliases]) {
      best = max(best, _textScore(nq, b));
    }
    best = max(best, _textScore(nq, m.genericName) * 0.95);
    for (final i in m.ingredients) {
      best = max(best, _textScore(nq, i) * 0.95);
    }
    final maker = m.manufacturer;
    if (maker != null) best = max(best, _textScore(nq, maker) * 0.8);
    return best;
  }

  static double _textScore(String nq, String field) {
    final nf = normalizeText(field);
    if (nf.isEmpty) return 0.0;
    if (nq == nf) return 1.0;
    final qt = nq.split(' ');
    final ft = nf.split(' ');
    if (qt.every((t) => ft.contains(t))) return 0.9;
    return similarity(nq, nf);
  }

  static double _applyStrength(double s, ParsedQuery q, Medicine m) {
    final qs = q.strength;
    if (qs == null) return s;
    final ms = parseStrength(m.strength);
    if (ms == null) return s * 0.8;
    return qs.sameAs(ms) ? s : s * 0.5;
  }

  static double _applyForm(double s, ParsedQuery q, Medicine m) {
    final hint = q.formHint;
    if (hint == null) return s;
    final form = m.dosageForm?.toLowerCase();
    if (form == null) return s * 0.8;
    return form.contains(hint) ? s : s * 0.6;
  }
}
