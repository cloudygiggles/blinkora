import 'package:get/get.dart';
import '../../../data/providers/order_provider.dart';
import '../../../data/providers/address_provider.dart';
import '../../../data/providers/product_provider.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/order_item_model.dart';
import '../../../data/models/address_model.dart';

class OrderHistoryController extends GetxController {
  final OrderProvider orderProvider = Get.find<OrderProvider>();
  final AddressProvider addressProvider = Get.find<AddressProvider>();
  final ProductProvider productProvider = Get.find<ProductProvider>();

  var isLoading = false.obs;
  var orders = <Order>[].obs;

  // Mapping orderId ke list OrderItem
  var orderItemsMap = <int, List<OrderItem>>{}.obs;

  // Mapping orderId ke Address
  var orderAddressMap = <int, Address?>{}.obs;

  // Cache productId ke productName
  var productMap = <int, String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchOrderHistory();
  }

  Future<void> fetchOrderHistory() async {
    isLoading.value = true;

    // 1️⃣ Fetch orders
    await orderProvider.fetchOrderHistory();
    orders.value = orderProvider.orderHistory;

    // 2️⃣ Fetch semua produk sekaligus untuk cache
    final allProducts = await productProvider.getProducts();
    for (var product in allProducts) {
      productMap[product.id] = product.name;
    }

    // 3️⃣ Fetch order items & address per order
    for (var order in orders) {
      final items = await orderProvider.fetchOrderItems(order.id);
      orderItemsMap[order.id] = items;

      final address = await addressProvider.getAddressById(order.addressId);
      orderAddressMap[order.id] = address;
    }

    isLoading.value = false;
  }

  // Dapatkan nama produk dari productMap
  String getProductName(int productId) {
    return productMap[productId] ?? 'Produk';
  }
}
