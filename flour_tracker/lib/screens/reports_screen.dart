import 'package:flutter/material.dart';
import 'package:flour_tracker/models/sale.dart';
import 'package:flour_tracker/models/customer.dart';
import 'package:flour_tracker/models/flour_product.dart';
import 'package:flour_tracker/services/database_service.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

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
  int _totalSales = 0;
  int _totalCustomers = 0;
  double _totalUnpaidAmount = 0;

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
      final filteredSales = sales.where((sale) {
        return sale.date.isAfter(_startDate) &&
            sale.date.isBefore(_endDate.add(const Duration(days: 1)));
      }).toList();

      // Calculate summary metrics
      double totalRevenue = 0;
      double totalQuantity = 0;
      double unpaidAmount = 0;

      for (var sale in filteredSales) {
        totalRevenue += sale.totalPrice;
        totalQuantity += sale.quantity;

        if (!sale.isPaid) {
          unpaidAmount += sale.totalPrice;
        }
      }

      setState(() {
        _sales = filteredSales;
        _customers = customers;
        _products = products;
        _totalRevenue = totalRevenue;
        _totalQuantitySold = totalQuantity;
        _totalSales = filteredSales.length;
        _totalCustomers = customers.length;
        _totalUnpaidAmount = unpaidAmount;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading report data: $e')),
        );
      }
      setState(() {

  Widget _buildSummaryCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sales Summary',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Sales',
                '₹${_totalSales.toStringAsFixed(2)}',
                Icons.payments,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Quantity Sold',
                '${_totalQuantitySold.toStringAsFixed(2)} kg',
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
                'Transactions',
                _totalTransactions.toString(),
                Icons.receipt_long,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Average Sale',
                _totalTransactions > 0
                    ? '₹${(_totalSales / _totalTransactions).toStringAsFixed(2)}'
                    : '₹0.00',
                Icons.trending_up,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventorySection() {
    // Sort products by stock level (ascending)
    final sortedProducts = List<FlourProduct>.from(_products)
      ..sort((a, b) => a.quantityInStock.compareTo(b.quantityInStock));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Inventory Status',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        if (_products.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No inventory data available'),
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
                    'Current Stock Levels',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
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
                                child: Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                '${product.quantityInStock.toStringAsFixed(2)} kg',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: product.quantityInStock < 10
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

  Widget _buildRecentSalesSection() {
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
          'Recent Sales',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        if (recentSales.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No recent sales data available'),
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
                          bottom: i < recentSales.length - 1 ? 16 : 0),
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
                                  '${recentSales[i].product.name} - ${recentSales[i].quantity.toStringAsFixed(2)} kg',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  DateFormat('MMM dd, yyyy')
                                      .format(recentSales[i].date),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${recentSales[i].totalPrice.toStringAsFixed(2)}',
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
}