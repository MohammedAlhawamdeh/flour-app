import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flour_tracker/models/customer.dart';
import 'package:flour_tracker/models/debt.dart';
import 'package:flour_tracker/models/expense.dart';
import 'package:flour_tracker/models/flour_product.dart';
import 'package:flour_tracker/models/sale.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:intl/intl.dart';
// Import sqlite3_flutter_libs to ensure SQLite is bundled
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  static bool _closing = false;
  static bool _opening = false;

  // Initialize database factory for desktop platforms
  static Future<void> initializeDatabaseFactory() async {
    // Ensure that the SQLite library is properly loaded
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      // Load the bundled SQLite library
      try {
        // The sqlite3_flutter_libs package is imported but doesn't need explicit initialization
        // It automatically makes the SQLite library available when imported

        // Initialize FFI for desktop
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        print("SQLite initialized successfully for desktop platform");
      } catch (e) {
        print("Error initializing SQLite: $e");
        rethrow;
      }
    }
  }

  Future<Database> get database async {
    if (_closing) {
      // Wait for closing to complete before trying to open
      while (_closing) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }
    
    if (_database != null) {
      // Check if the database is actually open
      try {
        await _database!.rawQuery('SELECT 1');
        return _database!;
      } catch (e) {
        print("Database was closed unexpectedly, reopening: $e");
        _database = null;
      }
    }

    // Prevent multiple simultaneous opening attempts
    if (_opening) {
      // Wait for the database to be opened by another call
      while (_opening && _database == null) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      if (_database != null) return _database!;
    }

    _opening = true;
    try {
      // Ensure database factory is initialized
      await initializeDatabaseFactory();
      _database = await _initDatabase();
      return _database!;
    } finally {
      _opening = false;
    }
  }

  Future<void> closeDatabase() async {
    if (_database != null && !_closing) {
      _closing = true;
      try {
        await _database!.close();
        _database = null;
        print("Database closed successfully");
      } catch (e) {
        print("Error closing database: $e");
      } finally {
        _closing = false;
      }
    }
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'flour_tracker.db');
    return await openDatabase(
      path,
      version: 4, // Increase version number from 3 to 4
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      // Add description column to debts table
      await db.execute('ALTER TABLE debts ADD COLUMN description TEXT');
    }

    if (oldVersion < 3) {
      // Add surname column to customers table
      await db.execute(
        'ALTER TABLE customers ADD COLUMN surname TEXT DEFAULT ""',
      );

      // Create expenses table
      await db.execute('''
        CREATE TABLE expenses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type TEXT NOT NULL,
          amount REAL NOT NULL,
          date TEXT NOT NULL,
          paymentMethod TEXT NOT NULL,
          description TEXT
        )
      ''');
    }

    if (oldVersion < 4) {
      // Add category column to products table for Turkish flour types (ekmeklik, böreklik, etc.)
      await db.execute('ALTER TABLE products ADD COLUMN category TEXT');
    }
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Create tables
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        pricePerKg REAL NOT NULL,
        quantityInStock REAL NOT NULL,
        description TEXT,
        category TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        surname TEXT NOT NULL,
        phoneNumber TEXT,
        address TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER NOT NULL,
        customerId INTEGER,
        quantity REAL NOT NULL,
        totalPrice REAL NOT NULL,
        date TEXT NOT NULL,
        isPaid INTEGER NOT NULL,
        FOREIGN KEY (productId) REFERENCES products (id),
        FOREIGN KEY (customerId) REFERENCES customers (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE debts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerId INTEGER NOT NULL,
        productId INTEGER NOT NULL,
        quantity REAL NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        isPaid INTEGER NOT NULL DEFAULT 0,
        paidDate TEXT,
        description TEXT,
        FOREIGN KEY (customerId) REFERENCES customers (id),
        FOREIGN KEY (productId) REFERENCES products (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        paymentMethod TEXT NOT NULL,
        description TEXT
      )
    ''');
  }

  // Product CRUD Operations
  Future<int> insertProduct(FlourProduct product) async {
    final db = await database;
    return await db.insert('products', product.toMap());
  }

  Future<List<FlourProduct>> getProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('products');
    return List.generate(maps.length, (i) {
      return FlourProduct.fromMap(maps[i]);
    });
  }

  Future<FlourProduct?> getProduct(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return FlourProduct.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateProduct(FlourProduct product) async {
    final db = await database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // Customer CRUD Operations
  Future<int> insertCustomer(Customer customer) async {
    final db = await database;
    return await db.insert('customers', customer.toMap());
  }

  Future<List<Customer>> getCustomers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('customers');
    return List.generate(maps.length, (i) {
      return Customer.fromMap(maps[i]);
    });
  }

  Future<Customer?> getCustomer(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Customer.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await database;
    return await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> deleteCustomer(int id) async {
    final db = await database;
    return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  // Sales CRUD Operations
  Future<int> insertSale(Sale sale) async {
    final db = await database;

    // Update inventory
    if (sale.product.id != null) {
      FlourProduct? product = await getProduct(sale.product.id!);
      if (product != null) {
        double newQuantity = product.quantityInStock - sale.quantity;
        await updateProduct(
          FlourProduct(
            id: product.id,
            name: product.name,
            pricePerKg: product.pricePerKg,
            quantityInStock: newQuantity,
            description: product.description,
          ),
        );
      }
    }

    return await db.insert('sales', sale.toMap());
  }

  Future<List<Sale>> getSales() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('sales');

    List<Sale> salesList = [];
    for (var map in maps) {
      final FlourProduct? product = await getProduct(map['productId']);
      Customer? customer;
      if (map['customerId'] != null) {
        customer = await getCustomer(map['customerId']);
      }

      if (product != null) {
        salesList.add(Sale.fromMap(map, product, customer));
      }
    }

    return salesList;
  }

  // Debt CRUD Operations
  Future<int> insertDebt(Debt debt) async {
    final db = await database;
    return await db.insert('debts', debt.toMap());
  }

  Future<List<Debt>> getDebts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('debts');

    List<Debt> debtsList = [];
    for (var map in maps) {
      final Customer? customer = await getCustomer(map['customerId']);
      final FlourProduct? product = await getProduct(map['productId']);

      if (customer != null && product != null) {
        debtsList.add(Debt.fromMap(map, customer, product));
      }
    }

    return debtsList;
  }

  Future<List<Debt>> getCustomerDebts(int customerId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'debts',
      where: 'customerId = ?',
      whereArgs: [customerId],
    );

    List<Debt> debtsList = [];
    for (var map in maps) {
      final Customer? customer = await getCustomer(map['customerId']);
      final FlourProduct? product = await getProduct(map['productId']);

      if (customer != null && product != null) {
        debtsList.add(Debt.fromMap(map, customer, product));
      }
    }

    return debtsList;
  }

  Future<int> markDebtAsPaid(int debtId) async {
    final db = await database;
    return await db.update(
      'debts',
      {'isPaid': 1, 'paidDate': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [debtId],
    );
  }

  // Alias for insertDebt to maintain API consistency
  Future<int> addDebt(Debt debt) async {
    return insertDebt(debt);
  }

  Future<int> updateDebt(Debt debt) async {
    final db = await database;
    return await db.update(
      'debts',
      debt.toMap(),
      where: 'id = ?',
      whereArgs: [debt.id],
    );
  }

  Future<int> deleteDebt(int id) async {
    final db = await database;
    return await db.delete('debts', where: 'id = ?', whereArgs: [id]);
  }

  // Expense CRUD Operations
  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return await db.insert('expenses', expense.toMap());
  }

  Future<List<Expense>> getExpenses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('expenses');
    return List.generate(maps.length, (i) {
      return Expense.fromMap(maps[i]);
    });
  }

  Future<List<Expense>> getExpensesByDate(DateTime date) async {
    final db = await database;
    final String dateStr = DateFormat('yyyy-MM-dd').format(date);
    final String startDate = '$dateStr 00:00:00.000';
    final String endDate = '$dateStr 23:59:59.999';

    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
    );

    return List.generate(maps.length, (i) {
      return Expense.fromMap(maps[i]);
    });
  }

  Future<Expense?> getExpense(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Expense.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAllData() async {
    final db = await database;
    // Delete data from all tables, careful with foreign key constraints
    // Delete in reverse order of dependencies
    await db.delete('debts');
    await db.delete('sales');
    await db.delete('customers');
    await db.delete('products');
  }
}
