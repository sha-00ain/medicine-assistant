/// Matching thresholds. Tune these later using test fixtures.
class MatchConfig {
  /// Minimum score for the top candidate to count as "confident".
  static const double confidentMinScore = 0.85;

  /// Minimum gap between the top and second candidate to count as "confident".
  static const double confidentMinMargin = 0.15;

  /// Candidates below this score are dropped.
  static const double candidateMinScore = 0.6;

  /// Maximum number of candidates shown to the user.
  static const int maxCandidates = 8;
}
