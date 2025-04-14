import 'package:flour_tracker/models/customer.dart';
import 'package:flour_tracker/models/flour_product.dart';

class Debt {
  final int? id;
  final Customer customer;
  final FlourProduct product;
  final double quantity;
  final double amount;
  final DateTime date;
  final bool isPaid;
  final DateTime? paidDate;
  final String? description;

  Debt({
    this.id,
    required this.customer,
    required this.product,
    required this.quantity,
    required this.amount,
    required this.date,
    required this.isPaid,
    this.paidDate,
    this.description,
  });

  Debt copyWith({
    int? id,
    Customer? customer,
    FlourProduct? product,
    double? quantity,
    double? amount,
    DateTime? date,
    bool? isPaid,
    DateTime? paidDate,
    String? description,
  }) {
    return Debt(
      id: id ?? this.id,
      customer: customer ?? this.customer,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      isPaid: isPaid ?? this.isPaid,
      paidDate: paidDate ?? this.paidDate,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customer.id,
      'productId': product.id,
      'quantity': quantity,
      'amount': amount,
      'date': date.toIso8601String(),
      'isPaid': isPaid ? 1 : 0,
      'paidDate': paidDate?.toIso8601String(),
      'description': description,
    };
  }

  factory Debt.fromMap(
    Map<String, dynamic> map,
    Customer customer,
    FlourProduct product,
  ) {
    return Debt(
      id: map['id'],
      customer: customer,
      product: product,
      quantity: map['quantity'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      isPaid: map['isPaid'] == 1,
      paidDate:
          map['paidDate'] != null ? DateTime.parse(map['paidDate']) : null,
      description: map['description'],
    );
  }

  @override
  String toString() {
    return 'Debt(id: $id, customer: ${customer.name}, product: ${product.name}, quantity: $quantity, amount: $amount, date: $date, isPaid: $isPaid, paidDate: $paidDate, description: $description)';
  }
}
