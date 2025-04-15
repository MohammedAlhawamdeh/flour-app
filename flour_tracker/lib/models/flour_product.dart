class FlourProduct {
  final int? id;
  final String name;
  final double pricePerKg;
  final double quantityInStock;
  final String? description;
  final String? category; // Kategori: ekmeklik, böreklik, etc.

  FlourProduct({
    this.id,
    required this.name,
    required this.pricePerKg,
    required this.quantityInStock,
    this.description,
    this.category,
  });

  // Add a getter for currentStock to avoid breaking existing code
  double get currentStock => quantityInStock;

  FlourProduct copyWith({
    int? id,
    String? name,
    double? pricePerKg,
    double? quantityInStock,
    String? description,
    String? category,
  }) {
    return FlourProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      quantityInStock: quantityInStock ?? this.quantityInStock,
      description: description ?? this.description,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'pricePerKg': pricePerKg,
      'quantityInStock': quantityInStock,
      'description': description,
      'category': category,
    };
  }

  factory FlourProduct.fromMap(Map<String, dynamic> map) {
    return FlourProduct(
      id: map['id'],
      name: map['name'],
      pricePerKg: map['pricePerKg'],
      quantityInStock: map['quantityInStock'],
      description: map['description'],
      category: map['category'],
    );
  }

  @override
  String toString() {
    return 'FlourProduct(id: $id, name: $name, pricePerKg: $pricePerKg, quantityInStock: $quantityInStock, description: $description, category: $category)';
  }
}
