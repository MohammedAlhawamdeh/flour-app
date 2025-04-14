import 'package:flutter/material.dart';
import 'package:flour_tracker/models/flour_product.dart';
import 'package:flour_tracker/services/database_service.dart';
import 'package:flour_tracker/widgets/custom_text_field.dart';
import 'package:provider/provider.dart';
import 'package:flour_tracker/providers/settings_provider.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<FlourProduct> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await _databaseService.getProducts();
      setState(() {
        _products = products;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading products: $e')),
      );
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
        title: const Text('Inventory Management'),
        backgroundColor: Colors.amber.shade700,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 80,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No flour products found',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add a product to get started',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
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
                                    product.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _showProductForm(product),
                                      color: Colors.blue,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => _deleteProduct(product),
                                      color: Colors.red,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildInfoItem(
                                  'Price per Kg',
                                  '${settingsProvider.currencySymbol}${product.pricePerKg.toStringAsFixed(settingsProvider.showDecimals ? 2 : 0)}',
                                  _getCurrencyIcon(settingsProvider.currencySymbol),
                                ),
                                const SizedBox(width: 16),
                                _buildInfoItem(
                                  'Quantity in Stock',
                                  '${product.quantityInStock.toStringAsFixed(settingsProvider.showDecimals ? 2 : 0)} kg',
                                  Icons.inventory,
                                ),
                              ],
                            ),
                            if (product.description != null &&
                                product.description!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Description: ${product.description}',
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
        onPressed: () => _showProductForm(),
        backgroundColor: Colors.amber.shade700,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.amber.shade700,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
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
    );
  }

  IconData _getCurrencyIcon(String currencySymbol) {
    switch (currencySymbol) {
      case '₹':
        return Icons.currency_rupee;
      case '\$':
        return Icons.attach_money;
      case '€':
        return Icons.euro;
      case '£':
        return Icons.currency_pound;
      case '¥':
        return Icons.currency_yen;
      default:
        return Icons.monetization_on;
    }
  }

  Future<void> _showProductForm([FlourProduct? product]) async {
    final TextEditingController nameController =
        TextEditingController(text: product?.name ?? '');
    final TextEditingController priceController = TextEditingController(
        text: product?.pricePerKg.toString() ?? '');
    final TextEditingController quantityController = TextEditingController(
        text: product?.quantityInStock.toString() ?? '');
    final TextEditingController descriptionController =
        TextEditingController(text: product?.description ?? '');

    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
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
                product == null ? 'Add New Product' : 'Edit Product',
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
                    CustomTextField(
                      label: 'Product Name',
                      controller: nameController,
                    ),
                    CustomTextField(
                      label: 'Price per Kg',
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Price is required';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    CustomTextField(
                      label: 'Quantity in Stock (kg)',
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Quantity is required';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    CustomTextField(
                      label: 'Description (Optional)',
                      controller: descriptionController,
                      isRequired: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(context);
                    
                    final FlourProduct newProduct = FlourProduct(
                      id: product?.id,
                      name: nameController.text,
                      pricePerKg: double.parse(priceController.text),
                      quantityInStock: double.parse(quantityController.text),
                      description: descriptionController.text.isEmpty
                          ? null
                          : descriptionController.text,
                    );

                    try {
                      if (product == null) {
                        await _databaseService.insertProduct(newProduct);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Product added successfully')),
                        );
                      } else {
                        await _databaseService.updateProduct(newProduct);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Product updated successfully')),
                        );
                      }
                      _loadProducts();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Error saving product: $e')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  product == null ? 'Add Product' : 'Update Product',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteProduct(FlourProduct product) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
            'Are you sure you want to delete ${product.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm && product.id != null) {
      try {
        await _databaseService.deleteProduct(product.id!);
        _loadProducts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting product: $e')),
          );
        }
      }
    }
  }
}