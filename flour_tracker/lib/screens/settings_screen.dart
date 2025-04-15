import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flour_tracker/providers/theme_provider.dart';
import 'package:flour_tracker/providers/settings_provider.dart';
import 'package:flour_tracker/services/translations_service.dart'; // Import translations

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLoading();
  }

  Future<void> _checkLoading() async {
    // Small delay to ensure providers are fully loaded
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppTranslations.t(context, 'settingsTitle')),
        backgroundColor: Colors.amber.shade700,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSectionHeader(AppTranslations.t(context, 'appearance')),
                  SwitchListTile(
                    title: Text(AppTranslations.t(context, 'darkMode')),
                    subtitle: Text(
                      AppTranslations.t(context, 'darkModeSubtitle'),
                    ),
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.toggleTheme(value);
                    },
                    secondary: Icon(
                      themeProvider.isDarkMode
                          ? Icons.dark_mode
                          : Icons.light_mode,
                      color: Colors.amber.shade700,
                    ),
                  ),
                  const Divider(),
                  _buildSectionHeader(
                    AppTranslations.t(context, 'displayOptions'),
                  ),
                  ListTile(
                    title: Text(AppTranslations.t(context, 'currencySymbol')),
                    subtitle: Text(
                      '${AppTranslations.t(context, 'current')}: ${settingsProvider.currencySymbol}',
                    ),
                    leading: Icon(
                      Icons.currency_lira,
                      color: Colors.amber.shade700,
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showCurrencyDialog(settingsProvider),
                  ),
                  SwitchListTile(
                    title: Text(AppTranslations.t(context, 'showDecimals')),
                    subtitle: Text(
                      AppTranslations.t(context, 'showDecimalsSubtitle'),
                    ),
                    value: settingsProvider.showDecimals,
                    onChanged: (value) {
                      settingsProvider.setShowDecimals(value);
                    },
                    secondary: Icon(
                      Icons.numbers,
                      color: Colors.amber.shade700,
                    ),
                  ),
                  ListTile(
                    title: Text(AppTranslations.t(context, 'dateFormat')),
                    subtitle: Text(
                      '${AppTranslations.t(context, 'current')}: ${settingsProvider.dateFormat}',
                    ),
                    leading: Icon(
                      Icons.calendar_today,
                      color: Colors.amber.shade700,
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showDateFormatDialog(settingsProvider),
                  ),
                  ListTile(
                    title: Text(
                      AppTranslations.t(context, 'languageSelection'),
                    ),
                    subtitle: Text(
                      '${AppTranslations.t(context, 'current')}: ${settingsProvider.language == 'tr' ? AppTranslations.t(context, 'turkish') : AppTranslations.t(context, 'english')}',
                    ),
                    leading: Icon(Icons.language, color: Colors.amber.shade700),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showLanguageDialog(settingsProvider),
                  ),
                  const Divider(),
                  _buildSectionHeader(
                    AppTranslations.t(context, 'dataManagement'),
                  ),
                  ListTile(
                    title: Text(AppTranslations.t(context, 'backupRestore')),
                    subtitle: Text(
                      AppTranslations.t(context, 'backupSubtitle'),
                    ),
                    leading: Icon(Icons.backup, color: Colors.amber.shade700),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => Navigator.pushNamed(context, '/backup'),
                  ),
                  const Divider(),
                  _buildSectionHeader(AppTranslations.t(context, 'about')),
                  ListTile(
                    title: Text(AppTranslations.t(context, 'version')),
                    subtitle: const Text('1.0.0'),
                    leading: Icon(
                      Icons.info_outline,
                      color: Colors.amber.shade700,
                    ),
                  ),
                  ListTile(
                    title: Text(AppTranslations.t(context, 'developer')),
                    subtitle: Text(AppTranslations.t(context, 'developerName')),
                    leading: Icon(Icons.code, color: Colors.amber.shade700),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () {
                      settingsProvider.saveSettings();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppTranslations.t(context, 'saveSettings'),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(AppTranslations.t(context, 'saveSettings')),
                  ),
                ],
              ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.amber.shade800,
        ),
      ),
    );
  }

  void _showCurrencyDialog(SettingsProvider settingsProvider) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppTranslations.t(context, 'changeCurrencySymbol')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: Text(AppTranslations.t(context, 'turkishLira')),
                  subtitle: const Text('₺'),
                  value: '₺',
                  groupValue: settingsProvider.currencySymbol,
                  onChanged: (value) {
                    settingsProvider.setCurrencySymbol(value!);
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<String>(
                  title: Text(AppTranslations.t(context, 'dollar')),
                  subtitle: const Text('\$'),
                  value: '\$',
                  groupValue: settingsProvider.currencySymbol,
                  onChanged: (value) {
                    settingsProvider.setCurrencySymbol(value!);
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<String>(
                  title: Text(AppTranslations.t(context, 'euro')),
                  subtitle: const Text('€'),
                  value: '€',
                  groupValue: settingsProvider.currencySymbol,
                  onChanged: (value) {
                    settingsProvider.setCurrencySymbol(value!);
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<String>(
                  title: Text(AppTranslations.t(context, 'pound')),
                  subtitle: const Text('£'),
                  value: '£',
                  groupValue: settingsProvider.currencySymbol,
                  onChanged: (value) {
                    settingsProvider.setCurrencySymbol(value!);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppTranslations.t(context, 'cancel')),
              ),
            ],
          ),
    );
  }

  void _showDateFormatDialog(SettingsProvider settingsProvider) {
    final currentFormat = settingsProvider.dateFormat;
    String selectedFormat = currentFormat;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppTranslations.t(context, 'changeDateFormat')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: Text(AppTranslations.t(context, 'turkishFormat')),
                  subtitle: Text(
                    AppTranslations.t(context, 'turkishFormatExample'),
                  ),
                  value: 'dd.MM.yyyy',
                  groupValue: selectedFormat,
                  onChanged: (value) {
                    selectedFormat = value!;
                    Navigator.pop(context, value);
                  },
                ),
                RadioListTile<String>(
                  title: Text(AppTranslations.t(context, 'americanFormat')),
                  subtitle: Text(
                    AppTranslations.t(context, 'americanFormatExample'),
                  ),
                  value: 'MM/dd/yyyy',
                  groupValue: selectedFormat,
                  onChanged: (value) {
                    selectedFormat = value!;
                    Navigator.pop(context, value);
                  },
                ),
                RadioListTile<String>(
                  title: Text(AppTranslations.t(context, 'isoFormat')),
                  subtitle: Text(
                    AppTranslations.t(context, 'isoFormatExample'),
                  ),
                  value: 'yyyy-MM-dd',
                  groupValue: selectedFormat,
                  onChanged: (value) {
                    selectedFormat = value!;
                    Navigator.pop(context, value);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppTranslations.t(context, 'cancel')),
              ),
            ],
          ),
    ).then((value) {
      if (value != null && value != currentFormat) {
        settingsProvider.setDateFormat(value);
      }
    });
  }

  void _showLanguageDialog(SettingsProvider settingsProvider) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppTranslations.t(context, 'changeLanguage')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: Text(AppTranslations.t(context, 'turkish')),
                  value: 'tr',
                  groupValue: settingsProvider.language,
                  onChanged: (value) {
                    settingsProvider.setLanguage(value!);
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<String>(
                  title: Text(AppTranslations.t(context, 'english')),
                  value: 'en',
                  groupValue: settingsProvider.language,
                  onChanged: (value) {
                    settingsProvider.setLanguage(value!);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppTranslations.t(context, 'cancel')),
              ),
            ],
          ),
    );
  }
}
