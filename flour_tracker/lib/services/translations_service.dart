import 'package:flutter/material.dart';

class AppTranslations {
  static final Map<String, Map<String, String>> _translations = {
    'en': {
      // App title
      'appTitle': 'Flour Tracker',

      // Main menu items
      'home': 'Home',
      'inventory': 'Inventory',
      'sales': 'Sales',
      'customers': 'Customers',
      'debts': 'Debts',
      'expenses': 'Expenses',
      'settings': 'Settings',
      'backup': 'Backup & Restore',

      // Home screen
      'welcome': 'Welcome to Flour Tracker',
      'welcomeSubtitle': 'Manage your flour business from one place',
      'dailySummary': 'Daily Summary',
      'todaySales': 'Today\'s Sales',
      'totalDebt': 'Total Debt',
      'lowStockWarning': 'Low Stock Warning (below 50kg)',
      'refresh': 'Refresh',
      'inventoryManagement': 'Inventory Management',
      'inventoryDescription': 'Track and manage flour stock levels',
      'salesManagement': 'Sales Management',
      'salesDescription': 'Record and track flour sales',
      'customerManagement': 'Customer Management',
      'customerDescription': 'Manage customers and their information',
      'debtTracking': 'Debt Tracking',
      'debtDescription': 'Track customer debts and payments',
      'expenseTracking': 'Expense Tracking',
      'expenseDescription': 'Track daily business expenses',
      'reports': 'Reports',
      'reportsDescription': 'View sales and inventory reports (Coming Soon)',

      // Settings screen
      'settingsTitle': 'Settings',
      'appearance': 'Appearance',
      'darkMode': 'Dark Mode',
      'darkModeSubtitle': 'Enable dark theme for the app',
      'displayOptions': 'Display Options',
      'currencySymbol': 'Currency Symbol',
      'current': 'Current',
      'showDecimals': 'Show Decimals',
      'showDecimalsSubtitle': 'Show values with two decimal places',
      'dateFormat': 'Date Format',
      'languageSelection': 'Language Selection',
      'dataManagement': 'Data Management',
      'backupRestore': 'Backup & Restore',
      'backupSubtitle': 'Create backups or restore your data',
      'about': 'About',
      'version': 'Version',
      'developer': 'Developer',
      'developerName': 'Flour Tracker Team',
      'saveSettings': 'Save Settings',

      // Language dialog
      'changeLanguage': 'Change Language',
      'turkish': 'Turkish',
      'english': 'English',
      'cancel': 'Cancel',

      // Currency dialog
      'changeCurrency': 'Change Currency Symbol',
      'turkishLira': 'Turkish Lira',
      'dollar': 'Dollar',
      'euro': 'Euro',
      'pound': 'Pound',

      // Date format dialog
      'changeDateFormat': 'Change Date Format',
      'turkishFormat': 'DD.MM.YYYY',
      'turkishFormatExample': 'Example: 14.04.2025',
      'americanFormat': 'MM/DD/YYYY',
      'americanFormatExample': 'Example: 04/14/2025',
      'isoFormat': 'YYYY-MM-DD',
      'isoFormatExample': 'Example: 2025-04-14',
    },
    'tr': {
      // App title
      'appTitle': 'Un Takip',

      // Main menu items
      'home': 'Ana Sayfa',
      'inventory': 'Envanter',
      'sales': 'Satışlar',
      'customers': 'Müşteriler',
      'debts': 'Borçlar',
      'expenses': 'Giderler',
      'settings': 'Ayarlar',
      'backup': 'Yedekleme & Geri Yükleme',

      // Home screen
      'welcome': 'Un Takip Sistemine Hoş Geldiniz',
      'welcomeSubtitle': 'Unlu mamul işletmenizi tek yerden yönetin',
      'dailySummary': 'Günlük Özet',
      'todaySales': 'Bugünkü Satışlar',
      'totalDebt': 'Toplam Borç',
      'lowStockWarning': 'Düşük Stok Uyarısı (50kg altı)',
      'refresh': 'Yenile',
      'inventoryManagement': 'Stok Yönetimi',
      'inventoryDescription': 'Un stok seviyelerini takip edin ve yönetin',
      'salesManagement': 'Satış Yönetimi',
      'salesDescription': 'Un satışlarını kaydedin ve takip edin',
      'customerManagement': 'Müşteri Yönetimi',
      'customerDescription': 'Müşterileri ve bilgilerini yönetin',
      'debtTracking': 'Borç Takibi',
      'debtDescription': 'Müşteri borçlarını ve ödemelerini takip edin',
      'expenseTracking': 'Gider Takibi',
      'expenseDescription': 'Günlük işletme giderlerini takip edin',
      'reports': 'Raporlar',
      'reportsDescription': 'Satış ve stok raporlarını görüntüleyin (Yakında)',

      // Settings screen
      'settingsTitle': 'Ayarlar',
      'appearance': 'Görünüm',
      'darkMode': 'Karanlık Mod',
      'darkModeSubtitle': 'Uygulama için karanlık temayı etkinleştir',
      'displayOptions': 'Görüntüleme Seçenekleri',
      'currencySymbol': 'Para Birimi Sembolü',
      'current': 'Güncel',
      'showDecimals': 'Ondalık Göster',
      'showDecimalsSubtitle': 'Değerleri iki ondalık basamakla göster',
      'dateFormat': 'Tarih Formatı',
      'languageSelection': 'Dil Seçimi',
      'dataManagement': 'Veri Yönetimi',
      'backupRestore': 'Yedekleme & Geri Yükleme',
      'backupSubtitle': 'Yedek oluşturun veya verilerinizi geri yükleyin',
      'about': 'Hakkında',
      'version': 'Sürüm',
      'developer': 'Geliştirici',
      'developerName': 'Un Takip Ekibi',
      'saveSettings': 'Ayarları Kaydet',

      // Language dialog
      'changeLanguage': 'Dil Seçimini Değiştir',
      'turkish': 'Türkçe',
      'english': 'English',
      'cancel': 'İptal',

      // Currency dialog
      'changeCurrency': 'Para Birimi Sembolünü Değiştir',
      'turkishLira': 'Türk Lirası',
      'dollar': 'Dolar',
      'euro': 'Euro',
      'pound': 'Pound',

      // Date format dialog
      'changeDateFormat': 'Tarih Formatını Değiştir',
      'turkishFormat': 'GG.AA.YYYY',
      'turkishFormatExample': 'Örn. 14.04.2025',
      'americanFormat': 'AA/GG/YYYY',
      'americanFormatExample': 'Örn. 04/14/2025',
      'isoFormat': 'YYYY-AA-GG',
      'isoFormatExample': 'Örn. 2025-04-14',
    },
  };

  static String translate(BuildContext context, String key) {
    final Locale locale = Localizations.localeOf(context);
    final String languageCode = locale.languageCode;

    if (!_translations.containsKey(languageCode) ||
        !_translations[languageCode]!.containsKey(key)) {
      // Fallback to English if translation is missing
      return _translations['en']![key] ?? key;
    }

    return _translations[languageCode]![key]!;
  }

  // Shorthand method for easier access
  static String t(BuildContext context, String key) => translate(context, key);
}
