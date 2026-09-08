import 'dart:convert';
import 'package:flutter/services.dart';

class TranslationService {
  TranslationService._();
  static final TranslationService instance = TranslationService._();

  Map<String, dynamic> _localizedStrings = {};
  String _currentLanguage = 'tr';

  String get currentLanguage => _currentLanguage;

  Future<void> loadLanguage(String langCode) async {
    _currentLanguage = langCode.toLowerCase();
    try {
      final jsonString = await rootBundle.loadString(
        'assets/translations/$_currentLanguage.json',
      );
      _localizedStrings = jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (_) {
      final fallbackString = await rootBundle.loadString(
        'assets/translations/tr.json',
      );
      _localizedStrings = jsonDecode(fallbackString) as Map<String, dynamic>;
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

    String result = current.toString();

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