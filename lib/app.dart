import 'package:flutter/material.dart';
import 'package:medicine_app/core/strings.dart';
import 'package:medicine_app/data/source.dart';
import 'package:medicine_app/ocr/ocr_service.dart';
import 'package:medicine_app/state/app_state.dart';
import 'package:medicine_app/ui/home_screen.dart';

class MedicineApp extends StatelessWidget {
  const MedicineApp({
    super.key,
    required this.appState,
    required this.source,
    required this.imageSource,
    required this.ocr,
  });

  final AppState appState;
  final MedicineSourceProvider source;
  final ImageSourceService imageSource;
  final OcrService ocr;

  static const Color _seed = Color(0xFF00796B);

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: appState,
      child: Builder(
        builder: (context) {
          final lang = AppScope.of(context).lang;
          return MaterialApp(
            title: Strings.t(lang, 'app.title'),
            debugShowCheckedModeBanner: false,
            themeMode: ThemeMode.system,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: _seed),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: _seed,
                brightness: Brightness.dark,
              ),
            ),
            home: HomeScreen(
              source: source,
              imageSource: imageSource,
              ocr: ocr,
            ),
          );
        },
      ),
    );
  }
}
