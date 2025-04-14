import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flour_tracker/providers/theme_provider.dart';
import 'package:flour_tracker/providers/settings_provider.dart';

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
        title: const Text('Settings'),
        backgroundColor: Colors.amber.shade700,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSectionHeader('Appearance'),
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Enable dark theme for the app'),
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
                  _buildSectionHeader('Display Options'),
                  ListTile(
                    title: const Text('Currency Symbol'),
                    subtitle: Text(
                      'Current: ${settingsProvider.currencySymbol}',
                    ),
                    leading: Icon(
                      Icons.currency_rupee,
                      color: Colors.amber.shade700,
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showCurrencyDialog(settingsProvider),
                  ),
                  SwitchListTile(
                    title: const Text('Show Decimal Places'),
                    subtitle: const Text(
                      'Display values with two decimal places',
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
                  const Divider(),
                  _buildSectionHeader('Data Management'),
                  ListTile(
                    title: const Text('Backup & Restore'),
                    subtitle: const Text('Create backups or restore your data'),
                    leading: Icon(Icons.backup, color: Colors.amber.shade700),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => Navigator.pushNamed(context, '/backup'),
                  ),
                  const Divider(),
                  _buildSectionHeader('About'),
                  ListTile(
                    title: const Text('Version'),
                    subtitle: const Text('1.0.0'),
                    leading: Icon(
                      Icons.info_outline,
                      color: Colors.amber.shade700,
                    ),
                  ),
                  ListTile(
                    title: const Text('Developer'),
                    subtitle: const Text('Flour Tracker Team'),
                    leading: Icon(Icons.code, color: Colors.amber.shade700),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: settingsProvider.saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Save Settings'),
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
    final TextEditingController controller = TextEditingController(
      text: settingsProvider.currencySymbol,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Change Currency Symbol'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Currency Symbol',
                hintText: 'Enter the currency symbol (e.g., ₹, \$, €)',
                border: OutlineInputBorder(),
              ),
              maxLength: 1,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    settingsProvider.setCurrencySymbol(controller.text);
                  }
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }
}
