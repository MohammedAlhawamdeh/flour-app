import 'package:flutter/material.dart';
import 'package:flour_tracker/models/customer.dart';
import 'package:flour_tracker/models/debt.dart';
import 'package:flour_tracker/models/flour_product.dart';
import 'package:flour_tracker/services/database_service.dart';
import 'package:flour_tracker/widgets/custom_text_field.dart';
import 'package:provider/provider.dart';
import 'package:flour_tracker/providers/settings_provider.dart';
import 'package:intl/intl.dart';

class CustomerDebtsScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDebtsScreen({super.key, required this.customer});

  @override
  State<CustomerDebtsScreen> createState() => _CustomerDebtsScreenState();
}

class _CustomerDebtsScreenState extends State<CustomerDebtsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Debt> _debts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDebts();
  }

  double get _totalDebt {
    if (_debts.isEmpty) return 0;
    return _debts.fold(0, (sum, debt) => sum + (debt.isPaid ? 0 : debt.amount));
  }

  Future<void> _loadDebts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final debts = await _databaseService.getCustomerDebts(
        widget.customer.id!,
      );
      setState(() {
        _debts = debts;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading debts: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addDebt(Debt debt) async {
    try {
      // First, ensure the product exists in the database
      final existingProduct = await _databaseService.getProduct(
        debt.product.id!,
      );

      if (existingProduct == null) {
        // The product doesn't exist yet, so insert it
        await _databaseService.insertProduct(debt.product);
      }

      // Now add the debt
      await _databaseService.addDebt(debt);
      _loadDebts(); // Reload the list after adding
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debt added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding debt: $e')));
      }
    }
  }

  Future<void> _updateDebt(Debt debt) async {
    try {
      await _databaseService.updateDebt(debt);
      _loadDebts(); // Reload the list after updating
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debt updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating debt: $e')));
      }
    }
  }

  Future<void> _confirmDeleteDebt(Debt debt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: Text(
              'Are you sure you want to delete this debt record for ${debt.product.name}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      _deleteDebt(debt);
    }
  }

  Future<void> _deleteDebt(Debt debt) async {
    try {
      if (debt.id == null) {
        throw Exception('Cannot delete debt with null ID');
      }
      await _databaseService.deleteDebt(debt.id!);
      _loadDebts(); // Reload the list after deleting
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debt deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting debt: $e')));
      }
    }
  }

  void _showDebtForm([Debt? debtToEdit]) {
    final formKey = GlobalKey<FormState>();
    final isEditing = debtToEdit != null;

    // Form field controllers
    final productController = TextEditingController(
      text: isEditing ? debtToEdit.product.name : '',
    );
    final quantityController = TextEditingController(
      text: isEditing ? debtToEdit.quantity.toString() : '',
    );
    final priceController = TextEditingController(
      text: isEditing ? debtToEdit.amount.toString() : '',
    );
    final descriptionController = TextEditingController(
      text: isEditing ? debtToEdit.description ?? '' : '',
    );

    DateTime selectedDate = isEditing ? debtToEdit.date : DateTime.now();
    bool isPaid = isEditing ? debtToEdit.isPaid : false;

    // For product selection
    FlourProduct? selectedProduct = isEditing ? debtToEdit.product : null;
    bool isCreatingNewProduct = selectedProduct == null;
    List<FlourProduct> existingProducts = [];
    bool isLoadingProducts = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final settingsProvider = Provider.of<SettingsProvider>(context);

            // Load existing products when the form is shown
            if (isLoadingProducts) {
              _databaseService.getProducts().then((products) {
                setState(() {
                  existingProducts = products;
                  isLoadingProducts = false;

                  // If editing, check if the product exists in the list
                  if (isEditing && selectedProduct != null) {
                    final existingProduct = products.firstWhere(
                      (p) => p.id == selectedProduct?.id,
                      orElse: () => selectedProduct!,
                    );
                    selectedProduct = existingProduct;

                    // Update controllers with selected product data
                    productController.text = selectedProduct!.name;
                    if (!isCreatingNewProduct) {
                      priceController.text =
                          selectedProduct!.pricePerKg.toString();
                    }
                  }
                });
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      isEditing ? 'Edit Debt' : 'Add New Debt',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Product selection section
                    Row(
                      children: [
                        const Text('Product: '),
                        const SizedBox(width: 8),
                        Expanded(
                          child:
                              isLoadingProducts
                                  ? const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : DropdownButtonFormField<FlourProduct?>(
                                    decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      border: OutlineInputBorder(),
                                    ),
                                    value: selectedProduct,
                                    hint: const Text('Select a product'),
                                    isExpanded: true,
                                    items: [
                                      ...existingProducts.map(
                                        (product) =>
                                            DropdownMenuItem<FlourProduct>(
                                              value: product,
                                              child: Text(product.name),
                                            ),
                                      ),
                                      const DropdownMenuItem<FlourProduct?>(
                                        value: null,
                                        child: Text('+ Create new product'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        selectedProduct = value;
                                        isCreatingNewProduct = value == null;

                                        if (value != null) {
                                          // Set product details from selected product
                                          productController.text = value.name;
                                          priceController.text =
                                              value.pricePerKg.toString();
                                        } else {
                                          // Clear fields for new product
                                          productController.text = '';
                                          priceController.text = '';
                                        }
                                      });
                                    },
                                    validator:
                                        (value) =>
                                            (value == null &&
                                                    productController
                                                        .text
                                                        .isEmpty)
                                                ? 'Please select or create a product'
                                                : null,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Only show product name field if creating a new product
                    if (isCreatingNewProduct)
                      CustomTextField(
                        controller: productController,
                        label: 'New Product Name',
                        validator: (value) {
                          if (isCreatingNewProduct &&
                              (value == null || value.isEmpty)) {
                            return 'Please enter a product name';
                          }
                          return null;
                        },
                      ),
                    if (isCreatingNewProduct) const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: quantityController,
                            label: 'Quantity (kg)',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Invalid number';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: priceController,
                            label:
                                'Amount (${settingsProvider.currencySymbol})',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Invalid number';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: descriptionController,
                      label: 'Description (optional)',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Date: '),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (picked != null) {
                              setState(() {
                                selectedDate = picked;
                              });
                            }
                          },
                          child: Text(
                            DateFormat('MMM dd, yyyy').format(selectedDate),
                          ),
                        ),
                        const Spacer(),
                        const Text('Paid: '),
                        Switch(
                          value: isPaid,
                          onChanged: (value) {
                            setState(() {
                              isPaid = value;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          // Create product - either new or use existing
                          final product =
                              isCreatingNewProduct
                                  ? FlourProduct(
                                    id: DateTime.now().millisecondsSinceEpoch,
                                    name: productController.text.trim(),
                                    pricePerKg: double.parse(
                                      priceController.text,
                                    ),
                                    quantityInStock: double.parse(
                                      quantityController.text,
                                    ),
                                    description:
                                        descriptionController.text.isEmpty
                                            ? null
                                            : descriptionController.text.trim(),
                                  )
                                  : selectedProduct!;

                          final debt = Debt(
                            id:
                                isEditing
                                    ? debtToEdit.id
                                    : DateTime.now().millisecondsSinceEpoch,
                            customer: widget.customer,
                            product: product,
                            quantity: double.parse(quantityController.text),
                            amount: double.parse(priceController.text),
                            date: selectedDate,
                            isPaid: isPaid,
                            description:
                                descriptionController.text.isEmpty
                                    ? null
                                    : descriptionController.text.trim(),
                          );

                          if (isEditing) {
                            _updateDebt(debt);
                          } else {
                            _addDebt(debt);
                          }

                          Navigator.pop(context);
                        }
                      },
                      child: Text(isEditing ? 'Update' : 'Add'),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDebtItem(Debt debt) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isPaid = debt.isPaid;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      color: isPaid ? Colors.green.shade50 : Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                debt.product.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              '${settingsProvider.currencySymbol}${debt.amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${debt.quantity.toStringAsFixed(1)} kg'),
                Text(DateFormat('MMM dd, yyyy').format(debt.date)),
              ],
            ),
            if (debt.description != null && debt.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(debt.description!),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  backgroundColor:
                      isPaid ? Colors.green.shade100 : Colors.orange.shade100,
                  label: Text(isPaid ? 'Paid' : 'Unpaid'),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showDebtForm(debt),
                      tooltip: 'Edit',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDeleteDebt(debt),
                      tooltip: 'Delete',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.customer.name}\'s Debts'),
        backgroundColor: Colors.amber.shade700,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.amber.shade50,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Outstanding Debt',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${settingsProvider.currencySymbol}${_totalDebt.toStringAsFixed(settingsProvider.showDecimals ? 2 : 0)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color:
                              _totalDebt > 0
                                  ? Colors.red.shade700
                                  : Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showDebtForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Debt'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _debts.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 80,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No debts found',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add a debt to get started',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _debts.length,
                      itemBuilder: (context, index) {
                        final debt = _debts[index];
                        return _buildDebtItem(debt);
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
