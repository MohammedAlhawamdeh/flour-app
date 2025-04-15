class Expense {
  final int? id;
  final String type; // Type of expense (Gider türü)
  final double amount; // Amount (Tutar)
  final DateTime date; // Date (Tarih)
  final String paymentMethod; // Payment method (Nakit veya Kredi)
  final String? description; // Additional notes

  Expense({
    this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.paymentMethod,
    this.description,
  });

  Expense copyWith({
    int? id,
    String? type,
    double? amount,
    DateTime? date,
    String? paymentMethod,
    String? description,
  }) {
    return Expense(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'date': date.toIso8601String(),
      'paymentMethod': paymentMethod,
      'description': description,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      type: map['type'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      paymentMethod: map['paymentMethod'],
      description: map['description'],
    );
  }

  @override
  String toString() {
    return 'Expense(id: $id, type: $type, amount: $amount, date: $date, paymentMethod: $paymentMethod, description: $description)';
  }
}
