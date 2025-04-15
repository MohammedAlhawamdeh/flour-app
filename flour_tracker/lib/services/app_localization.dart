import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart'; // Added import for SynchronousFuture

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  // Helper method to get translations
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  // Static member to provide the path to the translation JSON files
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'Flour Tracker',
      'home': 'Home',
      'inventory': 'Inventory',
      'sales': 'Sales',
      'customers': 'Customers',
      'debts': 'Debts',
      'expenses': 'Expenses',
      'reports': 'Reports',
      'settings': 'Settings',
      'darkMode': 'Dark Mode',
      'language': 'Language',
      'backupRestore': 'Backup & Restore',
      // Add more translations as needed
    },
    'tr': {
      'appTitle': 'Un Takip',
      'home': 'Ana Sayfa',
      'inventory': 'Stok',
      'sales': 'Satışlar',
      'customers': 'Müşteriler',
      'debts': 'Borçlar',
      'expenses': 'Giderler',
      'reports': 'Raporlar',
      'settings': 'Ayarlar',
      'darkMode': 'Karanlık Mod',
      'language': 'Dil',
      'backupRestore': 'Yedekleme ve Geri Yükleme',
      // Add more translations as needed
    },
  };

  // Method to get localized strings
  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

// This delegate will be responsible for loading the localization
class AppLocalizationDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationDelegate();

  @override
  bool isSupported(Locale locale) {
    // We support English and Turkish
    return ['en', 'tr'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(AppLocalizationDelegate old) => false; // Only reload if needed
}
