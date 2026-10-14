import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_app/core/sections.dart';
import 'package:medicine_app/core/strings.dart';
import 'package:medicine_app/data/models.dart';
import 'package:medicine_app/logic/confirmation.dart';
import 'package:medicine_app/logic/matcher.dart';
import 'package:medicine_app/logic/query_parser.dart';
import 'package:medicine_app/logic/section_builder.dart';
import 'package:medicine_app/state/app_state.dart';

List<Medicine> loadDemo() => parseMedicines(
      File('assets/data/demo_medicines.json').readAsStringSync(),
    );

MatchResult run(String input, List<Medicine> all) =>
    MedicineMatcher.match(QueryParser.parse(input), all);

Medicine fake(String id, String brand) => Medicine(
      id: id,
      brandName: brand,
      genericName: 'generic-$id',
      identitySource: const SourceInfo(
        name: 'test',
        lastChecked: '2026-10-13',
        verification: 'demo',
      ),
    );

SectionView sectionOf(List<SectionView> views, SectionId id) =>
    views.firstWhere((v) => v.id == id);

void main() {
  final all = loadDemo();

  group('QueryParser', () {
    test('splits name, strength and question intent (Bangla)', () {
      final q = QueryParser.parse('DemoMol 500 mg কী কাজে লাগে?');
      expect(q.nameText, 'demomol');
      expect(q.strength?.value, 500);
      expect(q.strength?.unit, 'mg');
      expect(q.intent, SectionId.uses);
      expect(q.looksLikeQuestion, isTrue);
    });

    test('plain name has no question and no intent', () {
      final q = QueryParser.parse('AlphaDemo');
      expect(q.nameText, 'alphademo');
      expect(q.intent, isNull);
      expect(q.looksLikeQuestion, isFalse);
    });

    test('English question is understood', () {
      final q = QueryParser.parse('what are the side effects of DemoMol 250 mg');
      expect(q.intent, SectionId.sideEffects);
      expect(q.nameText, 'demomol');
      expect(q.strength?.value, 250);
    });
  });

  group('MedicineMatcher', () {
    test('complete unique name is confident', () {
      final r = run('AlphaDemo', all);
      expect(r.status, MatchStatus.confident);
      expect(r.top?.medicine.id, 'alphademo');
    });

    test('matching ignores letter case', () {
      expect(run('alphademo', all).status, MatchStatus.confident);
    });

    test('name plus strength is confident and picks the right strength', () {
      final r = run('DemoMol 500 mg', all);
      expect(r.status, MatchStatus.confident);
      expect(r.top?.medicine.id, 'demomol-500');
    });

    test('short name with several matches is ambiguous', () {
      final r = run('DemoMol', all);
      expect(r.status, MatchStatus.ambiguous);
      final ids = r.candidates.map((c) => c.medicine.id).toSet();
      expect(ids, containsAll(['demomol-250', 'demomol-500', 'demomol-syrup']));
    });

    test('Bangla alias finds the same medicine and asks to choose', () {
      final r = run('ডেমোমল', all);
      expect(r.status, MatchStatus.ambiguous);
      expect(r.candidates.length, greaterThanOrEqualTo(3));
    });

    test('dosage form in the text disambiguates', () {
      final r = run('DemoMol syrup', all);
      expect(r.status, MatchStatus.confident);
      expect(r.top?.medicine.id, 'demomol-syrup');
    });

    test('generic name shared by several brands is ambiguous', () {
      final r = run('Demo Generic B', all);
      expect(r.status, MatchStatus.ambiguous);
      final ids = r.candidates.map((c) => c.medicine.id).toSet();
      expect(ids, containsAll(['alphademo', 'betademo']));
    });

    test('strength only lists medicines and always asks to confirm', () {
      final r = run('500 mg', all);
      expect(r.status, MatchStatus.ambiguous);
      expect(r.candidates.map((c) => c.medicine.id), contains('demomol-500'));
    });

    test('unknown text is not found', () {
      expect(run('zzzzzz', all).status, MatchStatus.notFound);
    });
  });

  group('Confidence boundaries', () {
    test('clear winner (second candidate far behind) is confident', () {
      final meds = [fake('a', 'abcdefghij'), fake('b', 'abcdefghxy')];
      expect(run('abcdefghij', meds).status, MatchStatus.confident);
    });

    test('close second candidate (margin too small) is ambiguous', () {
      final meds = [fake('a', 'abcdefghij'), fake('b', 'abcdefghix')];
      expect(run('abcdefghij', meds).status, MatchStatus.ambiguous);
    });

    test('single candidate below the score threshold is ambiguous', () {
      final meds = [fake('a', 'abcde')];
      final r = run('abcdx', meds);
      expect(r.status, MatchStatus.ambiguous);
      expect(r.candidates.length, 1);
    });

    test('single candidate above the score threshold is confident', () {
      final meds = [fake('a', 'abcdefghij')];
      expect(run('abcdefghix', meds).status, MatchStatus.confident);
    });
  });

  group('Identity confirmation gate', () {
    test('an ambiguous result can never become a confirmed medicine', () {
      final r = run('DemoMol', all);
      expect(() => ConfirmedMedicine.fromMatch(r), throwsStateError);
    });

    test('a not-found result can never become a confirmed medicine', () {
      final r = run('zzzzzz', all);
      expect(() => ConfirmedMedicine.fromMatch(r), throwsStateError);
    });

    test('a confident result becomes a confirmed medicine', () {
      final r = run('AlphaDemo', all);
      expect(ConfirmedMedicine.fromMatch(r).medicine.id, 'alphademo');
    });
  });

  group('SectionBuilder', () {
    final gamma = all.firstWhere((m) => m.id == 'gammademo');
    final alpha = all.firstWhere((m) => m.id == 'alphademo');
    final demomol250 = all.firstWhere((m) => m.id == 'demomol-250');

    test('missing information is marked unavailable, never invented', () {
      final views = SectionBuilder.buildAll(
        ConfirmedMedicine.userSelected(gamma),
        all,
        'en',
      );
      expect(sectionOf(views, SectionId.liver).available, isFalse);
      expect(sectionOf(views, SectionId.price).available, isFalse);
      expect(sectionOf(views, SectionId.composition).available, isFalse);
      expect(sectionOf(views, SectionId.uses).available, isTrue);
    });

    test('dosage always carries the "general reference" note', () {
      final views = SectionBuilder.buildAll(
        ConfirmedMedicine.userSelected(gamma),
        all,
        'en',
      );
      expect(
        sectionOf(views, SectionId.dosage).notes,
        contains(Strings.t('en', 'dosage.note')),
      );
    });

    test('overdose always carries the emergency note, even without data', () {
      final views = SectionBuilder.buildAll(
        ConfirmedMedicine.userSelected(gamma),
        all,
        'en',
      );
      final overdose = sectionOf(views, SectionId.overdose);
      expect(overdose.available, isFalse);
      expect(overdose.notes, contains(Strings.t('en', 'overdose.emergency')));
    });

    test('alternatives need the same generic, strength and form', () {
      expect(
        SectionBuilder.findAlternatives(alpha, all).map((m) => m.id),
        ['betademo'],
      );
      expect(SectionBuilder.findAlternatives(demomol250, all), isEmpty);
    });

    test('price shows country, currency, pack size and verified date', () {
      final views = SectionBuilder.buildAll(
        ConfirmedMedicine.userSelected(demomol250),
        all,
        'en',
      );
      final price = sectionOf(views, SectionId.price);
      expect(price.available, isTrue);
      expect(price.lines, contains('Pack size: 10 tablets'));
      expect(price.lines, contains('Per pack: 20.00 BDT'));
      expect(price.lines, contains('Per unit: 2.00 BDT'));
      expect(price.lines, contains('Country: BD'));
      expect(price.lines, contains('Last verified: 2026-10-13'));
    });

    test('sources section lists each distinct source once', () {
      final views = SectionBuilder.buildAll(
        ConfirmedMedicine.userSelected(demomol250),
        all,
        'en',
      );
      final sources = sectionOf(views, SectionId.sources);
      expect(sources.available, isTrue);
      final keys = sources.sources.map((s) => s.dedupeKey).toList();
      expect(keys.length, keys.toSet().length);
    });
  });

  group('Strings and language', () {
    test('every section has a Bangla and an English title', () {
      for (final id in SectionId.values) {
        expect(Strings.has('section.${id.key}'), isTrue, reason: id.key);
        expect(Strings.section('bn', id), isNotEmpty);
        expect(Strings.section('en', id), isNotEmpty);
      }
    });

    test('the selected language is remembered', () async {
      final store = MemoryLanguageStore('bn');
      final state = AppState(lang: 'bn', store: store);
      await state.setLang('en');
      expect(state.lang, 'en');
      expect(await store.load(), 'en');
    });
  });
}
