import 'package:get/get.dart';
import '../../../data/services/product_data_service.dart';
import '../../../data/providers/order_provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../routes/app_pages.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/cart_item_model.dart';

class HomeController extends GetxController {
  final ProductDataService _productDataService = Get.find();
  final Connectivity _connectivity = Connectivity();
  final OrderProvider _orderProvider = Get.find<OrderProvider>();
  final AuthProvider _authProvider = Get.find<AuthProvider>();

  // ================= STATE =================
  final isLoading = false.obs;
  final products = <Product>[].obs;
  final filteredProducts = <Product>[].obs;
  final categories = <String>[].obs;
  final selectedCategory = ''.obs;
  final searchQuery = ''.obs;
  final errorMessage = ''.obs;
  final isOnline = true.obs;
  final isOfflineMode = false.obs;

  // ================= USER INFO =================
  final userName = ''.obs;
  final userEmail = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initUserInfo();
    _initConnectivity();
    fetchProducts();
  }

  Future<void> _initUserInfo() async {
    final user = _authProvider.currentUser;
    if (user != null) {
      userEmail.value = user.email ?? '';

      // Ambil nama dari metadata Supabase, atau dari table profiles jika ada
      final nameFromMetadata = user.userMetadata?['name'];
      if (nameFromMetadata != null) {
        userName.value = nameFromMetadata;
      } else {
        final roleData = await _authProvider.getUserRole(user.id);
        // bisa pakai roleData jika perlu
        userName.value = 'User'; // fallback
      }
    }
  }

  // ================= PRODUCT =================
  Future<void> fetchProducts() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      isOfflineMode.value = false;

      if (isOnline.value) {
        final fetchedProducts = await _productDataService.getProducts();
        final fetchedCategories = await _productDataService.getCategories();

        products.value = fetchedProducts;
        categories.value = fetchedCategories;
        filteredProducts.value = fetchedProducts;
      } else {
        _useCachedData();
      }
    } catch (_) {
      errorMessage.value = 'Gagal memuat produk';
      if (_productDataService.hasCachedData()) {
        _useCachedData();
      }
    } finally {
      isLoading.value = false;
    }
  }

  void _useCachedData() {
    products.value = _productDataService.getCachedProducts();
    categories.value = _productDataService.getCachedCategories();
    filteredProducts.value = products;
    isOfflineMode.value = true;
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
    _filterProducts();
  }

  void setCategory(String category) {
    selectedCategory.value = category;
    _filterProducts();
  }

  void _filterProducts() {
    var result = products.toList();

    if (selectedCategory.isNotEmpty) {
      result = result
          .where((p) => p.category == selectedCategory.value)
          .toList();
    }

    if (searchQuery.isNotEmpty) {
      result = result
          .where((p) =>
              p.name.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
              p.description.toLowerCase().contains(searchQuery.value.toLowerCase()))
          .toList();
    }

    filteredProducts.value = result;
  }

  void clearFilters() {
    selectedCategory.value = '';
    searchQuery.value = '';
    filteredProducts.value = products;
  }

  // ================= CART ACTION =================
  void addToCart(Product product) => _orderProvider.addToCart(product);
  void removeFromCart(int productId) => _orderProvider.removeFromCart(productId);

  // ================= NAVIGATION =================
  void goToCheckout() => Get.toNamed(Routes.CHECKOUT);
  void goToLocation() => Get.toNamed(Routes.LOCATION);
  void goToHistory() => Get.toNamed(Routes.HISTORY);
  void goToAddressList() => Get.toNamed(Routes.ADDRESS_LIST);

  // ================= CONNECTIVITY =================
  void _initConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    isOnline.value = result != ConnectivityResult.none;

    _connectivity.onConnectivityChanged.listen((r) {
      isOnline.value = r != ConnectivityResult.none;
      if (isOnline.value && isOfflineMode.value) {
        fetchProducts();
      }
    });
  }

  // ================= CART OBSERVABLE =================
  RxMap<int, int> get cartItems => _orderProvider.cartItemsMap;
  RxList<CartItem> get cartItemsList => _orderProvider.cartItemsList;
  RxBool get cartLoading => _orderProvider.isLoading;
  RxString get cartError => _orderProvider.errorMessage;
  int get cartItemCount => _orderProvider.totalItems;
  double get cartTotalPrice => _orderProvider.totalPriceDouble;
}
