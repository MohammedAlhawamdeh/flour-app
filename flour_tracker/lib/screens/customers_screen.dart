import 'package:flutter/material.dart';
import 'package:flour_tracker/models/customer.dart';
import 'package:flour_tracker/services/database_service.dart';
import 'package:provider/provider.dart';
import 'package:flour_tracker/providers/settings_provider.dart';
import 'package:flour_tracker/widgets/custom_text_field.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Customer> _customers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final customers = await _databaseService.getCustomers();
      setState(() {
        _customers = customers;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading customers: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Management'),
        backgroundColor: Colors.amber.shade700,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _customers.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.people_outline,
                      size: 80,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No customers found',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add a customer to get started',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _customers.length,
                itemBuilder: (context, index) {
                  final customer = _customers[index];
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
                                  customer.name,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.account_balance_wallet,
                                    ),
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/customer_debts',
                                        arguments: customer,
                                      );
                                    },
                                    color: Colors.amber.shade700,
                                    tooltip: 'View Debts',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed:
                                        () => _showCustomerForm(customer),
                                    color: Colors.blue,
                                    tooltip: 'Edit',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _deleteCustomer(customer),
                                    color: Colors.red,
                                    tooltip: 'Delete',
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (customer.phoneNumber != null &&
                              customer.phoneNumber!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.phone, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    customer.phoneNumber!,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          if (customer.address != null &&
                              customer.address!.isNotEmpty)
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    customer.address!,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCustomerForm(),
        backgroundColor: Colors.amber.shade700,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showCustomerForm([Customer? customer]) async {
    final TextEditingController nameController = TextEditingController(
      text: customer?.name ?? '',
    );
    final TextEditingController phoneController = TextEditingController(
      text: customer?.phoneNumber ?? '',
    );
    final TextEditingController addressController = TextEditingController(
      text: customer?.address ?? '',
    );

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
                customer == null ? 'Add New Customer' : 'Edit Customer',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Form(
                key: formKey,
                child: Column(
                  children: [
                    CustomTextField(
                      label: 'Customer Name',
                      controller: nameController,
                    ),
                    CustomTextField(
                      label: 'Phone Number (Optional)',
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      isRequired: false,
                    ),
                    CustomTextField(
                      label: 'Address (Optional)',
                      controller: addressController,
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

                    final Customer newCustomer = Customer(
                      id: customer?.id,
                      name: nameController.text,
                      phoneNumber:
                          phoneController.text.isEmpty
                              ? null
                              : phoneController.text,
                      address:
                          addressController.text.isEmpty
                              ? null
                              : addressController.text,
                    );

                    try {
                      if (customer == null) {
                        await _databaseService.insertCustomer(newCustomer);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Customer added successfully'),
                          ),
                        );
                      } else {
                        await _databaseService.updateCustomer(newCustomer);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Customer updated successfully'),
                          ),
                        );
                      }
                      _loadCustomers();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error saving customer: $e')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  customer == null ? 'Add Customer' : 'Update Customer',
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

  Future<void> _deleteCustomer(Customer customer) async {
    final bool confirm =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Delete Customer'),
                content: Text(
                  'Are you sure you want to delete ${customer.name}? This action cannot be undone and will remove all associated debts.',
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
        ) ??
        false;

    if (confirm && customer.id != null) {
      try {
        await _databaseService.deleteCustomer(customer.id!);
        _loadCustomers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Customer deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting customer: $e')),
          );
        }
      }
    }
  }
}
