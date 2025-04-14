import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  String _currencySymbol = '₹';
  bool _showDecimals = true;

  String get currencySymbol => _currencySymbol;
  bool get showDecimals => _showDecimals;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _currencySymbol = prefs.getString('currencySymbol') ?? '₹';
    _showDecimals = prefs.getBool('showDecimals') ?? true;
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

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currencySymbol', _currencySymbol);
    await prefs.setBool('showDecimals', _showDecimals);
  }
}
