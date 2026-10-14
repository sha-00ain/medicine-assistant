import 'package:medicine_app/core/sections.dart';
import 'package:medicine_app/core/strings.dart';
import 'package:medicine_app/core/text_utils.dart';
import 'package:medicine_app/data/models.dart';
import 'package:medicine_app/logic/confirmation.dart';

/// One section of the details screen, already localized.
class SectionView {
  const SectionView({
    required this.id,
    required this.available,
    this.lines = const [],
    this.sources = const [],
    this.notes = const [],
  });

  final SectionId id;

  /// False means "Information not available" is shown.
  final bool available;
  final List<String> lines;
  final List<SourceInfo> sources;

  /// Fixed safety notes (not medical data), e.g. the overdose emergency text.
  final List<String> notes;
}

class SectionBuilder {
  /// Sections shown on the details screen, in order. The prescription section
  /// is only shown when a prescription is provided (later phase). The sources
  /// section is always appended last by [buildAll].
  static const List<SectionId> displayOrder = [
    SectionId.identity,
    SectionId.uses,
    SectionId.directions,
    SectionId.dosage,
    SectionId.contraindications,
    SectionId.sideEffects,
    SectionId.warnings,
    SectionId.overdose,
    SectionId.pregnancy,
    SectionId.price,
    SectionId.composition,
    SectionId.mechanism,
    SectionId.interactions,
    SectionId.pediatric,
    SectionId.geriatric,
    SectionId.kidney,
    SectionId.liver,
    SectionId.alternatives,
    SectionId.storage,
    SectionId.expiry,
  ];

  static List<SectionView> buildAll(
    ConfirmedMedicine confirmed,
    List<Medicine> all,
    String lang,
  ) {
    final views = <SectionView>[
      for (final id in displayOrder) build(id, confirmed, all, lang),
    ];

    final seen = <String>{};
    final sources = <SourceInfo>[];
    for (final v in views) {
      for (final s in v.sources) {
        if (seen.add(s.dedupeKey)) sources.add(s);
      }
    }
    views.add(SectionView(
      id: SectionId.sources,
      available: sources.isNotEmpty,
      sources: sources,
    ));
    return views;
  }

  static SectionView build(
    SectionId id,
    ConfirmedMedicine confirmed,
    List<Medicine> all,
    String lang,
  ) {
    final m = confirmed.medicine;
    switch (id) {
      case SectionId.identity:
        return _identity(m, lang);
      case SectionId.composition:
        return _composition(m, lang);
      case SectionId.price:
        return _price(m, lang);
      case SectionId.alternatives:
        return _alternatives(m, all, lang);
      case SectionId.expiry:
        return SectionView(
          id: id,
          available: false,
          notes: [Strings.t(lang, 'expiry.note')],
        );
      case SectionId.prescription:
      case SectionId.sources:
        return SectionView(id: id, available: false);
      default:
        return _fromData(id, m, lang);
    }
  }

  static String _kv(String lang, String labelKey, String? value) {
    final v = (value == null || value.trim().isEmpty)
        ? Strings.t(lang, 'info.na')
        : value;
    return '${Strings.t(lang, labelKey)}: $v';
  }

  static SectionView _identity(Medicine m, String lang) {
    return SectionView(
      id: SectionId.identity,
      available: true,
      lines: [
        _kv(lang, 'identity.brand', m.brandName),
        _kv(lang, 'identity.generic', m.genericName),
        _kv(
          lang,
          'identity.ingredients',
          m.ingredients.isEmpty ? null : m.ingredients.join(', '),
        ),
        _kv(lang, 'identity.strength', m.strength),
        _kv(lang, 'identity.form', m.dosageForm),
        _kv(lang, 'identity.manufacturer', m.manufacturer),
      ],
      sources: [m.identitySource],
    );
  }

  static SectionView _composition(Medicine m, String lang) {
    if (m.ingredients.isEmpty) {
      return const SectionView(id: SectionId.composition, available: false);
    }
    final lines = <String>[...m.ingredients];
    final s = m.strength;
    if (s != null && s.trim().isNotEmpty) {
      lines.add(_kv(lang, 'identity.strength', s));
    }
    return SectionView(
      id: SectionId.composition,
      available: true,
      lines: lines,
      sources: [m.identitySource],
    );
  }

  static SectionView _price(Medicine m, String lang) {
    final p = m.price;
    if (p == null) {
      return const SectionView(id: SectionId.price, available: false);
    }
    final lines = <String>[
      _kv(lang, 'price.pack', p.packSize),
      _kv(lang, 'price.perPack',
          '${p.amount.toStringAsFixed(2)} ${p.currency}'),
    ];
    final perUnit = p.perUnit;
    if (perUnit != null) {
      lines.add(_kv(
          lang, 'price.perUnit', '${perUnit.toStringAsFixed(2)} ${p.currency}'));
    }
    lines.add(_kv(lang, 'price.country', p.country));
    lines.add(_kv(lang, 'price.verifiedOn', p.lastVerified));
    return SectionView(
      id: SectionId.price,
      available: true,
      lines: lines,
      sources: [p.source],
    );
  }

  /// Same generic name, same strength and same dosage form (never a different
  /// strength or form), computed only from the local records.
  static List<Medicine> findAlternatives(Medicine m, List<Medicine> all) {
    final generic = normalizeText(m.genericName);
    if (generic.isEmpty) return const [];
    final strength = parseStrength(m.strength);
    final form = (m.dosageForm ?? '').toLowerCase();
    return all.where((o) {
      if (o.id == m.id) return false;
      if (normalizeText(o.genericName) != generic) return false;
      final os = parseStrength(o.strength);
      if (strength == null || os == null || !strength.sameAs(os)) return false;
      return (o.dosageForm ?? '').toLowerCase() == form;
    }).toList();
  }

  static SectionView _alternatives(
    Medicine m,
    List<Medicine> all,
    String lang,
  ) {
    final alts = findAlternatives(m, all);
    if (alts.isEmpty) {
      return const SectionView(id: SectionId.alternatives, available: false);
    }
    return SectionView(
      id: SectionId.alternatives,
      available: true,
      lines: [
        for (final a in alts)
          a.manufacturer == null
              ? a.brandName
              : '${a.brandName} - ${a.manufacturer}',
      ],
      sources: [
        SourceInfo(
          name: Strings.t(lang, 'source.computed'),
          lastChecked: m.identitySource.lastChecked,
          verification: m.isDemo ? 'demo' : 'unverified',
        ),
      ],
      notes: [Strings.t(lang, 'alternatives.note')],
    );
  }

  static SectionView _fromData(SectionId id, Medicine m, String lang) {
    final notes = <String>[];
    if (id == SectionId.dosage) notes.add(Strings.t(lang, 'dosage.note'));
    if (id == SectionId.overdose) {
      notes.add(Strings.t(lang, 'overdose.emergency'));
    }
    final d = m.sections[id];
    if (d == null) {
      return SectionView(id: id, available: false, notes: notes);
    }
    return SectionView(
      id: id,
      available: true,
      lines: [d.text.of(lang)],
      sources: [d.source],
      notes: notes,
    );
  }
}
