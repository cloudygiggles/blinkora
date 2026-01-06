// models/cart_item_model.dart
import 'package:hive/hive.dart';
import 'product_model.dart';

part 'cart_item_model.g.dart'; // Untuk Hive generator

@HiveType(typeId: 4)
class CartItem extends HiveObject {
  @HiveField(0)
  final Product product;
  
  @HiveField(1)
  int quantity;
  
  CartItem({
    required this.product,
    this.quantity = 1,
  });
  
  int get totalPrice => product.price * quantity;
}

// models/cart_item_model.g.dart (akan di-generate)
// Jalankan: flutter pub run build_runner build