import 'package:flutter/material.dart';
import 'package:flour_tracker/models/customer.dart';
import 'package:flour_tracker/models/flour_product.dart';
import 'package:flour_tracker/models/sale.dart';
import 'package:flour_tracker/services/database_service.dart';
import 'package:flour_tracker/widgets/custom_text_field.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flour_tracker/providers/settings_provider.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Sale> _sales = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final sales = await _databaseService.getSales();
      setState(() {
        _sales = sales;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading sales: $e')));
      }
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
        title: const Text('Sales Management'),
        backgroundColor: Colors.amber.shade700,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _sales.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.point_of_sale_outlined,
                      size: 80,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No sales found',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Record a sale to get started',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _sales.length,
                itemBuilder: (context, index) {
                  final sale = _sales[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Sale #${sale.id}',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      sale.isPaid
                                          ? Colors.green.shade100
                                          : Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  sale.isPaid ? 'Paid' : 'Unpaid',
                                  style: TextStyle(
                                    color:
                                        sale.isPaid
                                            ? Colors.green.shade800
                                            : Colors.red.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Product: ${sale.product.name}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          Text(
                            'Date: ${DateFormat('MMM dd, yyyy').format(sale.date)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Quantity',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    Text(
                                      '${sale.quantity.toStringAsFixed(settingsProvider.showDecimals ? 2 : 0)} kg',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Price',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    Text(
                                      '${settingsProvider.currencySymbol}${sale.totalPrice.toStringAsFixed(settingsProvider.showDecimals ? 2 : 0)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (sale.customer != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Customer: ${sale.customer!.name}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSaleForm(),
        backgroundColor: Colors.amber.shade700,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showSaleForm() async {
    final products = await _databaseService.getProducts();
    final customers = await _databaseService.getCustomers();

    if (products.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add flour products before recording a sale'),
          ),
        );
      }
      return;
    }

    FlourProduct? selectedProduct = products.isNotEmpty ? products[0] : null;
    Customer? selectedCustomer;

    final quantityController = TextEditingController();
    final isPaidController = ValueNotifier<bool>(true);

    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Record New Sale',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Form(
                    key: formKey,
                    child: Column(
                      children: [
                        // Product Dropdown
                        DropdownButtonFormField<FlourProduct>(
                          value: selectedProduct,
                          decoration: const InputDecoration(
                            labelText: 'Select Product',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          items:
                              products.map((product) {
                                return DropdownMenuItem<FlourProduct>(
                                  value: product,
                                  child: Text(
                                    '${product.name} - ${Provider.of<SettingsProvider>(context).currencySymbol}${product.pricePerKg}/kg (${product.quantityInStock.toStringAsFixed(Provider.of<SettingsProvider>(context).showDecimals ? 2 : 0)} kg in stock)',
                                  ),
                                );
                              }).toList(),
                          onChanged: (product) {
                            setState(() {
                              selectedProduct = product;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a product';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Quantity TextField
                        CustomTextField(
                          label: 'Quantity (kg)',
                          controller: quantityController,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Quantity is required';
                            }
                            final quantity = double.tryParse(value);
                            if (quantity == null) {
                              return 'Please enter a valid number';
                            }
                            if (selectedProduct != null &&
                                quantity > selectedProduct!.quantityInStock) {
                              return 'Not enough stock available';
                            }
                            return null;
                          },
                        ),

                        // Customer Dropdown (Optional)
                        if (customers.isNotEmpty)
                          DropdownButtonFormField<Customer?>(
                            value: selectedCustomer,
                            decoration: const InputDecoration(
                              labelText: 'Select Customer (Optional)',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            items: [
                              const DropdownMenuItem<Customer?>(
                                value: null,
                                child: Text('No Customer (Walk-in)'),
                              ),
                              ...customers.map((customer) {
                                return DropdownMenuItem<Customer?>(
                                  value: customer,
                                  child: Text(customer.name),
                                );
                              }),
                            ],
                            onChanged: (customer) {
                              setState(() {
                                selectedCustomer = customer;
                              });
                            },
                          ),

                        // Payment Status Switch
                        ValueListenableBuilder<bool>(
                          valueListenable: isPaidController,
                          builder: (context, isPaid, _) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Payment Status:'),
                                  Row(
                                    children: [
                                      Text(isPaid ? 'Paid' : 'Unpaid'),
                                      Switch(
                                        value: isPaid,
                                        activeColor: Colors.amber.shade700,
                                        onChanged: (value) {
                                          isPaidController.value = value;
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate() &&
                          selectedProduct != null) {
                        Navigator.pop(context);

                        final double quantity = double.parse(
                          quantityController.text,
                        );
                        final double totalPrice =
                            quantity * selectedProduct!.pricePerKg;

                        final Sale newSale = Sale(
                          product: selectedProduct!,
                          customer: selectedCustomer,
                          quantity: quantity,
                          totalPrice: totalPrice,
                          pricePerKg: selectedProduct!.pricePerKg,
                          date: DateTime.now(),
                          isPaid: isPaidController.value,
                        );

                        try {
                          await _databaseService.insertSale(newSale);
                          _loadSales();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Sale recorded successfully'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error recording sale: $e'),
                              ),
                            );
                          }
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Record Sale',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
