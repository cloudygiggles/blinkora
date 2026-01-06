import 'package:blinkora/app/data/providers/order_provider.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../data/providers/product_provider.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/order_model.dart';

class AdminProductController extends GetxController {
  final ProductProvider _productProvider = Get.find();
  final OrderProvider _orderProvider = Get.find<OrderProvider>();

  final products = <Product>[].obs;
  final isLoading = false.obs;

  // Product being edited
  final selectedProduct = Rxn<Product>();

  // Form Controllers
  final nameController = TextEditingController();
  final categoryController = TextEditingController();
  final priceController = TextEditingController();
  final colorController = TextEditingController();
  final descriptionController = TextEditingController();
  final imagePathController = TextEditingController();

  RxList<Order> get orders => _orderProvider.allOrders;
  RxBool get isOrderLoading => _orderProvider.isLoading;

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
    fetchOrders();
  }

  @override
  void onClose() {
    nameController.dispose();
    categoryController.dispose();
    priceController.dispose();
    colorController.dispose();
    descriptionController.dispose();
    imagePathController.dispose();
    super.onClose();
  }

  void fetchOrders() {
    _orderProvider.fetchAllOrders();
  }

  void updateStatus(int orderId, String status) async {
    bool success = await _orderProvider.updateOrderStatus(orderId, status);
    if (success) {
      Get.snackbar("Berhasil", "Pesanan #$orderId sekarang $status",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // Fetch products
  Future<void> fetchProducts() async {
    try {
      isLoading.value = true;
      final result = await _productProvider.getProducts();
      products.value = result;
    } catch (e) {
      Get.snackbar(
        "Error!",
        "Failed to fetch products: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Create new product
  Future<void> createProduct() async {
    if (!_validateForm()) return;

    try {
      isLoading.value = true;

      final newProduct = Product.create(
        name: nameController.text.trim(),
        category: categoryController.text.trim(),
        price: int.parse(priceController.text.trim()),
        color: colorController.text.trim(),
        description: descriptionController.text.trim(),
        imagePath: imagePathController.text.trim(),
      );

      await _productProvider.createProduct(newProduct);

      Get.back();
      _clearForm();
      fetchProducts();

      Get.snackbar(
        'Success',
        'Product created successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create product: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Update product
  Future<void> updateProduct(Product product) async {
    if (!_validateForm()) return;

    try {
      isLoading.value = true;

      final updatedProduct = product.copyWith(
        name: nameController.text.trim(),
        category: categoryController.text.trim(),
        price: int.parse(priceController.text.trim()),
        color: colorController.text.trim(),
        description: descriptionController.text.trim(),
        imagePath: imagePathController.text.trim(),
        updatedAt: DateTime.now(),
      );

      await _productProvider.updateProduct(updatedProduct);

      Get.back();
      _clearForm();
      selectedProduct.value = null; // reset

      fetchProducts();

      Get.snackbar(
        'Success',
        'Product updated successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update product: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Delete product
  Future<void> deleteProduct(int id, String name) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        isLoading.value = true;

        await _productProvider.deleteProduct(id);
        fetchProducts();

        Get.snackbar(
          'Success',
          'Product deleted successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to delete product: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } finally {
        isLoading.value = false;
      }
    }
  }

  // Prepare form to edit
  void editProduct(Product product) {
    selectedProduct.value = product;

    nameController.text = product.name;
    categoryController.text = product.category;
    priceController.text = product.price.toString();
    colorController.text = product.color;
    descriptionController.text = product.description;
    imagePathController.text = product.imagePath;
  }

  // Validation
  bool _validateForm() {
    if (nameController.text.trim().isEmpty) {
      _showValidation("Product name is required");
      return false;
    }

    if (categoryController.text.trim().isEmpty) {
      _showValidation("Category is required");
      return false;
    }

    if (priceController.text.trim().isEmpty ||
        int.tryParse(priceController.text.trim()) == null) {
      _showValidation("Valid price is required");
      return false;
    }

    if (colorController.text.trim().isEmpty) {
      _showValidation("Color is required");
      return false;
    }

    return true;
  }

  void _showValidation(String message) {
    Get.snackbar(
      'Validation Error',
      message,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
  }

  // Clear form
  void _clearForm() {
    nameController.clear();
    categoryController.clear();
    priceController.clear();
    colorController.clear();
    descriptionController.clear();
    imagePathController.clear();
  }
}
