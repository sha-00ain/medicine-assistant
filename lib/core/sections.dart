/// All sections of the medicine details screen, in display order.
enum SectionId {
  identity('identity'),
  uses('uses'),
  directions('directions'),
  dosage('dosage'),
  contraindications('contraindications'),
  sideEffects('sideEffects'),
  warnings('warnings'),
  overdose('overdose'),
  pregnancy('pregnancy'),
  price('price'),
  composition('composition'),
  mechanism('mechanism'),
  interactions('interactions'),
  pediatric('pediatric'),
  geriatric('geriatric'),
  kidney('kidney'),
  liver('liver'),
  alternatives('alternatives'),
  storage('storage'),
  expiry('expiry'),
  prescription('prescription'),
  sources('sources');

  const SectionId(this.key);

  final String key;

  static SectionId? fromKey(String key) {
    for (final s in SectionId.values) {
      if (s.key == key) return s;
    }
    return null;
  }
}
