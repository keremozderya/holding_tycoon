import 'dart:convert';
import 'package:flutter/services.dart';

class TranslationService {
  TranslationService._();
  static final TranslationService instance = TranslationService._();

  Map<String, dynamic> _localizedStrings = {};
  String _currentLanguage = 'tr';
  int _loadGeneration = 0;

  static const supportedLanguages = <String>{'tr', 'en', 'de', 'es', 'fr', 'it'};

  String get currentLanguage => _currentLanguage;

  Future<void> loadLanguage(String langCode) async {
    final requested = langCode.toLowerCase();
    final language = supportedLanguages.contains(requested) ? requested : 'tr';
    final generation = ++_loadGeneration;
    try {
      final jsonString = await rootBundle.loadString(
        'assets/translations/$language.json',
      );
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) throw const FormatException('Translation root must be an object');
      if (generation == _loadGeneration) {
        _localizedStrings = decoded;
        _currentLanguage = language;
      }
    } catch (_) {
      try {
        final fallbackString = await rootBundle.loadString('assets/translations/tr.json');
        final decoded = jsonDecode(fallbackString);
        if (generation == _loadGeneration && decoded is Map<String, dynamic>) {
          _localizedStrings = decoded;
          _currentLanguage = 'tr';
        }
      } catch (_) {
        if (generation == _loadGeneration) {
          _localizedStrings = <String, dynamic>{};
          _currentLanguage = 'tr';
        }
      }
    }
  }

  String translate(String key, {Map<String, String>? params}) {
    final keys = key.split('.');
    dynamic current = _localizedStrings;

    for (final k in keys) {
      if (current is Map<String, dynamic> && current.containsKey(k)) {
        current = current[k];
      } else {
        return key;
      }
    }

    if (current is! String) return key;
    String result = current;

    if (params != null) {
      params.forEach((paramKey, value) {
        result = result.replaceAll('{$paramKey}', value);
      });
    }

    return result;
  }
}

extension TranslationExtension on String {
  String tr({Map<String, String>? params}) {
    return TranslationService.instance.translate(this, params: params);
  }
}
