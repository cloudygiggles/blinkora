import 'package:get/get.dart';
import '../models/product_model.dart';
import '../providers/product_provider.dart';
import 'hive_service.dart';

class ProductDataService extends GetxService {
  final ProductProvider _productProvider = Get.find<ProductProvider>();
  final HiveService _hiveService = Get.find<HiveService>();

  Future<ProductDataService> init() async {
    return this;
  }

  // ============ READ OPERATIONS (For All Users) ============

  Future<List<Product>> getProducts() async {
    try {
      final products = await _productProvider.getProducts();
      await _hiveService.cacheProducts(products);
      return products;
    } catch (e) {
      if (_hiveService.hasCachedProducts()) {
        return _hiveService.getCachedProducts();
      }
      rethrow;
    }
  }

  Future<List<Product>> searchProducts(String query) async {
    try {
      return await _productProvider.searchProducts(query);
    } catch (e) {
      if (_hiveService.hasCachedProducts()) {
        return _hiveService.searchProducts(query);
      }
      rethrow;
    }
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      return await _productProvider.getProductsByCategory(category);
    } catch (e) {
      if (_hiveService.hasCachedProducts()) {
        return _hiveService.getProductsByCategory(category);
      }
      rethrow;
    }
  }

  Future<List<String>> getCategories() async {
    try {
      return await _productProvider.getCategories();
    } catch (e) {
      if (_hiveService.hasCachedProducts()) {
        return _hiveService.getCachedCategories();
      }
      rethrow;
    }
  }

  Future<Product?> getProductById(int id) async {
    try {
      return await _productProvider.getProductById(id);
    } catch (e) {
      if (_hiveService.hasCachedProducts()) {
        return _hiveService.getProductById(id);
      }
      rethrow;
    }
  }

  // ============ CACHE MANAGEMENT ============

  List<Product> getCachedProducts() {
    return _hiveService.getCachedProducts();
  }

  List<String> getCachedCategories() {
    return _hiveService.getCachedCategories();
  }

  bool hasCachedData() {
    return _hiveService.hasCachedProducts();
  }

  Future<List<Product>> refreshData() {
    return getProducts();
  }

  Future<void> clearCache() async {
    await _hiveService.clearCache();
  }
}