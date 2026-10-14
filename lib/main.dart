import 'package:flutter/material.dart';
import 'package:medicine_app/app.dart';
import 'package:medicine_app/data/source.dart';
import 'package:medicine_app/ocr/platform_services.dart';
import 'package:medicine_app/state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = SharedPrefsLanguageStore();
  final lang = await store.load();
  runApp(
    MedicineApp(
      appState: AppState(lang: lang, store: store),
      source: AssetMedicineSource(),
      imageSource: ImagePickerService(),
      ocr: MlKitOcrService(),
    ),
  );
}
