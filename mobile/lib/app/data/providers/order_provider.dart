import 'dart:async';
import 'package:blinkora/app/data/models/order_item_model.dart';
import 'package:blinkora/app/data/models/order_model.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../services/supabase_service.dart';
import './address_provider.dart';

class OrderProvider extends GetxController {
  static const String cartBoxName = 'cart_box';

  final SupabaseService _supabase = Get.find<SupabaseService>();
  final AddressProvider addressProvider = Get.find<AddressProvider>();
  late Box<CartItem> _cartBox;

  // ========================
  // STATE RX
  // ========================
  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var cartItemsMap = <int, int>{}.obs; // Map<ProductId, Quantity>
  var cartItemsList = <CartItem>[].obs; // Full CartItem list
  var orderHistory = <Order>[].obs;
  var allOrders = <Order>[].obs;
  // ========================
  // INIT
  // ========================
  Future<OrderProvider> init() async {
    _cartBox = await Hive.openBox<CartItem>(cartBoxName);
    _loadCartFromBox();
    return this;
  }

  void _loadCartFromBox() {
    final items = _cartBox.values.toList();
    cartItemsList.value = items;

    final map = <int, int>{};
    for (final item in items) {
      map[item.product.id] = item.quantity;
    }
    cartItemsMap.value = map;
  }

  // ========================
  // DERIVED GETTERS
  // ========================
  bool get isCartEmpty => cartItemsList.isEmpty;
  int get totalItems =>
      cartItemsList.fold(0, (sum, item) => sum + item.quantity);
  double get totalPriceDouble =>
      cartItemsList.fold(0, (sum, item) => sum + item.totalPrice).toDouble();

  // ========================
  // CART CRUD
  // ========================
  void addToCart(Product product) {
    final key = _cartBox.keys.firstWhere(
      (k) => _cartBox.get(k)!.product.id == product.id,
      orElse: () => null,
    );

    if (key != null) {
      final item = _cartBox.get(key)!;
      item.quantity++;
      item.save();
    } else {
      _cartBox.add(CartItem(product: product));
    }

    _loadCartFromBox();
  }

  void updateQuantity(Product product, int quantity) {
    if (quantity <= 0) {
      removeFromCart(product.id);
      return;
    }

    final key = _cartBox.keys.firstWhere(
      (k) => _cartBox.get(k)!.product.id == product.id,
      orElse: () => null,
    );

    if (key != null) {
      final item = _cartBox.get(key)!;
      item.quantity = quantity;
      item.save();
    }

    _loadCartFromBox();
  }

  void removeFromCart(int productId) {
    final key = _cartBox.keys.firstWhere(
      (k) => _cartBox.get(k)!.product.id == productId,
      orElse: () => null,
    );

    if (key != null) _cartBox.delete(key);
    _loadCartFromBox();
  }

  void clearCart() {
    _cartBox.clear();

    // pastikan Rx benar-benar ter-refresh
    cartItemsList.clear();
    cartItemsList.refresh();

    cartItemsMap.clear();
    cartItemsMap.refresh();
  }

  // ========================
  // CHECKOUT
  // ========================
  Future<bool> checkout() async {
    if (isCartEmpty) {
      errorMessage.value = 'Keranjang kosong';
      return false;
    }

    final user = _supabase.currentUser;
    if (user == null) {
      errorMessage.value = 'User belum login';
      return false;
    }

    if (addressProvider.address.value == null) {
      errorMessage.value = 'Alamat pengiriman belum diatur';
      return false;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      // 1️⃣ Create order
      final order = await _supabase
          .from('orders')
          .insert({
            'user_id': user.id,
            'total_price': cartItemsList.fold(
              0,
              (sum, item) => sum + item.totalPrice,
            ),
            'status': 'pending',
            'address_id': addressProvider.address.value!.id,
          })
          .select()
          .single();

      final int orderId = order['id'];

      // 2️⃣ Create order items
      final items = cartItemsList.map((item) {
        return {
          'order_id': orderId,
          'product_id': item.product.id,
          'quantity': item.quantity,
          'price': item.product.price,
        };
      }).toList();

      await _supabase.from('order_items').insert(items);

      // 3️⃣ Clear cart
      clearCart();

      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchOrderHistory() async {
    final user = _supabase.currentUser;
    if (user == null) return;

    try {
      isLoading.value = true;

      final data = await _supabase
          .from('orders')
          .select('*, order_items(*)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      orderHistory.value = data.map<Order>((json) {
        // Mapping order items
        final itemsJson = json['order_items'] as List<dynamic>? ?? [];
        final items = itemsJson.map<OrderItem>((item) {
          return OrderItem(
            id: item['id'] ?? 0,
            orderId: item['order_id'] ?? 0,
            productId: item['product_id'] ?? 0,
            quantity: item['quantity'] ?? 1,
            price: item['price'] ?? 0,
          );
        }).toList();

        return Order(
          id: json['id'] ?? 0,
          userId: json['user_id'] ?? '',
          totalPrice: json['total_price'] ?? 0,
          status: json['status'] ?? 'pending',
          createdAt: json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
          updatedAt: json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
          addressId: json['address_id'] ?? 0, // mapping address_id
        );
      }).toList();

      print('🚀 Order history fetched: ${orderHistory.length} items');
    } catch (e) {
      print('❌ Failed to fetch order history: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<OrderItem>> fetchOrderItems(int orderId) async {
    final user = _supabase.currentUser;
    if (user == null) return [];

    try {
      final data = await _supabase
          .from('order_items')
          .select()
          .eq('order_id', orderId);

      return data.map<OrderItem>((json) => OrderItem.fromJson(json)).toList();
    } catch (e) {
      print('❌ Failed to fetch order items for order $orderId: $e');
      return [];
    }
  }

  Future<void> fetchAllOrders() async {
    try {
      isLoading.value = true;

      // Mengambil data orders, item didalamnya, dan informasi user terkait
      final data = await _supabase
          .from('orders')
          .select('*, order_items(*)')
          .order('created_at', ascending: false);

      allOrders.value = data.map<Order>((json) {
        return Order.fromJson(
          json,
        ); // Pastikan model Order Anda punya fromJson yang menghandle list items
      }).toList();

      print('🚀 Total ${allOrders.length} orders fetched for Admin');
    } catch (e) {
      errorMessage.value = "Gagal mengambil semua pesanan: $e";
    } finally {
      isLoading.value = false;
    }
  }

  /// Memperbarui status pesanan (e.g. pending -> shipping -> completed)
  Future<bool> updateOrderStatus(int orderId, String newStatus) async {
    try {
      isLoading.value = true;

      await _supabase
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId);

      // Update local state agar UI langsung berubah tanpa fetch ulang full
      int index = allOrders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        allOrders[index] = allOrders[index].copyWith(status: newStatus);
        allOrders.refresh();
      }

      return true;
    } catch (e) {
      errorMessage.value = "Gagal update status: $e";
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
