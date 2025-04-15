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
        ).showSnackBar(SnackBar(content: Text('Borçlar yüklenirken hata: $e')));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Borç başarıyla eklendi')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Borç eklenirken hata: $e')));
      }
    }
  }

  Future<void> _updateDebt(Debt debt) async {
    try {
      await _databaseService.updateDebt(debt);
      _loadDebts(); // Reload the list after updating
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Borç başarıyla güncellendi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Borç güncellenirken hata: $e')));
      }
    }
  }

  Future<void> _confirmDeleteDebt(Debt debt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Silmeyi Onayla'),
            content: Text(
              '${debt.product.name} için bu borç kaydını silmek istediğinizden emin misiniz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sil', style: TextStyle(color: Colors.red)),
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
        throw Exception('Null ID ile borç silinemez');
      }
      await _databaseService.deleteDebt(debt.id!);
      _loadDebts(); // Reload the list after deleting
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Borç başarıyla silindi')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Borç silinirken hata: $e')));
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
                      isEditing ? 'Borç Düzenle' : 'Yeni Borç Ekle',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Product selection section
                    Row(
                      children: [
                        const Text('Ürün: '),
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
                                    hint: const Text('Ürün seçin'),
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
                                        child: Text('+ Yeni ürün oluştur'),
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
                                                ? 'Lütfen bir ürün seçin veya oluşturun'
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
                        label: 'Yeni Ürün Adı',
                        validator: (value) {
                          if (isCreatingNewProduct &&
                              (value == null || value.isEmpty)) {
                            return 'Lütfen bir ürün adı girin';
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
                            label: 'Miktar (çuval)',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Gerekli';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Geçersiz sayı';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: priceController,
                            label: 'Tutar (${settingsProvider.currencySymbol})',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Gerekli';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Geçersiz sayı';
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
                      label: 'Açıklama (isteğe bağlı)',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Tarih: '),
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
                            DateFormat(
                              settingsProvider.dateFormat,
                            ).format(selectedDate),
                          ),
                        ),
                        const Spacer(),
                        const Text('Ödendi: '),
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
                      child: Text(isEditing ? 'Güncelle' : 'Ekle'),
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
                Text('${debt.quantity.toStringAsFixed(1)} çuval'),
                Text(DateFormat(settingsProvider.dateFormat).format(debt.date)),
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
                // Payment status toggle switch
                Row(
                  children: [
                    Icon(
                      isPaid ? Icons.check_circle : Icons.pending_actions,
                      color: isPaid ? Colors.green.shade700 : Colors.orange.shade700,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isPaid ? 'Ödendi' : 'Ödenmedi',
                      style: TextStyle(
                        color: isPaid ? Colors.green.shade700 : Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Switch(
                      value: isPaid,
                      activeColor: Colors.green.shade700,
                      onChanged: (value) {
                        final updatedDebt = debt.copyWith(
                          isPaid: value,
                          paidDate: value ? DateTime.now() : null,
                        );
                        _updateDebt(updatedDebt);
                      },
                    ),
                  ],
                ),
                // Edit and delete buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showDebtForm(debt),
                      tooltip: 'Düzenle',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDeleteDebt(debt),
                      tooltip: 'Sil',
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
        title: Text('${widget.customer.fullName} Borçları'),
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
                        'Toplam Borç Miktarı',
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
                  label: const Text('Borç Ekle'),
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
                            'Borç kaydı bulunamadı',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Başlamak için borç ekleyin',
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
