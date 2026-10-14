import 'sections.dart';

/// Simple bilingual string table (Bangla = 'bn', English = 'en').
class Strings {
  static String t(String lang, String key) {
    final entry = _all[key];
    if (entry == null) return key;
    return entry[lang] ?? entry['en'] ?? key;
  }

  static bool has(String key) => _all.containsKey(key);

  static String section(String lang, SectionId id) =>
      t(lang, 'section.${id.key}');

  static const Map<String, Map<String, String>> _all = {
    'app.title': {'bn': 'ওষুধের তথ্য', 'en': 'Medicine Info'},
    'language': {'bn': 'ভাষা', 'en': 'Language'},
    'lang.bn': {'bn': 'বাংলা', 'en': 'বাংলা (Bangla)'},
    'lang.en': {'bn': 'English', 'en': 'English'},
    'search.hint': {
      'bn': 'ওষুধের নাম লিখুন (যেমন: DemoMol 500 mg)',
      'en': 'Type a medicine name (e.g. DemoMol 500 mg)',
    },
    'search.button': {'bn': 'খুঁজুন', 'en': 'Search'},
    'loading': {'bn': 'লোড হচ্ছে...', 'en': 'Loading...'},
    'demo.banner': {
      'bn': 'ডেমো ডেটা: এটি পরীক্ষামূলক তথ্য, আসল চিকিৎসা তথ্য নয়।',
      'en':
          'DEMO DATA: placeholder information for testing, not real medical information.',
    },
    'disclaimer': {
      'bn':
          'এটি সাধারণ ওষুধ-তথ্য, ব্যক্তিগত চিকিৎসা পরামর্শ নয়। ওষুধ শুরু, বন্ধ বা পরিবর্তন করার আগে ডাক্তার বা ফার্মাসিস্টের সাথে কথা বলুন।',
      'en':
          'This is general medicine information, not personal medical advice. Talk to a doctor or pharmacist before starting, stopping or changing any medicine.',
    },
    'error.title': {
      'bn': 'ডেটা লোড করা যায়নি',
      'en': 'Could not load medicine data',
    },
    'error.body': {
      'bn':
          'ওষুধের ডেটা উৎস এখন পাওয়া যাচ্ছে না। কোনো তথ্য অনুমান করে দেখানো হবে না।',
      'en':
          'The medicine data source is not available right now. No information will be guessed or filled in.',
    },
    'retry': {'bn': 'আবার চেষ্টা করুন', 'en': 'Retry'},
    'clarify.title': {
      'bn': 'আপনি কোনটি বোঝাতে চেয়েছেন?',
      'en': 'Which one do you mean?',
    },
    'clarify.single': {
      'bn': 'মিল নিশ্চিত নয়। এটিই কি আপনার ওষুধ?',
      'en': 'The match is uncertain. Is this your medicine?',
    },
    'clarify.body': {
      'bn': 'নিশ্চিত করার জন্য একটি বেছে নিন।',
      'en': 'Please choose one to confirm.',
    },
    'notfound.title': {
      'bn': 'কোনো ওষুধ পাওয়া যায়নি',
      'en': 'No medicine found',
    },
    'notfound.body': {
      'bn': 'নামের বানান পরীক্ষা করুন বা জেনেরিক নাম দিয়ে খুঁজুন।',
      'en': 'Check the spelling or try searching by generic name.',
    },
    'details.question': {'bn': 'আপনার প্রশ্ন', 'en': 'Your question'},
    'details.direct': {'bn': 'সরাসরি উত্তর', 'en': 'Direct answer'},
    'details.full': {
      'bn': 'ওষুধের সম্পূর্ণ তথ্য',
      'en': 'Full medicine information',
    },
    'details.noIntent': {
      'bn':
          'আপনার প্রশ্নটি Smart Medicine Mode কোনো নির্দিষ্ট বিভাগের সাথে মেলাতে পারেনি। নিচে সম্পূর্ণ তথ্য দেখুন।',
      'en':
          'Smart Medicine Mode could not match your question to a specific section. See the full information below.',
    },
    'info.na': {
      'bn': 'তথ্য পাওয়া যায়নি',
      'en': 'Information not available',
    },
    'source.label': {'bn': 'উৎস', 'en': 'Source'},
    'source.open': {'bn': 'মূল পেজ খুলুন', 'en': 'Open original page'},
    'source.openFailed': {
      'bn': 'লিংকটি খোলা যায়নি',
      'en': 'Could not open the link',
    },
    'source.lastChecked': {'bn': 'সর্বশেষ যাচাই', 'en': 'Last checked'},
    'source.verification': {'bn': 'যাচাই অবস্থা', 'en': 'Verification'},
    'source.computed': {
      'bn': 'স্থানীয় রেকর্ড থেকে হিসাব করা',
      'en': 'Computed from local records',
    },
    'verification.demo': {'bn': 'ডেমো (যাচাইকৃত নয়)', 'en': 'Demo (not verified)'},
    'verification.unverified': {'bn': 'যাচাই হয়নি', 'en': 'Unverified'},
    'verification.verified': {'bn': 'যাচাইকৃত', 'en': 'Verified'},
    'dosage.note': {
      'bn': 'এটি সাধারণ রেফারেন্স, ব্যক্তিগত প্রেসক্রিপশন নয়।',
      'en': 'This is a general reference, not a personal prescription.',
    },
    'overdose.emergency': {
      'bn':
          'অতিরিক্ত ডোজ বা গুরুতর প্রতিক্রিয়ার সন্দেহ হলে এখনই জরুরি চিকিৎসা সহায়তা নিন বা স্থানীয় জরুরি সেবায় যোগাযোগ করুন।',
      'en':
          'If an overdose or a serious reaction is suspected, get urgent medical help now or contact local emergency services.',
    },
    'expiry.note': {
      'bn':
          'মেয়াদের তারিখ নির্দিষ্ট প্যাকেটের উপর নির্ভর করে। এই ডেটায় প্যাকেট-নির্দিষ্ট তথ্য নেই।',
      'en':
          'Expiry depends on the specific package. This data has no package-specific information.',
    },
    'alternatives.note': {
      'bn': 'একই উপাদান, শক্তি ও ধরন মিলিয়ে স্থানীয় ডেটা থেকে হিসাব করা।',
      'en':
          'Computed from local data by matching ingredient, strength and dosage form.',
    },
    'identity.brand': {'bn': 'ব্র্যান্ড', 'en': 'Brand'},
    'identity.generic': {'bn': 'জেনেরিক নাম', 'en': 'Generic name'},
    'identity.ingredients': {'bn': 'উপাদান', 'en': 'Active ingredients'},
    'identity.strength': {'bn': 'শক্তি', 'en': 'Strength'},
    'identity.form': {'bn': 'ধরন', 'en': 'Dosage form'},
    'identity.manufacturer': {'bn': 'প্রস্তুতকারক', 'en': 'Manufacturer'},
    'price.pack': {'bn': 'প্যাক সাইজ', 'en': 'Pack size'},
    'price.perPack': {'bn': 'প্রতি প্যাক', 'en': 'Per pack'},
    'price.perUnit': {'bn': 'প্রতি পিস', 'en': 'Per unit'},
    'price.country': {'bn': 'দেশ', 'en': 'Country'},
    'price.verifiedOn': {'bn': 'যাচাইয়ের তারিখ', 'en': 'Last verified'},
    'section.identity': {'bn': 'ওষুধের পরিচিতি', 'en': 'Medicine identity'},
    'section.uses': {'bn': 'ব্যবহারসমূহ', 'en': 'Uses'},
    'section.directions': {
      'bn': 'আমি কীভাবে এটি গ্রহণ করব?',
      'en': 'How should I take it?',
    },
    'section.dosage': {'bn': 'ডোজ', 'en': 'Dosage'},
    'section.contraindications': {
      'bn': 'যেসব ক্ষেত্রে ব্যবহার করা যাবে না',
      'en': 'When it must not be used',
    },
    'section.sideEffects': {'bn': 'পার্শ্বপ্রতিক্রিয়া', 'en': 'Side effects'},
    'section.warnings': {
      'bn': 'সতর্কতা ও সতর্কবাণী',
      'en': 'Warnings and precautions',
    },
    'section.overdose': {'bn': 'ওভারডোজ', 'en': 'Overdose'},
    'section.pregnancy': {
      'bn': 'গর্ভাবস্থায় ও স্তন্যদানকালে ব্যবহার',
      'en': 'Pregnancy and breastfeeding',
    },
    'section.price': {
      'bn': 'প্যাক সাইজ ও প্রতি পিসের দাম',
      'en': 'Pack size and price per unit',
    },
    'section.composition': {
      'bn': 'উপাদান ও শক্তি',
      'en': 'Composition and strength',
    },
    'section.mechanism': {'bn': 'কীভাবে কাজ করে', 'en': 'How it works'},
    'section.interactions': {
      'bn': 'ওষুধের পারস্পরিক প্রতিক্রিয়া',
      'en': 'Drug interactions',
    },
    'section.pediatric': {
      'bn': 'শিশুদের ক্ষেত্রে ব্যবহার',
      'en': 'Use in children',
    },
    'section.geriatric': {
      'bn': 'বয়স্কদের ক্ষেত্রে ব্যবহার',
      'en': 'Use in the elderly',
    },
    'section.kidney': {
      'bn': 'কিডনির সমস্যায় সতর্কতা',
      'en': 'Kidney-related cautions',
    },
    'section.liver': {
      'bn': 'লিভারের সমস্যায় সতর্কতা',
      'en': 'Liver-related cautions',
    },
    'section.alternatives': {'bn': 'বিকল্প ব্র্যান্ড', 'en': 'Alternative brands'},
    'section.storage': {'bn': 'সংরক্ষণবিধি', 'en': 'Storage instructions'},
    'section.expiry': {
      'bn': 'মেয়াদোত্তীর্ণের তথ্য',
      'en': 'Expiry information',
    },
    'section.prescription': {
      'bn': 'প্রেসক্রিপশন ব্যাখ্যা',
      'en': 'Prescription explanation',
    },
    'section.sources': {'bn': 'তথ্যের উৎস', 'en': 'Information sources'},
    'photo.take': {'bn': 'ছবি তুলুন', 'en': 'Take photo'},
    'photo.gallery': {'bn': 'গ্যালারি থেকে', 'en': 'Choose from gallery'},
    'photo.reading': {
      'bn': 'ছবি থেকে লেখা পড়া হচ্ছে...',
      'en': 'Reading the photo...',
    },
    'photo.unreadable.title': {
      'bn': 'ছবি থেকে ওষুধের নাম পড়া যায়নি',
      'en': 'Could not read the medicine name from the photo',
    },
    'photo.unreadable.body': {
      'bn':
          'ছবিটি ঝাপসা বা অসম্পূর্ণ হতে পারে। ভালো আলোতে ওষুধের নামের লেখা কাছ থেকে আবার তুলুন, অথবা নাম হাতে লিখুন।',
      'en':
          'The photo may be blurry or incomplete. Retake it in good light, close to the name on the package, or type the name instead.',
    },
    'photo.retake': {'bn': 'আবার ছবি তুলুন', 'en': 'Retake photo'},
    'photo.typeName': {'bn': 'নাম লিখুন', 'en': 'Type the name'},
    'photo.notfound.title': {
      'bn': 'ছবির লেখার সাথে কোনো ওষুধ মেলেনি',
      'en': 'No medicine matches the text in the photo',
    },
    'photo.notfound.body': {
      'bn':
          'পড়া লেখা নিচে দেখুন। নাম হাতে লিখে খুঁজুন অথবা আরও স্পষ্ট ছবি তুলুন।',
      'en':
          'See the text that was read below. Search by typing the name or take a clearer photo.',
    },
    'photo.ambiguous.note': {
      'bn':
          'ছবির লেখা থেকে একাধিক সম্ভাব্য ওষুধ মিলেছে। নিশ্চিত করার জন্য সঠিকটি বেছে নিন।',
      'en':
          'The text in the photo matched more than one possible medicine. Choose the right one to confirm.',
    },
    'photo.match': {'bn': 'মিল', 'en': 'Match'},
    'photo.readText': {
      'bn': 'ছবি থেকে যা পড়া হয়েছে',
      'en': 'Text read from the photo',
    },
    'photo.noAuthenticity': {
      'bn':
          'ছবির লেখা মিলিয়ে ওষুধ চেনা হয়েছে। এতে ওষুধটি আসল, নিরাপদ বা আপনার জন্য উপযুক্ত কি না তা প্রমাণ হয় না।',
      'en':
          'The medicine was identified by matching text read from the photo. This does not prove that it is genuine, safe or suitable for you.',
    },
    'photo.error.title': {
      'bn': 'ছবিটি প্রক্রিয়া করা যায়নি',
      'en': 'Could not process the photo',
    },
    'photo.error.body': {
      'bn':
          'ক্যামেরা খোলা বা ছবি পড়ার সময় সমস্যা হয়েছে। আবার চেষ্টা করুন অথবা নাম হাতে লিখুন।',
      'en':
          'Something went wrong while opening the camera or reading the photo. Try again or type the name.',
    },
  };
}
