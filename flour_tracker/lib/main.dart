import 'package:flutter/material.dart';
import 'package:flour_tracker/models/customer.dart';
import 'package:flour_tracker/screens/home_screen.dart';
import 'package:flour_tracker/screens/inventory_screen.dart';
import 'package:flour_tracker/screens/sales_screen.dart';
import 'package:flour_tracker/screens/customers_screen.dart';
import 'package:flour_tracker/screens/customer_debts_screen.dart';
// import 'package:flour_tracker/screens/reports_screen.dart';  // Temporarily disabled
import 'package:flour_tracker/screens/debts_screen.dart';
import 'package:flour_tracker/screens/splash_screen.dart';
import 'package:flour_tracker/screens/settings_screen.dart';
import 'package:flour_tracker/screens/backup_restore_screen.dart';
import 'package:provider/provider.dart';
import 'package:flour_tracker/services/database_service.dart';
import 'package:flour_tracker/providers/theme_provider.dart';
import 'package:flour_tracker/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database factory for desktop platforms
  await DatabaseService.initializeDatabaseFactory();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
      ],
      child: const FlourTrackerApp(),
    ),
  );
}

class FlourTrackerApp extends StatelessWidget {
  const FlourTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen for theme changes
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Flour Tracker',
      debugShowCheckedModeBanner: false, // Disable debug banner for release
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Colors.amber.shade700,
          secondary: Colors.amberAccent,
        ),
        useMaterial3: true,
      ),
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/': (context) => const HomeScreen(),
        '/inventory': (context) => const InventoryScreen(),
        '/sales': (context) => const SalesScreen(),
        '/customers': (context) => const CustomersScreen(),
        // '/reports': (context) => const ReportsScreen(),  // Temporarily disabled
        '/debts': (context) => const DebtsScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/backup': (context) => const BackupRestoreScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/customer_debts') {
          final customer = settings.arguments as Customer;
          return MaterialPageRoute(
            builder: (context) => CustomerDebtsScreen(customer: customer),
          );
        }
        return null;
      },
    );
  }
}
