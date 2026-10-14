import 'package:medicine_app/core/sections.dart';
import 'package:medicine_app/core/text_utils.dart';

/// What we understood from the text the user typed.
class ParsedQuery {
  const ParsedQuery({
    required this.raw,
    required this.nameText,
    this.strength,
    this.formHint,
    this.intent,
    required this.looksLikeQuestion,
  });

  /// The exact text the user typed.
  final String raw;

  /// The medicine-name part, after removing question words, strength and form.
  final String nameText;

  final Strength? strength;

  /// Canonical dosage form such as 'tablet' or 'syrup', if the user wrote one.
  final String? formHint;

  /// The section the user's question is about, if we recognised it.
  final SectionId? intent;

  final bool looksLikeQuestion;
}

class QueryParser {
  static const Map<SectionId, List<String>> _intentKeywords = {
    SectionId.uses: [
      'কী কাজে',
      'কি কাজে',
      'কাজে লাগে',
      'ব্যবহার',
      'what is it used for',
      'what is this for',
      'used for',
      'uses',
    ],
    SectionId.directions: [
      'কীভাবে খাব',
      'কিভাবে খাব',
      'কিভাবে গ্রহণ',
      'খাবারের আগে',
      'খাবারের পরে',
      'before food',
      'after food',
      'before meal',
      'after meal',
      'how to take',
      'how do i take',
      'directions',
    ],
    SectionId.dosage: ['ডোজ', 'dosage', 'dose'],
    SectionId.contraindications: [
      'কখন খাওয়া যাবে না',
      'ব্যবহার করা যাবে না',
      'contraindication',
      'who should not',
    ],
    SectionId.sideEffects: [
      'পার্শ্বপ্রতিক্রিয়া',
      'পার্শ্ব প্রতিক্রিয়া',
      'side effects',
      'side effect',
    ],
    SectionId.warnings: ['সতর্কতা', 'warning', 'precaution'],
    SectionId.overdose: ['ওভারডোজ', 'overdose'],
    SectionId.pregnancy: [
      'গর্ভাবস্থা',
      'গর্ভ',
      'স্তন্যদান',
      'pregnan',
      'breastfeed',
    ],
    SectionId.price: ['দাম', 'মূল্য', 'how much', 'price', 'cost'],
    SectionId.mechanism: [
      'কীভাবে কাজ করে',
      'কিভাবে কাজ করে',
      'how does it work',
      'mechanism',
    ],
    SectionId.interactions: ['পারস্পরিক প্রতিক্রিয়া', 'interaction'],
    SectionId.pediatric: ['শিশু', 'pediatric', 'paediatric', 'child'],
    SectionId.geriatric: ['বয়স্ক', 'geriatric', 'elderly'],
    SectionId.kidney: ['কিডনি', 'kidney', 'renal'],
    SectionId.liver: ['লিভার', 'liver', 'hepatic'],
    SectionId.alternatives: ['বিকল্প', 'alternative', 'substitute'],
    SectionId.storage: ['সংরক্ষণ', 'storage'],
    SectionId.expiry: ['মেয়াদ', 'expiry', 'expire'],
  };

  static const Set<String> _stopWords = {
    'কী',
    'কি',
    'কে',
    'কোন',
    'এই',
    'এটি',
    'এর',
    'ওষুধ',
    'ওষুধটি',
    'ওষুধের',
    'নাকি',
    'পরে',
    'আগে',
    'what',
    'is',
    'the',
    'of',
    'for',
    'this',
    'that',
    'are',
    'does',
    'it',
    'how',
    'much',
    'do',
    'i',
    'to',
    'an',
    'me',
    'tell',
    'about',
    'medicine',
    'drug',
    'please',
  };

  static const Map<String, String> _formWords = {
    'tablet': 'tablet',
    'ট্যাবলেট': 'tablet',
    'capsule': 'capsule',
    'ক্যাপসুল': 'capsule',
    'syrup': 'syrup',
    'সিরাপ': 'syrup',
    'suspension': 'suspension',
    'injection': 'injection',
    'ইনজেকশন': 'injection',
    'drops': 'drops',
    'cream': 'cream',
    'ointment': 'ointment',
  };

  /// Longest keywords first, so "ব্যবহার করা যাবে না" wins over "ব্যবহার".
  static final List<MapEntry<String, SectionId>> _keywords = _buildKeywords();

  static List<MapEntry<String, SectionId>> _buildKeywords() {
    final list = <MapEntry<String, SectionId>>[];
    _intentKeywords.forEach((id, words) {
      for (final w in words) {
        list.add(MapEntry(w, id));
      }
    });
    list.sort((a, b) => b.key.length.compareTo(a.key.length));
    return list;
  }

  static ParsedQuery parse(String raw) {
    var work = raw.toLowerCase();

    SectionId? intent;
    for (final entry in _keywords) {
      if (work.contains(entry.key)) {
        intent ??= entry.value;
        work = work.replaceAll(entry.key, ' ');
      }
    }

    Strength? strength;
    final m = strengthRegex.firstMatch(work);
    if (m != null) {
      strength = Strength(double.parse(m.group(1)!), m.group(2)!.toLowerCase());
      work = work.replaceFirst(strengthRegex, ' ');
    }

    String? form;
    final nameTokens = <String>[];
    for (final token in normalizeText(work).split(' ')) {
      if (token.isEmpty) continue;
      if (_stopWords.contains(token)) continue;
      final f = _formWords[token];
      if (f != null) {
        form ??= f;
        continue;
      }
      nameTokens.add(token);
    }

    return ParsedQuery(
      raw: raw,
      nameText: nameTokens.join(' '),
      strength: strength,
      formHint: form,
      intent: intent,
      looksLikeQuestion: intent != null || raw.contains('?'),
    );
  }
}
