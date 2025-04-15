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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ürünler yüklenirken hata: $e')));
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
        title: const Text('Stok Yönetimi'),
        backgroundColor: Colors.amber.shade700,
      ),
      body:
          _isLoading
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
                      'Ürün bulunamadı',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Başlamak için bir ürün ekleyin',
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (product.category != null &&
                                        product.category!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          product.category!,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.amber.shade900,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _showProductForm(product),
                                    color: Colors.blue,
                                    tooltip: 'Düzenle',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _deleteProduct(product),
                                    color: Colors.red,
                                    tooltip: 'Sil',
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildInfoItem(
                                'Kg Başına Fiyat',
                                '${settingsProvider.currencySymbol}${product.pricePerKg.toStringAsFixed(settingsProvider.showDecimals ? 2 : 0)}',
                                _getCurrencyIcon(
                                  settingsProvider.currencySymbol,
                                ),
                              ),
                              const SizedBox(width: 16),
                              _buildInfoItem(
                                'Stok Miktarı',
                                '${product.quantityInStock.toStringAsFixed(settingsProvider.showDecimals ? 2 : 0)} çuval',
                                Icons.inventory,
                              ),
                            ],
                          ),
                          if (product.description != null &&
                              product.description!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Açıklama: ${product.description}',
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
        tooltip: 'Ürün Ekle',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.amber.shade700),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
      case '₺':
        return Icons.currency_lira;
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
    final TextEditingController nameController = TextEditingController(
      text: product?.name ?? '',
    );
    final TextEditingController priceController = TextEditingController(
      text: product?.pricePerKg.toString() ?? '',
    );
    final TextEditingController quantityController = TextEditingController(
      text: product?.quantityInStock.toString() ?? '',
    );
    final TextEditingController descriptionController = TextEditingController(
      text: product?.description ?? '',
    );

    String selectedCategory = product?.category ?? 'Ekmeklik';
    final formKey = GlobalKey<FormState>();

    // Common Turkish flour categories
    final List<String> flourCategories = [
      'Ekmeklik', // Bread flour
      'Böreklik', // Pastry flour
      'Poğaçalık', // Biscuit/roll flour
      'Çöreklik', // Sweet pastry flour
      'Baklavalik', // Baklava flour
      'Keklik', // Cake flour
      'Simitlik', // Bagel flour
      'Pidecik', // Flatbread flour
      'Genel Amaçlı', // All-purpose flour
      'Diğer', // Other
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final settingsProvider = Provider.of<SettingsProvider>(context);
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
                    product == null ? 'Yeni Ürün Ekle' : 'Ürün Düzenle',
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
                          label: 'Ürün Adı',
                          controller: nameController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ürün adı gerekli';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Un Kategorisi',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                          ),
                          value: selectedCategory,
                          items:
                              flourCategories
                                  .map(
                                    (category) => DropdownMenuItem(
                                      value: category,
                                      child: Text(category),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCategory = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          label:
                              'Kg Başına Fiyat (${settingsProvider.currencySymbol})',
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Fiyat gerekli';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Lütfen geçerli bir sayı girin';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          label: 'Stok Miktarı (çuval)',
                          controller: quantityController,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Miktar gerekli';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Lütfen geçerli bir sayı girin';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          label: 'Açıklama (İsteğe bağlı)',
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
                          quantityInStock: double.parse(
                            quantityController.text,
                          ),
                          description:
                              descriptionController.text.isEmpty
                                  ? null
                                  : descriptionController.text,
                          category: selectedCategory,
                        );

                        try {
                          if (product == null) {
                            await _databaseService.insertProduct(newProduct);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Ürün başarıyla eklendi'),
                              ),
                            );
                          } else {
                            await _databaseService.updateProduct(newProduct);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Ürün başarıyla güncellendi'),
                              ),
                            );
                          }
                          _loadProducts();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Ürün kaydedilirken hata: $e'),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      product == null ? 'Ürün Ekle' : 'Ürünü Güncelle',
                      style: const TextStyle(fontSize: 16),
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

  Future<void> _deleteProduct(FlourProduct product) async {
    final bool confirm =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Ürünü Sil'),
                content: Text(
                  '${product.name} ürününü silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('İptal'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Sil',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirm && product.id != null) {
      try {
        await _databaseService.deleteProduct(product.id!);
        _loadProducts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ürün başarıyla silindi')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Ürün silinirken hata: $e')));
        }
      }
    }
  }
}
