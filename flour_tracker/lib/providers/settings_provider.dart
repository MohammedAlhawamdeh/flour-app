import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:intl/intl_standalone.dart';
import 'package:intl/date_symbol_data_local.dart'; // For date formatting
import 'dart:ui' as ui; // For forcing app rebuild

class SettingsProvider extends ChangeNotifier {
  String _currencySymbol = '₺';
  bool _showDecimals = true;
  String _language = 'tr'; // Default to Turkish
  String _dateFormat = 'dd.MM.yyyy'; // Turkish date format

  String get currencySymbol => _currencySymbol;
  bool get showDecimals => _showDecimals;
  String get language => _language;
  String get dateFormat => _dateFormat;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _currencySymbol = prefs.getString('currencySymbol') ?? '₺';
    _showDecimals = prefs.getBool('showDecimals') ?? true;
    _language = prefs.getString('language') ?? 'tr';
    _dateFormat = prefs.getString('dateFormat') ?? 'dd.MM.yyyy';
    notifyListeners();
  }

  Future<void> setCurrencySymbol(String symbol) async {
    if (symbol.isEmpty) return;

    _currencySymbol = symbol;
    notifyListeners();
  }

  Future<void> setShowDecimals(bool show) async {
    _showDecimals = show;
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    if (_language == lang) return; // No change needed

    _language = lang;

    // Initialize date formatting for the new language
    await initializeDateFormatting(lang == 'tr' ? 'tr_TR' : 'en_US', null);

    // Save settings immediately when language changes
    await saveSettings();

    // This deep notification will force the entire app to rebuild
    // which is needed when changing language
    notifyListeners();
  }

  Future<void> setDateFormat(String format) async {
    _dateFormat = format;
    notifyListeners();
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currencySymbol', _currencySymbol);
    await prefs.setBool('showDecimals', _showDecimals);
    await prefs.setString('language', _language);
    await prefs.setString('dateFormat', _dateFormat);
  }
}
