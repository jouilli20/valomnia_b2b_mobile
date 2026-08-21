import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_localizations.dart';

final languageControllerProvider =
    AsyncNotifierProvider<LanguageController, Locale>(LanguageController.new);

class LanguageController extends AsyncNotifier<Locale> {
  static const _storageKey = 'app_locale';
  static const _defaultLocale = Locale('fr');

  @override
  Future<Locale> build() async {
    final preferences = await SharedPreferences.getInstance();
    final code = preferences.getString(_storageKey);
    return _localeFromCode(code) ?? _defaultLocale;
  }

  Future<void> setLocale(Locale locale) async {
    if (!_isSupported(locale)) return;

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, locale.languageCode);
    state = AsyncData(Locale(locale.languageCode));
  }

  Locale? _localeFromCode(String? code) {
    if (code == null || code.trim().isEmpty) return null;
    final locale = Locale(code.trim().toLowerCase());
    return _isSupported(locale) ? locale : null;
  }

  bool _isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }
}

class AppLanguage {
  const AppLanguage({required this.locale, required this.label});

  final Locale locale;
  final String label;
}

const appLanguages = [
  AppLanguage(locale: Locale('fr'), label: 'Français'),
  AppLanguage(locale: Locale('en'), label: 'English'),
  AppLanguage(locale: Locale('de'), label: 'Deutsch'),
  AppLanguage(locale: Locale('nl'), label: 'Nederlands'),
  AppLanguage(locale: Locale('es'), label: 'Español'),
];
