import 'package:flutter/material.dart';
import 'package:flour_tracker/models/expense.dart';
import 'package:flour_tracker/services/database_service.dart';
import 'package:flour_tracker/widgets/custom_text_field.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flour_tracker/providers/settings_provider.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Expense> _expenses = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final expenses = await _databaseService.getExpensesByDate(_selectedDate);
      setState(() {
        _expenses = expenses;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Giderler yüklenirken hata: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  double get _totalExpensesForDay {
    return _expenses.fold(0, (sum, expense) => sum + expense.amount);
  }

  Future<void> _showDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadExpenses();
    }
  }

  void _showExpenseForm([Expense? expenseToEdit]) {
    final formKey = GlobalKey<FormState>();
    final isEditing = expenseToEdit != null;

    // Form field controllers
    final typeController = TextEditingController(
      text: isEditing ? expenseToEdit.type : '',
    );
    final amountController = TextEditingController(
      text: isEditing ? expenseToEdit.amount.toString() : '',
    );
    final descriptionController = TextEditingController(
      text: isEditing ? expenseToEdit.description ?? '' : '',
    );

    DateTime selectedDate = isEditing ? expenseToEdit.date : _selectedDate;
    String paymentMethod = isEditing ? expenseToEdit.paymentMethod : 'Nakit';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final settingsProvider = Provider.of<SettingsProvider>(context);

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
                      isEditing ? 'Gider Düzenle' : 'Yeni Gider Ekle',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: typeController,
                      label: 'Gider Türü',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Gider türü gerekli';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: amountController,
                      label: 'Tutar (${settingsProvider.currencySymbol})',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Tutar gerekli';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Geçersiz sayı';
                        }
                        return null;
                      },
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
                        const Text('Ödeme Yöntemi: '),
                      ],
                    ),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(),
                      ),
                      value: paymentMethod,
                      items: const [
                        DropdownMenuItem(value: 'Nakit', child: Text('Nakit')),
                        DropdownMenuItem(value: 'Kredi', child: Text('Kredi')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          paymentMethod = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          final expense = Expense(
                            id: isEditing ? expenseToEdit.id : null,
                            type: typeController.text.trim(),
                            amount: double.parse(amountController.text),
                            date: selectedDate,
                            paymentMethod: paymentMethod,
                            description:
                                descriptionController.text.isEmpty
                                    ? null
                                    : descriptionController.text.trim(),
                          );

                          if (isEditing) {
                            _updateExpense(expense);
                          } else {
                            _addExpense(expense);
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

  Future<void> _addExpense(Expense expense) async {
    try {
      await _databaseService.insertExpense(expense);
      _loadExpenses(); // Reload the list after adding
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gider başarıyla eklendi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gider eklenirken hata: $e')));
      }
    }
  }

  Future<void> _updateExpense(Expense expense) async {
    try {
      await _databaseService.updateExpense(expense);
      _loadExpenses(); // Reload the list after updating
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gider başarıyla güncellendi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gider güncellenirken hata: $e')),
        );
      }
    }
  }

  Future<void> _confirmDeleteExpense(Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Silmeyi Onayla'),
            content: Text(
              'Bu gider kaydını silmek istediğinizden emin misiniz?',
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
      _deleteExpense(expense);
    }
  }

  Future<void> _deleteExpense(Expense expense) async {
    try {
      if (expense.id == null) {
        throw Exception('Null ID ile gider silinemez');
      }
      await _databaseService.deleteExpense(expense.id!);
      _loadExpenses(); // Reload the list after deleting
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gider başarıyla silindi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gider silinirken hata: $e')));
      }
    }
  }

  Widget _buildExpenseItem(Expense expense) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                expense.type,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              '${settingsProvider.currencySymbol}${expense.amount.toStringAsFixed(2)}',
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
                Text('Ödeme: ${expense.paymentMethod}'),
                Text(
                  DateFormat(settingsProvider.dateFormat).format(expense.date),
                ),
              ],
            ),
            if (expense.description != null &&
                expense.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(expense.description!),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showExpenseForm(expense),
                  tooltip: 'Düzenle',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDeleteExpense(expense),
                  tooltip: 'Sil',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
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
        title: const Text('Günlük Giderler'),
        backgroundColor: Colors.amber.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _showDatePicker,
            tooltip: 'Tarih Seç',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadExpenses,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.amber.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat(
                    settingsProvider.dateFormat,
                    'tr',
                  ).format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Toplam Gider: ${settingsProvider.currencySymbol}${_totalExpensesForDay.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _expenses.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.receipt_long_outlined,
                            size: 80,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Bu tarihte gider kaydı yok',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Gider eklemek için + butonuna tıklayın',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _expenses.length,
                      itemBuilder: (context, index) {
                        final expense = _expenses[index];
                        return _buildExpenseItem(expense);
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showExpenseForm(),
        tooltip: 'Gider Ekle',
        backgroundColor: Colors.amber.shade700,
        child: const Icon(Icons.add),
      ),
    );
  }
}
