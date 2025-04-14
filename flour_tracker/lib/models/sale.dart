import 'package:flour_tracker/models/customer.dart';
import 'package:flour_tracker/models/flour_product.dart';

class Sale {
  final int? id;
  final FlourProduct product;
  final Customer? customer;
  final double quantity;
  final double pricePerKg;
  final double totalPrice;
  final bool isPaid;
  final DateTime date;

  Sale({
    this.id,
    required this.product,
    this.customer,
    required this.quantity,
    required this.pricePerKg,
    required this.totalPrice,
    required this.isPaid,
    required this.date,
  });

  Sale copyWith({
    int? id,
    FlourProduct? product,
    Customer? customer,
    double? quantity,
    double? pricePerKg,
    double? totalPrice,
    bool? isPaid,
    DateTime? date,
  }) {
    return Sale(
      id: id ?? this.id,
      product: product ?? this.product,
      customer: customer ?? this.customer,
      quantity: quantity ?? this.quantity,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      totalPrice: totalPrice ?? this.totalPrice,
      isPaid: isPaid ?? this.isPaid,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': product.id,
      'customerId': customer?.id,
      'quantity': quantity,
      'pricePerKg': pricePerKg,
      'totalPrice': totalPrice,
      'isPaid': isPaid ? 1 : 0,
      'date': date.toIso8601String(),
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map, FlourProduct product, [Customer? customer]) {
    return Sale(
      id: map['id'],
      product: product,
      customer: customer,
      quantity: map['quantity'],
      pricePerKg: map['pricePerKg'],
      totalPrice: map['totalPrice'],
      isPaid: map['isPaid'] == 1,
      date: DateTime.parse(map['date']),
    );
  }

  @override
  String toString() {
    return 'Sale(id: $id, product: ${product.name}, customer: ${customer?.name}, quantity: $quantity, pricePerKg: $pricePerKg, totalPrice: $totalPrice, isPaid: $isPaid, date: $date)';
  }
}