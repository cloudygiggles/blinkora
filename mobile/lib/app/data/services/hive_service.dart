import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../models/product_model.dart';

class HiveService extends GetxService {
  static const String _productsBox = 'products_box';
  late Box<Product> _productsBoxInstance;

  Future<HiveService> init() async {
    _productsBoxInstance = await Hive.openBox<Product>(_productsBox);
    return this;
  }

  // Save products to cache
  Future<void> cacheProducts(List<Product> products) async {
    await _productsBoxInstance.clear();
    for (final product in products) {
      await _productsBoxInstance.put(product.id, product);
    }
  }

  // Get cached products
  List<Product> getCachedProducts() {
    return _productsBoxInstance.values.toList();
  }

  // Check if cache exists
  bool hasCachedProducts() {
    return _productsBoxInstance.isNotEmpty;
  }

  // Get products by category from cache
  List<Product> getProductsByCategory(String category) {
    final products = getCachedProducts();
    return products.where((product) => product.category == category).toList();
  }

  // Search products in cache
  List<Product> searchProducts(String query) {
    final products = getCachedProducts();
    if (query.isEmpty) return products;
    
    return products.where((product) =>
      product.name.toLowerCase().contains(query.toLowerCase()) ||
      product.category.toLowerCase().contains(query.toLowerCase()) ||
      product.description.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  // Get all unique categories from cache
  List<String> getCachedCategories() {
    final products = getCachedProducts();
    final categories = products.map((product) => product.category).toSet().toList();
    categories.sort();
    return categories;
  }

  // Get specific product by id
  Product? getProductById(int id) {
    return _productsBoxInstance.get(id);
  }

  // Clear cache
  Future<void> clearCache() async {
    await _productsBoxInstance.clear();
  }

  // Get cache count
  int getCacheCount() {
    return _productsBoxInstance.length;
  }

  @override
  void onClose() {
    _productsBoxInstance.close();
    super.onClose();
  }
}