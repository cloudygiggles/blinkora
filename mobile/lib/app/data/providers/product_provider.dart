import 'package:get/get.dart';
import '../models/product_model.dart';
import '../services/supabase_service.dart';
import 'package:postgrest/postgrest.dart';

class ProductProvider extends GetxService {
  final SupabaseService _supabaseService = Get.find<SupabaseService>();

  Future<ProductProvider> init() async => this;

  // ========================================
  // READ OPERATIONS
  // ========================================

  Future<List<Product>> getProducts() async {
    try {
      final data = await _supabaseService.client
          .from('products')
          .select()
          .order('created_at', ascending: false);

      return List.from(data).map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  Future<List<Product>> searchProducts(String query) async {
    try {
      final data = await _supabaseService.client
          .from('products')
          .select()
          .ilike('name', '%$query%')
          .order('created_at', ascending: false);

      return List.from(data).map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final data = await _supabaseService.client
          .from('products')
          .select()
          .eq('category', category)
          .order('created_at', ascending: false);

      return List.from(data).map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch products by category: $e');
    }
  }

  Future<List<String>> getCategories() async {
    try {
      final data = await _supabaseService.client
          .from('products')
          .select('category')
          .order('category');

      final categories = List.from(
        data,
      ).map((item) => item['category'] as String).toSet().toList();

      categories.sort();
      return categories;
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  Future<Product?> getProductById(int id) async {
    try {
      final data = await _supabaseService.client
          .from('products')
          .select()
          .eq('id', id)
          .single();

      return Product.fromJson(data);
    } catch (e) {
      throw Exception('Failed to fetch product: $e');
    }
  }

  // ========================================
  // CREATE OPERATIONS
  // ========================================

  Future<Product> createProduct(Product product) async {
    try {
      final data = await _supabaseService.client
          .from('products')
          .insert(product.toJsonForCreate())
          .select()
          .single();

      return Product.fromJson(data);
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  Future<List<Product>> createProducts(List<Product> products) async {
    try {
      final jsonList = products.map((p) => p.toJson()).toList();

      final data = await _supabaseService.client
          .from('products')
          .insert(jsonList)
          .select();

      return List.from(data).map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to create products: $e');
    }
  }

  // ========================================
  // UPDATE OPERATIONS
  // ========================================

  Future<Product> updateProduct(Product product) async {
    try {
      final data = await _supabaseService.client
          .from('products')
          .update(product.toJson())
          .eq('id', product.id)
          .select()
          .single();

      return Product.fromJson(data);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  Future<Product> updateProductPartial({
    required int id,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final data = await _supabaseService.client
          .from('products')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return Product.fromJson(data);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  Future<Product> updateProductPrice(int id, int newPrice) async {
    return updateProductPartial(
      id: id,
      updates: {
        'price': newPrice,
        'updated_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<Product> updateProductStock(int id, int newStock) async {
    return updateProductPartial(
      id: id,
      updates: {
        'stock': newStock,
        'updated_at': DateTime.now().toIso8601String(),
      },
    );
  }

  // ========================================
  // DELETE OPERATIONS
  // ========================================

  Future<void> deleteProduct(int id) async {
    try {
      await _supabaseService.client.from('products').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  Future<void> deleteProducts(List<int> ids) async {
    try {
      await _supabaseService.client
          .from('products')
          .delete()
          .inFilter('id', ids);
    } catch (e) {
      throw Exception('Failed to delete products: $e');
    }
  }

  Future<void> deleteProductsByCategory(String category) async {
    try {
      await _supabaseService.client
          .from('products')
          .delete()
          .eq('category', category);
    } catch (e) {
      throw Exception('Failed to delete products by category: $e');
    }
  }

  // ========================================
  // BATCH OPERATIONS
  // ========================================

  Future<Product> upsertProduct(Product product) async {
    try {
      final data = await _supabaseService.client
          .from('products')
          .upsert(product.toJson())
          .select()
          .single();

      return Product.fromJson(data);
    } catch (e) {
      throw Exception('Failed to upsert product: $e');
    }
  }

  Future<List<Product>> bulkUpdateProducts(List<Product> products) async {
    try {
      final jsonList = products.map((p) => p.toJson()).toList();

      final data = await _supabaseService.client
          .from('products')
          .upsert(jsonList)
          .select();

      return List.from(data).map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to bulk update products: $e');
    }
  }

  // ========================================
  // UTILITY METHODS
  // ========================================

  Future<bool> productExists(int id) async {
    try {
      await _supabaseService.client
          .from('products')
          .select('id')
          .eq('id', id)
          .single();

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<int> getProductsCount() async {
    try {
      final response = await _supabaseService.client
          .from('products')
          .select()
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      throw Exception('Failed to get products count: $e');
    }
  }

  Future<List<Product>> getProductsPaginated({
    required int page,
    required int limit,
  }) async {
    try {
      final from = (page - 1) * limit;
      final to = from + limit - 1;

      final data = await _supabaseService.client
          .from('products')
          .select()
          .order('created_at', ascending: false)
          .range(from, to);

      return List.from(data).map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch paginated products: $e');
    }
  }
}
