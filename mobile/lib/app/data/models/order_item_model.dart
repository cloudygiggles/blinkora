import 'package:hive/hive.dart';

part 'order_item_model.g.dart';

@HiveType(typeId: 3)
class OrderItem {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final int orderId;

  @HiveField(2)
  final int productId;

  @HiveField(3)
  final int quantity;

  @HiveField(4)
  final int price;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.price,
  });

  // Untuk create order item baru
  factory OrderItem.create({
    required int orderId,
    required int productId,
    required int quantity,
    required int price,
  }) {
    return OrderItem(
      id: 0,
      orderId: orderId,
      productId: productId,
      quantity: quantity,
      price: price,
    );
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? 0,
      orderId: json['order_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      quantity: json['quantity'] ?? 1,
      price: json['price'] ?? 0,
    );
  }

  Map<String, dynamic> toJsonForCreate() {
    return {
      'order_id': orderId,
      'product_id': productId,
      'quantity': quantity,
      'price': price,
    };
  }

  @override
  String toString() {
    return 'OrderItem(orderId: $orderId, productId: $productId, qty: $quantity)';
  }
}
