// lib/services/translation_service.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class TranslationService extends ChangeNotifier {
  TranslationService._();

  static final TranslationService instance = TranslationService._();

  static const Set<String> supportedLanguages = <String>{
    'tr',
    'en',
    'de',
    'es',
    'fr',
    'it',
  };

  Map<String, dynamic> _localizedStrings = <String, dynamic>{};
  Map<String, dynamic> _englishFallbackStrings = <String, dynamic>{};
  Map<String, dynamic> _turkishFallbackStrings = <String, dynamic>{};

  Map<String, String> _foldedLiterals = <String, String>{};
  Map<String, String> _englishFoldedLiterals = <String, String>{};
  List<_LiteralPattern> _literalPatterns = <_LiteralPattern>[];
  List<_LiteralPattern> _englishLiteralPatterns = <_LiteralPattern>[];

  String _currentLanguage = 'tr';
  int _loadGeneration = 0;

  String get currentLanguage => _currentLanguage;

  Future<Map<String, dynamic>> _readJson(String code) async {
    final raw = await rootBundle.loadString('assets/translations/$code.json');
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Translation root must be a JSON object.');
    }
    return decoded;
  }

  Future<void> loadLanguage(String langCode) async {
    final requested = langCode.toLowerCase();
    final language = supportedLanguages.contains(requested) ? requested : 'tr';
    final generation = ++_loadGeneration;

    Map<String, dynamic> tr = <String, dynamic>{};
    Map<String, dynamic> en = <String, dynamic>{};
    Map<String, dynamic> selected = <String, dynamic>{};

    try {
      tr = await _readJson('tr');
    } catch (error) {
      debugPrint('Turkish translation fallback could not be loaded: $error');
    }

    try {
      en = language == 'tr' ? <String, dynamic>{} : await _readJson('en');
    } catch (error) {
      debugPrint('English translation fallback could not be loaded: $error');
    }

    try {
      selected = language == 'tr'
          ? tr
          : language == 'en'
              ? en
              : await _readJson(language);
    } catch (error) {
      debugPrint('$language translation could not be loaded: $error');
      selected = en.isNotEmpty ? en : tr;
    }

    if (generation != _loadGeneration) return;

    _turkishFallbackStrings = tr;
    _englishFallbackStrings = en;
    _localizedStrings = selected;
    _currentLanguage =
        selected.isEmpty && language != 'tr' ? 'tr' : language;

    _foldedLiterals = _compileFoldedLiterals(selected['literals']);
    _englishFoldedLiterals = _compileFoldedLiterals(en['literals']);
    _literalPatterns = _compileLiteralPatterns(selected['patterns']);
    _englishLiteralPatterns = _compileLiteralPatterns(en['patterns']);

    notifyListeners();
  }

  dynamic _lookup(Map<String, dynamic> root, String key) {
    dynamic current = root;
    for (final part in key.split('.')) {
      if (current is Map<String, dynamic> && current.containsKey(part)) {
        current = current[part];
        continue;
      }

      if (current is List<dynamic>) {
        final index = int.tryParse(part);
        if (index != null && index >= 0 && index < current.length) {
          current = current[index];
          continue;
        }
      }

      return null;
    }
    return current;
  }

  String factoryName(
    String factoryId, {
    required String fallback,
  }) {
    return translate(
      'factory_catalog.$factoryId.name',
      fallback: translateLiteral(fallback),
    );
  }

  String productName(
    String factoryId,
    int productIndex, {
    required String fallback,
  }) {
    return translate(
      'factory_catalog.$factoryId.products.$productIndex',
      fallback: translateLiteral(fallback),
    );
  }

  String translate(
    String key, {
    Map<String, String>? params,
    String? fallback,
  }) {
    dynamic value = _lookup(_localizedStrings, key);
    value ??= _lookup(_englishFallbackStrings, key);
    value ??= _lookup(_turkishFallbackStrings, key);

    if (value is! String) return fallback ?? key;
    return _applyParams(value, params);
  }

  /// Translates legacy/raw UI strings through JSON.
  ///
  /// This is intentionally supported during the migration so every existing
  /// screen can become language-aware without maintaining a second hard-coded
  /// translation table in Dart.
  String translateLiteral(String source) {
    if (source.isEmpty) return source;

    final selected = _literalLookup(
      source,
      _localizedStrings['literals'],
      _foldedLiterals,
    );
    if (selected != null) return selected;

    for (final pattern in _literalPatterns) {
      final translated = pattern.tryTranslate(source, translateLiteral);
      if (translated != null) return translated;
    }

    final english = _literalLookup(
      source,
      _englishFallbackStrings['literals'],
      _englishFoldedLiterals,
    );
    if (english != null) return english;

    for (final pattern in _englishLiteralPatterns) {
      final translated = pattern.tryTranslate(source, translateLiteral);
      if (translated != null) return translated;
    }

    // Turkish is the canonical source language. Missing keys never leak JSON
    // identifiers or crash the UI.
    return source;
  }

  String? _literalLookup(
    String source,
    dynamic rawMap,
    Map<String, String> folded,
  ) {
    if (rawMap is Map<String, dynamic>) {
      final exact = rawMap[source];
      if (exact is String) return _preserveCaseShape(source, exact);
    }

    final value = folded[source.toLowerCase()];
    if (value == null) return null;
    return _preserveCaseShape(source, value);
  }

  Map<String, String> _compileFoldedLiterals(dynamic source) {
    if (source is! Map<String, dynamic>) return <String, String>{};

    final result = <String, String>{};
    for (final entry in source.entries) {
      if (entry.value is String) {
        result[entry.key.toLowerCase()] = entry.value as String;
      }
    }
    return result;
  }

  String _preserveCaseShape(String source, String translated) {
    if (source == source.toUpperCase()) return translated.toUpperCase();
    return translated;
  }

  String _applyParams(String value, Map<String, String>? params) {
    var result = value;
    if (params == null) return result;

    for (final entry in params.entries) {
      result = result.replaceAll('{${entry.key}}', entry.value);
    }
    return result;
  }

  List<_LiteralPattern> _compileLiteralPatterns(dynamic source) {
    if (source is! Map<String, dynamic>) return <_LiteralPattern>[];

    final result = <_LiteralPattern>[];
    for (final entry in source.entries) {
      if (entry.value is String) {
        result.add(_LiteralPattern(entry.key, entry.value as String));
      }
    }

    // More specific patterns should win before short/general templates.
    result.sort(
      (a, b) => b.sourceTemplate.length.compareTo(a.sourceTemplate.length),
    );
    return result;
  }
}

