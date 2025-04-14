class Customer {
  final int? id;
  final String name;
  final String? phoneNumber;
  final String? address;

  Customer({
    this.id,
    required this.name,
    this.phoneNumber,
    this.address,
  });

  Customer copyWith({
    int? id,
    String? name,
    String? phoneNumber,
    String? address,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'address': address,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'],
      phoneNumber: map['phoneNumber'],
      address: map['address'],
    );
  }

  @override
  String toString() {
    return 'Customer(id: $id, name: $name, phoneNumber: $phoneNumber, address: $address)';
  }
}