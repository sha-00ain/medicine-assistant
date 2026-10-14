import 'dart:convert';

import 'package:medicine_app/core/sections.dart';

/// Thrown when a data source cannot be read. The UI shows an honest error.
class SourceUnavailableException implements Exception {
  SourceUnavailableException(this.message);

  final String message;

  @override
  String toString() => 'SourceUnavailableException: $message';
}

class LocalizedText {
  const LocalizedText({required this.bn, required this.en});

  final String bn;
  final String en;

  String of(String lang) => lang == 'bn' ? bn : en;

  factory LocalizedText.fromJson(Map<String, dynamic> j) => LocalizedText(
        bn: (j['bn'] ?? '') as String,
        en: (j['en'] ?? '') as String,
      );
}

class SourceInfo {
  const SourceInfo({
    required this.name,
    this.url,
    required this.lastChecked,
    required this.verification,
  });

  final String name;
  final String? url;
  final String lastChecked;

  /// 'demo', 'unverified' or 'verified'.
  final String verification;

  String get dedupeKey => '$name|${url ?? ''}';

  factory SourceInfo.fromJson(Map<String, dynamic> j) => SourceInfo(
        name: (j['name'] ?? '') as String,
        url: j['url'] as String?,
        lastChecked: (j['lastChecked'] ?? '') as String,
        verification: (j['verification'] ?? 'unverified') as String,
      );
}

class SectionData {
  const SectionData({required this.text, required this.source});

  final LocalizedText text;
  final SourceInfo source;

  factory SectionData.fromJson(Map<String, dynamic> j) => SectionData(
        text: LocalizedText.fromJson(j['text'] as Map<String, dynamic>),
        source: SourceInfo.fromJson(j['source'] as Map<String, dynamic>),
      );
}

class PriceInfo {
  const PriceInfo({
    required this.amount,
    required this.currency,
    required this.country,
    required this.packSize,
    this.unitCount,
    required this.lastVerified,
    required this.source,
  });

  final double amount;
  final String currency;
  final String country;
  final String packSize;
  final int? unitCount;
  final String lastVerified;
  final SourceInfo source;

  double? get perUnit {
    final n = unitCount;
    if (n == null || n <= 0) return null;
    return amount / n;
  }

  factory PriceInfo.fromJson(Map<String, dynamic> j) => PriceInfo(
        amount: (j['amount'] as num).toDouble(),
        currency: j['currency'] as String,
        country: j['country'] as String,
        packSize: j['packSize'] as String,
        unitCount: j['unitCount'] as int?,
        lastVerified: j['lastVerified'] as String,
        source: SourceInfo.fromJson(j['source'] as Map<String, dynamic>),
      );
}

class Medicine {
  const Medicine({
    required this.id,
    required this.brandName,
    this.aliases = const [],
    required this.genericName,
    this.ingredients = const [],
    this.strength,
    this.dosageForm,
    this.manufacturer,
    this.isDemo = false,
    required this.identitySource,
    this.sections = const {},
    this.price,
  });

  final String id;
  final String brandName;
  final List<String> aliases;
  final String genericName;
  final List<String> ingredients;
  final String? strength;
  final String? dosageForm;
  final String? manufacturer;
  final bool isDemo;
  final SourceInfo identitySource;
  final Map<SectionId, SectionData> sections;
  final PriceInfo? price;

  factory Medicine.fromJson(Map<String, dynamic> j) {
    final sections = <SectionId, SectionData>{};
    final raw = (j['sections'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    raw.forEach((key, value) {
      final id = SectionId.fromKey(key);
      if (id != null) {
        sections[id] = SectionData.fromJson(value as Map<String, dynamic>);
      }
    });
    return Medicine(
      id: j['id'] as String,
      brandName: j['brandName'] as String,
      aliases: ((j['aliases'] as List<dynamic>?) ?? <dynamic>[])
          .map((e) => e as String)
          .toList(),
      genericName: (j['genericName'] ?? '') as String,
      ingredients: ((j['ingredients'] as List<dynamic>?) ?? <dynamic>[])
          .map((e) => e as String)
          .toList(),
      strength: j['strength'] as String?,
      dosageForm: j['dosageForm'] as String?,
      manufacturer: j['manufacturer'] as String?,
      isDemo: (j['isDemo'] ?? false) as bool,
      identitySource:
          SourceInfo.fromJson(j['identitySource'] as Map<String, dynamic>),
      sections: sections,
      price: j['price'] == null
          ? null
          : PriceInfo.fromJson(j['price'] as Map<String, dynamic>),
    );
  }
}

/// Parses the JSON text of a medicine data file.
List<Medicine> parseMedicines(String source) {
  try {
    final root = jsonDecode(source) as Map<String, dynamic>;
    final list = root['medicines'] as List<dynamic>;
    return list
        .map((e) => Medicine.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e) {
    throw SourceUnavailableException('Invalid data format: $e');
  }
}