class _LiteralPattern {
  _LiteralPattern(this.sourceTemplate, this.targetTemplate) {
    final placeholder = RegExp(r'\{([A-Za-z0-9_]+)\}');
    final names = <String>[];
    final buffer = StringBuffer('^');
    var cursor = 0;

    for (final match in placeholder.allMatches(sourceTemplate)) {
      buffer.write(
        RegExp.escape(sourceTemplate.substring(cursor, match.start)),
      );
      buffer.write(r'(.+?)');
      names.add(match.group(1)!);
      cursor = match.end;
    }

    buffer.write(RegExp.escape(sourceTemplate.substring(cursor)));
    buffer.write(r'$');

    _names = names;
    _regex = RegExp(buffer.toString());
  }

  final String sourceTemplate;
  final String targetTemplate;

  late final List<String> _names;
  late final RegExp _regex;

  String? tryTranslate(
    String source,
    String Function(String source) translateCapturedLiteral,
  ) {
    final match = _regex.firstMatch(source);
    if (match == null) return null;

    var result = targetTemplate;
    for (var i = 0; i < _names.length; i++) {
      final raw = match.group(i + 1) ?? '';
      final translated = translateCapturedLiteral(raw);
      result = result.replaceAll('{${_names[i]}}', translated);
    }
    return result;
  }
}

extension TranslationExtension on String {
  String tr({
    Map<String, String>? params,
    String? fallback,
  }) {
    return TranslationService.instance.translate(
      this,
      params: params,
      fallback: fallback,
    );
  }

  String tl() => TranslationService.instance.translateLiteral(this);
}
