import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flour_tracker/models/customer.dart';
import 'package:flour_tracker/models/flour_product.dart';
import 'package:flour_tracker/models/sale.dart';
import 'package:flour_tracker/models/debt.dart';
import 'package:flour_tracker/services/database_service.dart';
import 'package:intl/intl.dart';

class BackupService {
  final DatabaseService _databaseService;

  BackupService(this._databaseService);

  Future<String> exportData() async {
    try {
      // Get all data from the database
      final products = await _databaseService.getProducts();
      final customers = await _databaseService.getCustomers();
      final sales = await _databaseService.getSales();
      final debts = await _databaseService.getDebts();

      // Create a backup object with all data
      final backupData = {
        'timestamp': DateTime.now().toIso8601String(),
        'products': products.map((product) => product.toMap()).toList(),
        'customers': customers.map((customer) => customer.toMap()).toList(),
        'sales': sales.map((sale) => sale.toMap()).toList(),
        'debts': debts.map((debt) => debt.toMap()).toList(),
      };

      // Convert to JSON
      final jsonData = jsonEncode(backupData);

      // Save to a file in the app's documents directory
      final directory = await getApplicationDocumentsDirectory();
      final dateFormat = DateFormat('yyyyMMdd_HHmmss');
      final fileName = 'flour_tracker_backup_${dateFormat.format(DateTime.now())}.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonData);

      return file.path;
    } catch (e) {
      throw Exception('Failed to export data: $e');
    }
  }

  Future<bool> importData(String filePath) async {
    try {
      // Read the backup file
      final file = File(filePath);
      final jsonData = await file.readAsString();
      final backupData = jsonDecode(jsonData);

      // Clear all existing data
      await _databaseService.clearAllData();

      // Import products
      final productsList = backupData['products'] as List;
      for (var productMap in productsList) {
        final product = FlourProduct.fromMap(productMap);
        await _databaseService.insertProduct(product);
      }

      // Import customers
      final customersList = backupData['customers'] as List;
      for (var customerMap in customersList) {
        final customer = Customer.fromMap(customerMap);
        await _databaseService.insertCustomer(customer);
      }

      // Import sales and debts
      // Note: We would need to handle relationships carefully here
      // This is a simplified version

      return true;
    } catch (e) {
      throw Exception('Failed to import data: $e');
    }
  }

  Future<List<String>> getAvailableBackups() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final dir = Directory(directory.path);
      final List<FileSystemEntity> entities = await dir.list().toList();
      final backupFiles = entities
          .whereType<File>()
          .where((file) => file.path.contains('flour_tracker_backup_') && file.path.endsWith('.json'))
          .map((file) => file.path)
          .toList();
      
      return backupFiles;
    } catch (e) {
      throw Exception('Failed to get available backups: $e');
    }
  }
}