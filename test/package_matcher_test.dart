import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_app/data/models.dart';
import 'package:medicine_app/logic/confirmation.dart';
import 'package:medicine_app/logic/package_matcher.dart';
import 'package:medicine_app/ocr/ocr_service.dart';

List<Medicine> loadDemo() => parseMedicines(
      File('assets/data/demo_medicines.json').readAsStringSync(),
    );

PhotoMatch run(String text, List<Medicine> all) =>
    PackageMatcher.match(OcrResult(text), all);

Medicine fake(
  String id,
  String brand, {
  String? manufacturer,
  String? form,
}) =>
    Medicine(
      id: id,
      brandName: brand,
      genericName: 'generic-$id',
      manufacturer: manufacturer,
      dosageForm: form,
      identitySource: const SourceInfo(
        name: 'test',
        lastChecked: '2026-10-13',
        verification: 'demo',
      ),
    );

void main() {
  final all = loadDemo();

  group('PackageMatcher: confident matches', () {
    test('brand, strength, form and manufacturer on the package', () {
      final r = run('AlphaDemo 10 mg Tablets\nSample Labs Ltd', all);
      expect(r.kind, PhotoMatchKind.confident);
      expect(r.candidates.first.medicine.id, 'alphademo');
    });

    test('a small OCR misreading of the brand still matches', () {
      // "AIphaDemo" (capital i instead of lowercase L) is a typical OCR slip.
      final r = run('AIphaDemo 10 mg', all);
      expect(r.kind, PhotoMatchKind.confident);
      expect(r.candidates.first.medicine.id, 'alphademo');
    });

    test('the strength printed on the package picks the right product', () {
      final r = run('DemoMol 500 mg Tablets', all);
      expect(r.kind, PhotoMatchKind.confident);
      expect(r.candidates.first.medicine.id, 'demomol-500');
    });

    test('the dosage form on the package picks the right product', () {
      final r = run('DemoMol Syrup 120 mg/5 ml', all);
      expect(r.kind, PhotoMatchKind.confident);
      expect(r.candidates.first.medicine.id, 'demomol-syrup');
    });

    test('the manufacturer separates the same brand from two makers', () {
      final meds = [
        fake('z1', 'Zolmax', manufacturer: 'Alpha Pharma'),
        fake('z2', 'Zolmax', manufacturer: 'Beta Pharma'),
      ];
      final r = run('Zolmax by Alpha Pharma', meds);
      expect(r.kind, PhotoMatchKind.confident);
      expect(r.candidates.first.medicine.id, 'z1');
    });
  });

  group('PackageMatcher: asks the user to confirm', () {
    test('brand only, several strengths: ambiguous', () {
      final r = run('DemoMol', all);
      expect(r.kind, PhotoMatchKind.ambiguous);
      final ids = r.candidates.map((c) => c.medicine.id).toSet();
      expect(ids, containsAll(['demomol-250', 'demomol-500', 'demomol-syrup']));
    });

    test('generic name shared by several brands: ambiguous', () {
      final r = run('Demo Generic B 10 mg', all);
      expect(r.kind, PhotoMatchKind.ambiguous);
      final ids = r.candidates.map((c) => c.medicine.id).toSet();
      expect(ids, containsAll(['alphademo', 'betademo']));
    });

    test('every candidate carries a confidence score', () {
      final r = run('DemoMol', all);
      for (final c in r.candidates) {
        expect(c.score, greaterThan(0.0));
        expect(c.score, lessThanOrEqualTo(1.0));
      }
    });
  });

  group('PackageMatcher: unreadable or unknown photos', () {
    test('empty text is unreadable', () {
      final r = run('', all);
      expect(r.kind, PhotoMatchKind.unreadable);
      expect(r.candidates, isEmpty);
    });

    test('only symbols is unreadable', () {
      expect(run('!! -- ##', all).kind, PhotoMatchKind.unreadable);
    });

    test('only very short fragments is unreadable', () {
      expect(run('ab\nx', all).kind, PhotoMatchKind.unreadable);
    });

    test('readable text that matches nothing is not found', () {
      final r = run('completely unrelated words here', all);
      expect(r.kind, PhotoMatchKind.notFound);
      expect(r.candidates, isEmpty);
    });

    test('very short names need an exact match', () {
      final meds = [fake('s1', 'Ab')];
      expect(run('Abc xyz', meds).kind, PhotoMatchKind.notFound);
    });

    test('the text that was read is kept for display', () {
      final r = run('  random words on a box  ', all);
      expect(r.clues.text, 'random words on a box');
    });

    test('strength and form clues are extracted', () {
      final r = run('Alpha 500mg tablets', all);
      expect(r.clues.strengths.first.value, 500);
      expect(r.clues.strengths.first.unit, 'mg');
      expect(r.clues.forms, contains('tablet'));
    });
  });

  group('PackageMatcher: identity gate', () {
    test('an ambiguous photo match cannot become a confirmed medicine', () {
      final r = run('DemoMol', all);
      expect(
        () => ConfirmedMedicine.fromMatch(r.toMatchResult(), fromPhoto: true),
        throwsStateError,
      );
    });

    test('an unreadable photo cannot become a confirmed medicine', () {
      final r = run('', all);
      expect(
        () => ConfirmedMedicine.fromMatch(r.toMatchResult(), fromPhoto: true),
        throwsStateError,
      );
    });

    test('a confident photo match becomes a confirmed medicine', () {
      final r = run('AlphaDemo 10 mg Tablets', all);
      final c = ConfirmedMedicine.fromMatch(r.toMatchResult(), fromPhoto: true);
      expect(c.medicine.id, 'alphademo');
      expect(c.fromPhoto, isTrue);
    });
  });
}
