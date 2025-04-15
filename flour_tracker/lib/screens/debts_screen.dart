import 'package:flutter/material.dart';
import 'package:flour_tracker/models/customer.dart';
import 'package:flour_tracker/models/debt.dart';
import 'package:flour_tracker/providers/settings_provider.dart';
import 'package:flour_tracker/services/database_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Debt> _debts = [];
  bool _isLoading = true;
  bool _showOnlyUnpaid = true;

  @override
  void initState() {
    super.initState();
    _loadDebts();
  }

  Future<void> _loadDebts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final debts = await _databaseService.getDebts();
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

  List<Debt> get _filteredDebts {
    if (_showOnlyUnpaid) {
      return _debts.where((debt) => !debt.isPaid).toList();
    }
    return _debts;
  }

  double get _totalOutstandingDebt {
    return _debts
        .where((debt) => !debt.isPaid)
        .fold(0, (sum, debt) => sum + debt.amount);
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Müşteri Borçları'),
        backgroundColor: Colors.amber.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDebts,
            tooltip: 'Yenile',
          ),
          Switch(
            value: _showOnlyUnpaid,
            onChanged: (value) {
              setState(() {
                _showOnlyUnpaid = value;
              });
            },
            activeColor: Colors.white,
            activeTrackColor: Colors.amber.shade900,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey.shade400,
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                'Sadece Ödenmeyenler',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.amber.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Toplam Ödenmeyen Borç',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${settingsProvider.currencySymbol}${_totalOutstandingDebt.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color:
                        _totalOutstandingDebt > 0
                            ? Colors.red.shade700
                            : Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
          // Debts list
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredDebts.isEmpty
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
                            _showOnlyUnpaid
                                ? 'Ödenmemiş borç bulunamadı'
                                : 'Borç kaydı bulunamadı',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _showOnlyUnpaid
                                ? 'Tüm müşteriler borçlarını ödemiş'
                                : 'Hiçbir müşterinin kaydedilmiş borcu yok',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredDebts.length,
                      itemBuilder: (context, index) {
                        final debt = _filteredDebts[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        debt.customer.fullName,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            debt.isPaid
                                                ? Colors.green.shade100
                                                : Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        debt.isPaid ? 'Ödendi' : 'Ödenmedi',
                                        style: TextStyle(
                                          color:
                                              debt.isPaid
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
                                  'Ürün: ${debt.product.name}',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                Text(
                                  'Tarih: ${DateFormat(settingsProvider.dateFormat).format(debt.date)}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                if (debt.isPaid && debt.paidDate != null)
                                  Text(
                                    'Ödeme tarihi: ${DateFormat(settingsProvider.dateFormat).format(debt.paidDate!)}',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Miktar',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          Text(
                                            '${debt.quantity.toStringAsFixed(2)} kg',
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Tutar',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          Text(
                                            '${settingsProvider.currencySymbol}${debt.amount.toStringAsFixed(2)}',
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
                                if (!debt.isPaid) ...[
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            Navigator.pushNamed(
                                              context,
                                              '/customer_debts',
                                              arguments: debt.customer,
                                            );
                                          },
                                          icon: const Icon(Icons.person),
                                          label: const Text(
                                            'Müşteriyi Görüntüle',
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed:
                                              () => _markDebtAsPaid(debt),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.green.shade600,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                          ),
                                          icon: const Icon(Icons.check_circle),
                                          label: const Text(
                                            'Ödendi Olarak İşaretle',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Future<void> _markDebtAsPaid(Debt debt) async {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final bool confirm =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Borcu Ödenmiş Olarak İşaretle'),
                content: Text(
                  '${settingsProvider.currencySymbol}${debt.amount.toStringAsFixed(2)} tutarındaki bu borcu ödenmiş olarak işaretlemek istediğinizden emin misiniz?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('İptal'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Ödenmiş Olarak İşaretle',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirm && debt.id != null) {
      try {
        await _databaseService.markDebtAsPaid(debt.id!);
        _loadDebts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Borç başarıyla ödenmiş olarak işaretlendi'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Borç güncellenirken hata: $e')),
          );
        }
      }
    }
  }
}
