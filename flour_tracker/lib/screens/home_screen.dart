import 'package:flutter/material.dart';
import 'package:flour_tracker/models/flour_product.dart';
import 'package:flour_tracker/models/sale.dart';
import 'package:flour_tracker/services/database_service.dart';
import 'package:provider/provider.dart';
import 'package:flour_tracker/providers/settings_provider.dart';
import 'package:intl/intl.dart';
import 'package:flour_tracker/services/translations_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = true;
  double _totalSalesToday = 0;
  double _totalOutstandingDebt = 0;
  List<FlourProduct> _lowStockProducts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Calculate total sales today
      final sales = await _databaseService.getSales();
      final today = DateTime.now();
      final todaySales =
          sales
              .where(
                (sale) =>
                    sale.date.year == today.year &&
                    sale.date.month == today.month &&
                    sale.date.day == today.day,
              )
              .toList();

      _totalSalesToday = todaySales.fold(
        0,
        (sum, sale) => sum + sale.totalPrice,
      );

      // Get outstanding debts
      final debts = await _databaseService.getDebts();
      _totalOutstandingDebt = debts
          .where((debt) => !debt.isPaid)
          .fold(0, (sum, debt) => sum + debt.amount);

      // Get low stock products (less than 50kg)
      final products = await _databaseService.getProducts();
      _lowStockProducts =
          products.where((product) => product.quantityInStock < 50).toList();
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppTranslations.t(context, 'appTitle')),
        backgroundColor: Colors.amber.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: AppTranslations.t(context, 'refresh'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            tooltip: AppTranslations.t(context, 'settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // App Logo and Welcome Message
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 60,
                    color: Colors.amber.shade700,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppTranslations.t(context, 'welcome'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppTranslations.t(context, 'welcomeSubtitle'),
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Daily Summary Section
            _isLoading
                ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                )
                : Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppTranslations.t(context, 'dailySummary'),
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade800,
                            ),
                          ),
                          Text(
                            DateFormat(
                              settingsProvider.dateFormat,
                            ).format(DateTime.now()),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      _buildSummaryItem(
                        context,
                        AppTranslations.t(context, 'todaySales'),
                        '${settingsProvider.currencySymbol}${_totalSalesToday.toStringAsFixed(2)}',
                        Icons.point_of_sale,
                        Colors.green,
                      ),
                      const SizedBox(height: 16),
                      _buildSummaryItem(
                        context,
                        AppTranslations.t(context, 'totalDebt'),
                        '${settingsProvider.currencySymbol}${_totalOutstandingDebt.toStringAsFixed(2)}',
                        Icons.account_balance_wallet,
                        _totalOutstandingDebt > 0 ? Colors.red : Colors.green,
                      ),
                      if (_lowStockProducts.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        _buildLowStockWarning(context, _lowStockProducts),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),

            const SizedBox(height: 24),

            // Main Menu Grid
            _buildMenuGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required IconData icon,
    required String titleKey,
    required String route,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withOpacity(0.7)],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 42, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                AppTranslations.t(context, titleKey),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLowStockWarning(
    BuildContext context,
    List<FlourProduct> lowStockProducts,
  ) {
    if (lowStockProducts.isEmpty) {
      return Container();
    }

    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  AppTranslations.t(context, 'lowStockWarning'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...lowStockProducts
                .map(
                  (product) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      '• ${product.name}: ${product.currentStock} ${AppTranslations.t(context, 'unitsLeft')}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                )
                .toList(),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.inventory),
              label: Text(AppTranslations.t(context, 'goToInventory')),
              onPressed: () => Navigator.pushNamed(context, '/inventory'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      padding: const EdgeInsets.all(16),
      children: [
        _buildMenuCard(
          context: context,
          icon: Icons.inventory_2,
          titleKey: 'menuInventory',
          route: '/inventory',
          color: Colors.blue.shade700,
        ),
        _buildMenuCard(
          context: context,
          icon: Icons.shopping_bag,
          titleKey: 'menuSales',
          route: '/sales',
          color: Colors.green.shade700,
        ),
        _buildMenuCard(
          context: context,
          icon: Icons.people,
          titleKey: 'menuCustomers',
          route: '/customers',
          color: Colors.orange.shade700,
        ),
        _buildMenuCard(
          context: context,
          icon: Icons.money_off,
          titleKey: 'menuDebts',
          route: '/debts',
          color: Colors.red.shade700,
        ),
        _buildMenuCard(
          context: context,
          icon: Icons.payments,
          titleKey: 'menuExpenses',
          route: '/expenses',
          color: Colors.purple.shade700,
        ),
        _buildMenuCard(
          context: context,
          icon: Icons.bar_chart,
          titleKey: 'menuReports',
          route: '/reports',
          color: Colors.teal.shade700,
        ),
      ],
    );
  }
}
