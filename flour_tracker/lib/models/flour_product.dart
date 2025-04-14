class FlourProduct {
  final int? id;
  final String name;
  final double pricePerKg;
  final double quantityInStock;
  final String? description;

  FlourProduct({
    this.id,
    required this.name,
    required this.pricePerKg,
    required this.quantityInStock,
    this.description,
  });

  FlourProduct copyWith({
    int? id,
    String? name,
    double? pricePerKg,
    double? quantityInStock,
    String? description,
  }) {
    return FlourProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      quantityInStock: quantityInStock ?? this.quantityInStock,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'pricePerKg': pricePerKg,
      'quantityInStock': quantityInStock,
      'description': description,
    };
  }

  factory FlourProduct.fromMap(Map<String, dynamic> map) {
    return FlourProduct(
      id: map['id'],
      name: map['name'],
      pricePerKg: map['pricePerKg'],
      quantityInStock: map['quantityInStock'],
      description: map['description'],
    );
  }

  @override
  String toString() {
    return 'FlourProduct(id: $id, name: $name, pricePerKg: $pricePerKg, quantityInStock: $quantityInStock, description: $description)';
  }
}