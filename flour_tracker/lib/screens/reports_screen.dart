import 'package:flutter/material.dart';
import 'package:flour_tracker/models/sale.dart';
import 'package:flour_tracker/models/customer.dart';
import 'package:flour_tracker/models/flour_product.dart';
import 'package:flour_tracker/services/database_service.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:flour_tracker/providers/settings_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = true;

  // Report data
  List<Sale> _sales = [];
  List<Customer> _customers = [];
  List<FlourProduct> _products = [];

  // Selected date range
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  // Summary metrics
  double _totalRevenue = 0;
  double _totalQuantitySold = 0;
  int _totalTransactions = 0;
  int _totalCustomers = 0;
  double _totalUnpaidAmount = 0;

  // Category analysis data
  Map<String, double> _categoryQuantityMap = {};
  Map<String, double> _categoryRevenueMap = {};

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final sales = await _databaseService.getSales();
      final customers = await _databaseService.getCustomers();
      final products = await _databaseService.getProducts();

      // Filter sales by date range
      final filteredSales =
          sales.where((sale) {
            return sale.date.isAfter(_startDate) &&
                sale.date.isBefore(_endDate.add(const Duration(days: 1)));
          }).toList();

      // Calculate summary metrics
      double totalRevenue = 0;
      double totalQuantity = 0;
      double unpaidAmount = 0;
      Map<String, double> categoryQuantity = {};
      Map<String, double> categoryRevenue = {};

      for (var sale in filteredSales) {
        totalRevenue += sale.totalPrice;
        totalQuantity += sale.quantity;

        if (!sale.isPaid) {
          unpaidAmount += sale.totalPrice;
        }

        // Category analysis
        final category = sale.product.category ?? 'Diğer';
        categoryQuantity[category] =
            (categoryQuantity[category] ?? 0) + sale.quantity;
        categoryRevenue[category] =
            (categoryRevenue[category] ?? 0) + sale.totalPrice;
      }

      setState(() {
        _sales = filteredSales;
        _customers = customers;
        _products = products;
        _totalRevenue = totalRevenue;
        _totalQuantitySold = totalQuantity;
        _totalTransactions = filteredSales.length;
        _totalCustomers = customers.length;
        _totalUnpaidAmount = unpaidAmount;
        _categoryQuantityMap = categoryQuantity;
        _categoryRevenueMap = categoryRevenue;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rapor verileri yüklenirken hata: $e')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.amber.shade700,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadReportData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Satış Raporları'),
        backgroundColor: Colors.amber.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Tarih Aralığı Seç',
            onPressed: _selectDateRange,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date range indicator
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.amber.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${DateFormat(settingsProvider.dateFormat).format(_startDate)} - ${DateFormat(settingsProvider.dateFormat).format(_endDate)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Summary cards
                    _buildSummaryCards(settingsProvider),
                    const SizedBox(height: 24),

                    // Category analysis
                    _buildCategoryAnalysis(settingsProvider),
                    const SizedBox(height: 24),

                    // Inventory section
                    _buildInventorySection(settingsProvider),
                    const SizedBox(height: 24),

                    // Recent sales
                    _buildRecentSalesSection(settingsProvider),
                  ],
                ),
              ),
    );
  }

  Widget _buildSummaryCards(SettingsProvider settingsProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Satış Özeti',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Toplam Gelir',
                '${settingsProvider.currencySymbol}${_totalRevenue.toStringAsFixed(settingsProvider.showDecimals ? 2 : 0)}',
                Icons.payments,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Satılan Miktar',
                '${_totalQuantitySold.toStringAsFixed(settingsProvider.showDecimals ? 2 : 0)} çuval',
                Icons.inventory,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'İşlem Sayısı',
                _totalTransactions.toString(),
                Icons.receipt_long,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Ödenmemiş Tutar',
                '${settingsProvider.currencySymbol}${_totalUnpaidAmount.toStringAsFixed(settingsProvider.showDecimals ? 2 : 0)}',
                Icons.money_off,
                Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryAnalysis(SettingsProvider settingsProvider) {
    // Sort categories by quantity sold (descending)
    final sortedCategories =
        _categoryQuantityMap.keys.toList()..sort(
          (a, b) =>
              _categoryQuantityMap[b]!.compareTo(_categoryQuantityMap[a]!),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Un Kategorisi Analizi',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (_categoryQuantityMap.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Kategori analizi için veri bulunamadı'),
            ),
          )
        else
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kategori Bazında Satış Miktarları',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  for (var category in sortedCategories)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  category,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                '${_categoryQuantityMap[category]!.toStringAsFixed(settingsProvider.showDecimals ? 2 : 0)} çuval',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: _getCategoryPercentage(category),
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation(
                              _getCategoryColor(category),
                            ),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${settingsProvider.currencySymbol}${_categoryRevenueMap[category]!.toStringAsFixed(settingsProvider.showDecimals ? 2 : 0)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInventorySection(SettingsProvider settingsProvider) {
    // Sort products by stock level (ascending)
    final sortedProducts = List<FlourProduct>.from(_products)
      ..sort((a, b) => a.quantityInStock.compareTo(b.quantityInStock));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stok Durumu',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (_products.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Stok verisi bulunamadı'),
            ),
          )
        else
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Güncel Stok Seviyeleri',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  for (var product in sortedProducts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (product.category != null &&
                                        product.category!.isNotEmpty)
                                      Text(
                                        product.category!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.amber.shade900,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                '${product.quantityInStock.toStringAsFixed(settingsProvider.showDecimals ? 2 : 0)} çuval',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      product.quantityInStock < 10
                                          ? Colors.red
                                          : Colors.black,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: _getStockLevelPercentage(product),
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation(
                              _getStockLevelColor(product),
                            ),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRecentSalesSection(SettingsProvider settingsProvider) {
    // Get 5 most recent sales
    List<Sale> recentSales = [];
    if (_sales.isNotEmpty) {
      recentSales = List<Sale>.from(_sales);
      recentSales.sort((a, b) => b.date.compareTo(a.date));
      recentSales = recentSales.take(5).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Son Satışlar',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (recentSales.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Son satış verisi bulunamadı'),
            ),
          )
        else
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (var i = 0; i < recentSales.length; i++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: i < recentSales.length - 1 ? 16 : 0,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.shopping_bag,
                              color: Colors.amber.shade700,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  recentSales[i].product.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (recentSales[i].product.category != null &&
                                    recentSales[i].product.category!.isNotEmpty)
                                  Text(
                                    recentSales[i].product.category!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.amber.shade900,
                                    ),
                                  ),
                                Text(
                                  '${recentSales[i].quantity.toStringAsFixed(settingsProvider.showDecimals ? 2 : 0)} çuval - ${DateFormat(settingsProvider.dateFormat).format(recentSales[i].date)}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${settingsProvider.currencySymbol}${recentSales[i].totalPrice.toStringAsFixed(settingsProvider.showDecimals ? 2 : 0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // Helper methods
  double _getStockLevelPercentage(FlourProduct product) {
    // Assuming 100kg as full capacity for visualization purposes
    // Adjust as needed based on your business logic
    const maxCapacity = 100.0;
    return (product.quantityInStock / maxCapacity).clamp(0.0, 1.0);
  }

  Color _getStockLevelColor(FlourProduct product) {
    if (product.quantityInStock < 10) {
      return Colors.red;
    } else if (product.quantityInStock < 30) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  double _getCategoryPercentage(String category) {
    // Calculate as percentage of total sales quantity
    if (_totalQuantitySold == 0) return 0;
    return (_categoryQuantityMap[category] ?? 0) / _totalQuantitySold;
  }

  Color _getCategoryColor(String category) {
    // Different colors for different flour categories
    switch (category) {
      case 'Ekmeklik':
        return Colors.amber.shade700;
      case 'Böreklik':
        return Colors.orange.shade600;
      case 'Poğaçalık':
        return Colors.red.shade500;
      case 'Çöreklik':
        return Colors.green.shade600;
      case 'Baklavalik':
        return Colors.purple.shade500;
      case 'Keklik':
        return Colors.blue.shade500;
      case 'Simitlik':
        return Colors.brown.shade500;
      case 'Pidecik':
        return Colors.teal.shade500;
      case 'Genel Amaçlı':
        return Colors.indigo.shade500;
      default:
        return Colors.grey.shade600;
    }
  }
}
