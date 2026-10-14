import 'package:flutter/services.dart' show rootBundle;
import 'package:medicine_app/data/models.dart';

/// Every data source (demo file, official dataset, licensed API...) implements
/// this interface. Replace the provider without touching the UI or the matcher.
abstract class MedicineSourceProvider {
  String get name;

  /// Throws [SourceUnavailableException] when the data cannot be read.
  Future<List<Medicine>> loadAll();
}

/// Reads the bundled demo dataset from the app assets.
class AssetMedicineSource implements MedicineSourceProvider {
  AssetMedicineSource({this.assetPath = 'assets/data/demo_medicines.json'});

  final String assetPath;

  @override
  String get name => 'Bundled demo dataset';

  @override
  Future<List<Medicine>> loadAll() async {
    final String text;
    try {
      text = await rootBundle.loadString(assetPath);
    } catch (e) {
      throw SourceUnavailableException('Could not read $assetPath: $e');
    }
    return parseMedicines(text);
  }
}

/// Reads medicines from a JSON string (used by tests).
class JsonStringMedicineSource implements MedicineSourceProvider {
  JsonStringMedicineSource(this.json);

  final String json;

  @override
  String get name => 'JSON string';

  @override
  Future<List<Medicine>> loadAll() async => parseMedicines(json);
}

/// Loads once and keeps the result in memory.
class MedicineRepository {
  MedicineRepository(this._provider);

  final MedicineSourceProvider _provider;
  List<Medicine>? _cache;

  Future<List<Medicine>> all() async {
    final cached = _cache;
    if (cached != null) return cached;
    final loaded = await _provider.loadAll();
    _cache = loaded;
    return loaded;
  }

  void reset() => _cache = null;
}
