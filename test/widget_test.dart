import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_app/app.dart';
import 'package:medicine_app/data/models.dart';
import 'package:medicine_app/data/source.dart';
import 'package:medicine_app/ocr/ocr_service.dart';
import 'package:medicine_app/state/app_state.dart';

class FailingSource implements MedicineSourceProvider {
  @override
  String get name => 'failing';

  @override
  Future<List<Medicine>> loadAll() async =>
      throw SourceUnavailableException('simulated failure');
}

class FakeImageSource implements ImageSourceService {
  FakeImageSource(this.path);

  final String? path;
  PhotoSource? lastSource;
  int calls = 0;

  @override
  Future<String?> pick(PhotoSource source) async {
    lastSource = source;
    calls++;
    return path;
  }
}

class FakeOcr implements OcrService {
  FakeOcr(this.text);

  final String text;

  @override
  Future<OcrResult> recognize(String imagePath) async => OcrResult(text);
}

class ThrowingOcr implements OcrService {
  @override
  Future<OcrResult> recognize(String imagePath) async =>
      throw OcrFailure('simulated OCR failure');
}

MedicineSourceProvider demoSource() => JsonStringMedicineSource(
      File('assets/data/demo_medicines.json').readAsStringSync(),
    );

Future<void> pumpApp(
  WidgetTester tester,
  MedicineSourceProvider source, {
  String lang = 'en',
  ImageSourceService? imageSource,
  OcrService? ocr,
}) async {
  final state = AppState(lang: lang, store: MemoryLanguageStore(lang));
  await tester.pumpWidget(
    MedicineApp(
      appState: state,
      source: source,
      imageSource: imageSource ?? FakeImageSource('/fake/photo.jpg'),
      ocr: ocr ?? FakeOcr(''),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> search(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.tap(find.byType(FilledButton));
  await tester.pumpAndSettle();
}

Future<void> takePhoto(WidgetTester tester) async {
  await tester.tap(find.text('Take photo'));
  await tester.pumpAndSettle();
}

void main() {
  group('Text search', () {
    testWidgets('complete unique name opens the full details automatically',
        (tester) async {
      await pumpApp(tester, demoSource());
      await search(tester, 'AlphaDemo');

      expect(find.text('Which one do you mean?'), findsNothing);
      expect(find.text('Direct answer'), findsNothing);
      expect(find.text('Full medicine information'), findsNothing);
      expect(find.text('Medicine identity'), findsOneWidget);
      expect(find.text('Dosage'), findsOneWidget);
      expect(
        find.text(
          'DEMO DATA: placeholder information for testing, not real medical information.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('short name with several matches asks for clarification',
        (tester) async {
      await pumpApp(tester, demoSource());
      await search(tester, 'DemoMol');

      expect(find.text('Which one do you mean?'), findsOneWidget);
      expect(find.byType(ListTile), findsNWidgets(3));
    });

    testWidgets(
        'no dosage or other details are shown before identity is confirmed',
        (tester) async {
      await pumpApp(tester, demoSource());
      await search(tester, 'DemoMol');

      expect(find.text('Dosage'), findsNothing);
      expect(find.text('Direct answer'), findsNothing);
      expect(find.text('Medicine identity'), findsNothing);
    });

    testWidgets('choosing a candidate confirms identity and opens the details',
        (tester) async {
      await pumpApp(tester, demoSource());
      await search(tester, 'DemoMol');

      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      expect(find.text('Medicine identity'), findsOneWidget);
      expect(find.text('Dosage'), findsOneWidget);
    });

    testWidgets(
        'a specific question shows the direct answer before the details',
        (tester) async {
      await pumpApp(tester, demoSource());
      await search(tester, 'DemoMol 500 mg কী কাজে লাগে?');

      final direct = find.text('Direct answer');
      final full = find.text('Full medicine information');
      expect(direct, findsOneWidget);
      expect(full, findsOneWidget);
      expect(
        tester.getTopLeft(direct).dy,
        lessThan(tester.getTopLeft(full).dy),
      );
    });

    testWidgets('missing information is shown as unavailable', (tester) async {
      await pumpApp(tester, demoSource());
      await search(tester, 'GammaDemo');

      expect(find.text('Information not available'), findsWidgets);
    });

    testWidgets('an unavailable data source shows an honest error state',
        (tester) async {
      await pumpApp(tester, FailingSource());

      expect(find.text('Could not load medicine data'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('unknown text shows the not-found state', (tester) async {
      await pumpApp(tester, demoSource());
      await search(tester, 'zzzzzz');

      expect(find.text('No medicine found'), findsOneWidget);
    });

    testWidgets('language can be switched from Bangla to English',
        (tester) async {
      await pumpApp(tester, demoSource(), lang: 'bn');
      expect(find.text('ওষুধের তথ্য'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English').last);
      await tester.pumpAndSettle();

      expect(find.text('Medicine Info'), findsOneWidget);
    });
  });

  group('Package photo', () {
    testWidgets('a clear package photo with no question opens full details',
        (tester) async {
      await pumpApp(
        tester,
        demoSource(),
        ocr: FakeOcr('AlphaDemo 10 mg Tablets\nSample Labs Ltd'),
      );
      await takePhoto(tester);

      expect(find.text('Medicine identity'), findsOneWidget);
      expect(find.text('Direct answer'), findsNothing);
      expect(find.text('Which one do you mean?'), findsNothing);
      expect(
        find.text(
          'The medicine was identified by matching text read from the photo. This does not prove that it is genuine, safe or suitable for you.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('a photo with a typed question shows the direct answer first',
        (tester) async {
      await pumpApp(
        tester,
        demoSource(),
        ocr: FakeOcr('AlphaDemo 10 mg Tablets'),
      );
      await tester.enterText(
          find.byType(TextField), 'what are the side effects?');
      await takePhoto(tester);

      final direct = find.text('Direct answer');
      final full = find.text('Full medicine information');
      expect(direct, findsOneWidget);
      expect(full, findsOneWidget);
      expect(
        tester.getTopLeft(direct).dy,
        lessThan(tester.getTopLeft(full).dy),
      );
    });

    testWidgets('a photo matching several medicines asks the user to confirm',
        (tester) async {
      await pumpApp(tester, demoSource(), ocr: FakeOcr('DemoMol'));
      await takePhoto(tester);

      expect(find.text('Which one do you mean?'), findsOneWidget);

      expect(find.textContaining('Match:'), findsNWidgets(3));
      expect(find.text('Dosage'), findsNothing);
      expect(find.text('Medicine identity'), findsNothing);
    });

    testWidgets('choosing a candidate after a photo opens the details',
        (tester) async {
      await pumpApp(tester, demoSource(), ocr: FakeOcr('DemoMol'));
      await takePhoto(tester);

      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      expect(find.text('Medicine identity'), findsOneWidget);
    });

    testWidgets('an unreadable photo asks for a clearer photo or manual input',
        (tester) async {
      await pumpApp(tester, demoSource(), ocr: FakeOcr(''));
      await takePhoto(tester);

      expect(
        find.text('Could not read the medicine name from the photo'),
        findsOneWidget,
      );
      expect(find.text('Retake photo'), findsOneWidget);
      expect(find.text('Type the name'), findsOneWidget);
      expect(find.text('Medicine identity'), findsNothing);
    });

    testWidgets('readable text that matches nothing is reported honestly',
        (tester) async {
      await pumpApp(
        tester,
        demoSource(),
        ocr: FakeOcr('completely unrelated words here'),
      );
      await takePhoto(tester);

      expect(
        find.text('No medicine matches the text in the photo'),
        findsOneWidget,
      );
      expect(find.text('Medicine identity'), findsNothing);
    });

    testWidgets('cancelling the camera or gallery changes nothing',
        (tester) async {
      final picker = FakeImageSource(null);
      await pumpApp(tester, demoSource(), imageSource: picker);
      await takePhoto(tester);

      expect(picker.calls, 1);
      expect(find.text('Could not process the photo'), findsNothing);
      expect(
        find.text('Could not read the medicine name from the photo'),
        findsNothing,
      );
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('an OCR failure shows an honest error', (tester) async {
      await pumpApp(tester, demoSource(), ocr: ThrowingOcr());
      await takePhoto(tester);

      expect(find.text('Could not process the photo'), findsOneWidget);
      expect(find.text('Medicine identity'), findsNothing);
    });

    testWidgets('the gallery button uses the gallery as the image source',
        (tester) async {
      final picker = FakeImageSource('/fake/photo.jpg');
      await pumpApp(
        tester,
        demoSource(),
        imageSource: picker,
        ocr: FakeOcr('completely unrelated words here'),
      );
      await tester.tap(find.text('Choose from gallery'));
      await tester.pumpAndSettle();

      expect(picker.lastSource, PhotoSource.gallery);
    });

    testWidgets('the camera button uses the camera as the image source',
        (tester) async {
      final picker = FakeImageSource('/fake/photo.jpg');
      await pumpApp(
        tester,
        demoSource(),
        imageSource: picker,
        ocr: FakeOcr('completely unrelated words here'),
      );
      await takePhoto(tester);

      expect(picker.lastSource, PhotoSource.camera);
    });
  });
}
