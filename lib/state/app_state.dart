import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where the selected language is remembered.
abstract class LanguageStore {
  Future<String> load();
  Future<void> save(String lang);
}

class SharedPrefsLanguageStore implements LanguageStore {
  static const String _key = 'app_language';

  @override
  Future<String> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(_key);
      return (value == 'en' || value == 'bn') ? value! : 'bn';
    } catch (_) {
      return 'bn';
    }
  }

  @override
  Future<void> save(String lang) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, lang);
    } catch (_) {
      // Remembering the language is a convenience; ignore storage failures.
    }
  }
}

/// In-memory store, used by tests.
class MemoryLanguageStore implements LanguageStore {
  MemoryLanguageStore([this._value = 'bn']);

  String _value;

  @override
  Future<String> load() async => _value;

  @override
  Future<void> save(String lang) async => _value = lang;
}

class AppState extends ChangeNotifier {
  AppState({required String lang, required LanguageStore store})
      : _lang = lang,
        _store = store;

  String _lang;
  final LanguageStore _store;

  /// 'bn' or 'en'.
  String get lang => _lang;

  Future<void> setLang(String value) async {
    if (value == _lang) return;
    _lang = value;
    notifyListeners();
    await _store.save(value);
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({
    super.key,
    required AppState state,
    required super.child,
  }) : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in the widget tree');
    return scope!.notifier!;
  }
}
