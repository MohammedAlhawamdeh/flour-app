class Customer {
  final int? id;
  final String name; // First name (Ad)
  final String surname; // Surname (Soyad)
  final String? phoneNumber;
  final String? address;

  Customer({
    this.id,
    required this.name,
    required this.surname,
    this.phoneNumber,
    this.address,
  });

  Customer copyWith({
    int? id,
    String? name,
    String? surname,
    String? phoneNumber,
    String? address,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      surname: surname ?? this.surname,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'surname': surname,
      'phoneNumber': phoneNumber,
      'address': address,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'],
      surname: map['surname'] ?? '', // Handle legacy data without surname
      phoneNumber: map['phoneNumber'],
      address: map['address'],
    );
  }

  String get fullName => '$name $surname'.trim();

  @override
  String toString() {
    return 'Customer(id: $id, name: $name, surname: $surname, phoneNumber: $phoneNumber, address: $address)';
  }
}
