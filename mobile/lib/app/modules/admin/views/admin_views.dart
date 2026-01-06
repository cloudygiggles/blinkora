import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_controller.dart';
import '../../../data/models/product_model.dart';
import '../../../data/providers/auth_provider.dart';
import '../../auth/views/login_view.dart';

class AdminProductView extends GetView<AdminProductController> {
  const AdminProductView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Admin Panel',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: isDarkMode ? Colors.pink[700] : Colors.pink[100],
          elevation: 0,
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                controller.fetchProducts();
                controller.fetchOrders(); // Refresh kedua data sekaligus
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: () => _showLogoutDialog(),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.pink,
            labelColor: Colors.pink,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(icon: Icon(Icons.inventory_2), text: 'Produk'),
              Tab(icon: Icon(Icons.shopping_cart), text: 'Pesanan'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildProductTab(context), 
            _buildOrdersTab()
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openProductForm(context, isEditing: false),
          backgroundColor: Colors.pink,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Produk Baru', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  // =========================================================
  // TAB 1: PRODUK
  // =========================================================
  Widget _buildProductTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          Expanded(child: _buildProductList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.pink.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Obx(() => Text(
            'Total Inventory: ${controller.products.length}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          )),
          const Icon(Icons.assessment_outlined, color: Colors.pink),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.products.isEmpty) {
        return _buildEmptyState('Belum ada produk', Icons.inventory_2);
      }
      return ListView.separated(
        itemCount: controller.products.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildProductItem(controller.products[index]),
      );
    });
  }

  Widget _buildProductItem(Product product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            color: _parseColor(product.color).withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.image_outlined, color: _parseColor(product.color)),
        ),
        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Rp ${product.price}', style: const TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _actionButton(Icons.edit, Colors.blue, () {
              controller.editProduct(product);
              _openProductForm(Get.context!, isEditing: true);
            }),
            const SizedBox(width: 8),
            _actionButton(Icons.delete, Colors.red, () => controller.deleteProduct(product.id, product.name)),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // TAB 2: KELOLA PESANAN
  // =========================================================
  Widget _buildOrdersTab() {
    return Obx(() {
      if (controller.isOrderLoading.value) {
        return const Center(child: CircularProgressIndicator(color: Colors.pink));
      }
      if (controller.orders.isEmpty) {
        return _buildEmptyState('Belum ada pesanan masuk', Icons.shopping_cart_outlined);
      }
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.orders.length,
        itemBuilder: (context, index) => _buildOrderCard(controller.orders[index]),
      );
    });
  }

  Widget _buildOrderCard(dynamic order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(order.status).withOpacity(0.1),
          child: Icon(Icons.receipt_long, color: _getStatusColor(order.status)),
        ),
        title: Text('Pesanan #${order.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Total: Rp ${order.totalPrice}'),
        trailing: _statusChip(order.status),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                _infoRow('User ID', order.userId),
                _infoRow('Alamat ID', order.addressId.toString()),
                _infoRow('Status Saat Ini', order.status.toUpperCase()),
                const SizedBox(height: 16),
                const Text('Ubah Status:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _statusButton(order.id, 'pending', Colors.orange),
                    _statusButton(order.id, 'shipping', Colors.blue),
                    _statusButton(order.id, 'completed', Colors.green),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // =========================================================
  // HELPER WIDGETS
  // =========================================================
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _statusButton(int id, String status, Color color) {
    return ElevatedButton(
      onPressed: () => controller.updateStatus(id, status),
      style: ElevatedButton.styleFrom(
        backgroundColor: color, foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(status.toUpperCase(), style: const TextStyle(fontSize: 10)),
    );
  }

  Widget _statusChip(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'shipping': return Colors.blue;
      case 'completed': return Colors.green;
      default: return Colors.grey;
    }
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  // Form input produk sama seperti sebelumnya (Sheet modal)
  void _openProductForm(BuildContext context, {required bool isEditing}) {
    if (!isEditing) {
      controller.selectedProduct.value = null;
      controller.nameController.clear();
      controller.categoryController.clear();
      controller.priceController.clear();
      controller.colorController.clear();
      controller.descriptionController.clear();
      controller.imagePathController.clear();
    }
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSheetHeader(isEditing),
                const SizedBox(height: 20),
                _buildFormFields(),
                const SizedBox(height: 24),
                _buildSheetButtons(isEditing),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        _customTextField(controller.nameController, 'Nama Produk', Icons.shopping_bag),
        _customTextField(controller.categoryController, 'Kategori', Icons.category),
        _customTextField(controller.priceController, 'Harga', Icons.payments, isNumber: true),
        _customTextField(controller.colorController, 'Warna (Hex)', Icons.palette, hint: '#FF6B8B'),
        _customTextField(controller.descriptionController, 'Deskripsi', Icons.description, maxLines: 3),
        _customTextField(controller.imagePathController, 'Path Gambar', Icons.image, hint: 'assets/images/item.jpg'),
      ],
    );
  }

  Widget _customTextField(TextEditingController ctrl, String label, IconData icon, {bool isNumber = false, int maxLines = 1, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl, keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label, hintText: hint,
          prefixIcon: Icon(icon, color: Colors.pink, size: 20),
          filled: true, fillColor: Colors.grey.withOpacity(0.05),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildSheetButtons(bool isEditing) {
    return Obx(() {
      final loading = controller.isLoading.value;
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: loading ? null : () => isEditing ? controller.updateProduct(controller.selectedProduct.value!) : controller.createProduct(),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, padding: const EdgeInsets.symmetric(vertical: 16)),
          child: loading ? const CircularProgressIndicator(color: Colors.white) : Text(isEditing ? 'Simpan Perubahan' : 'Tambah Produk', style: const TextStyle(color: Colors.white)),
        ),
      );
    });
  }

  Widget _buildSheetHeader(bool isEditing) => Text(isEditing ? 'Edit Data Produk' : 'Tambah Produk Baru', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold));

  void _showLogoutDialog() {
    Get.defaultDialog(
      title: "Logout", middleText: "Keluar dari mode Admin?",
      textConfirm: "Keluar", textCancel: "Batal", confirmTextColor: Colors.white, buttonColor: Colors.pink,
      onConfirm: () async {
        await Get.find<AuthProvider>().logout();
        Get.offAll(() => const LoginView());
      },
    );
  }

  Color _parseColor(String hexColor) {
    try {
      var hex = hexColor.trim().replaceFirst('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse('0x$hex'));
    } catch (e) { return Colors.grey; }
  }
}