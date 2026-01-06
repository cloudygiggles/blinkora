import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../controllers/home_controller.dart';
import '../../../data/models/product_model.dart';
import '../../../data/services/theme_service.dart';
import '../../../data/providers/auth_provider.dart';
import '../../auth/views/login_view.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width >= 600;

    return Scaffold(
      drawer: _buildDrawer(context),
      body: Obx(() {
        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(context, isTablet),
            if (controller.isOfflineMode.value)
              SliverToBoxAdapter(child: _buildOfflineBanner()),
            SliverToBoxAdapter(child: _buildSearchBar(context, isTablet)),
            SliverToBoxAdapter(child: _buildCategoryFilter(context, isTablet)),
            SliverToBoxAdapter(child: _buildLocationBanner(context, isTablet)),
            if (controller.isLoading.value)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (controller.errorMessage.isNotEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildErrorState(context, isTablet),
              )
            else if (controller.filteredProducts.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(context, isTablet),
              )
            else
              _buildProductGrid(context, isTablet),
          ],
        );
      }),
      floatingActionButton: Obx(
        () => controller.cartItemCount > 0
            ? _buildCartFloatingButton(context, isTablet)
            : const SizedBox(),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.pink[700]
                  : Colors.pink[100],
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Colors.pink),
            ),
            accountName: Obx(
              () => Text(
                controller.userName.value,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            accountEmail: Obx(
              () => Text(
                controller.userEmail.value,
                style: const TextStyle(color: Colors.black54),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Beranda'),
            onTap: () => Get.back(),
          ),
           ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('Alamat Pengiriman'),
            onTap: () {
              Get.back();
              controller.goToAddressList();
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Riwayat Pemesanan'),
            onTap: () {
              Get.back();
              controller.goToHistory();
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Keluar', style: TextStyle(color: Colors.red)),
            onTap: () {
              Get.back();
              _showLogoutDialog(context, false);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isTablet) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      elevation: 0,
      title: const Text(
        'Produk Anak',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.pink[700]
          : Colors.pink[100],
      actions: [
        _buildThemeToggle(isTablet),
        IconButton(
          icon: const Icon(Icons.history),
          tooltip: 'Riwayat Pemesanan',
          onPressed: () => Get.toNamed('/order-history'),
        ),
      ],
    );
  }

  Widget _buildProductGrid(BuildContext context, bool isTablet) {
    final screenSize = MediaQuery.of(context).size;
    int crossAxisCount = screenSize.width >= 900 ? 4 : (isTablet ? 3 : 2);
    if (screenSize.width < 360) crossAxisCount = 1;

    return SliverPadding(
      padding: EdgeInsets.all(isTablet ? 20 : 12),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: isTablet ? 0.75 : 0.65,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          return _buildProductCard(
            context,
            controller.filteredProducts[index],
            isTablet,
          );
        }, childCount: controller.filteredProducts.length),
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    Product product,
    bool isTablet,
  ) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: _buildProductImage(product)),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.category,
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  Text(
                    'Rp ${product.price}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildCartActions(product, isTablet),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(Product product) {
    final String path = product.imagePath;
    if (path.startsWith('assets/')) {
      return Image.asset(path, fit: BoxFit.cover, width: double.infinity);
    } else if (File(path).existsSync()) {
      return Image.file(File(path), fit: BoxFit.cover, width: double.infinity);
    }
    return Container(
      color: Colors.grey[200],
      width: double.infinity,
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }

  Widget _buildCartActions(Product product, bool isTablet) {
    return Obx(() {
      final qty = controller.cartItems[product.id] ?? 0;
      if (qty == 0) {
        return SizedBox(
          width: double.infinity,
          height: 32,
          child: ElevatedButton(
            onPressed: () => controller.addToCart(product),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Tambah", style: TextStyle(fontSize: 11)),
          ),
        );
      }
      return Container(
        height: 32,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => controller.removeFromCart(product.id),
              icon: const Icon(Icons.remove, size: 14),
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            Text(
              '$qty',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            IconButton(
              onPressed: () => controller.addToCart(product),
              icon: const Icon(Icons.add, size: 14),
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.orange[100],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 16, color: Colors.orange[800]),
          const SizedBox(width: 8),
          Text(
            'Mode Offline Aktif',
            style: TextStyle(fontSize: 12, color: Colors.orange[800]),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isTablet) {
    return Padding(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      child: TextField(
        onChanged: controller.setSearchQuery,
        decoration: InputDecoration(
          hintText: 'Cari produk...',
          prefixIcon: const Icon(Icons.search),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(BuildContext context, bool isTablet) {
    return SizedBox(
      height: 40,
      child: Obx(
        () => ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: controller.categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final cat = controller.categories[index];
            final isSelected = controller.selectedCategory.value == cat;
            return ChoiceChip(
              label: Text(cat, style: const TextStyle(fontSize: 12)),
              selected: isSelected,
              onSelected: (_) => controller.setCategory(cat),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLocationBanner(BuildContext context, bool isTablet) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: InkWell(
        onTap: () => controller.goToLocation(),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[100]!),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: Colors.blue),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Tambahkan Alamat Pengiriman!',
                  style: TextStyle(fontSize: 13, color: Colors.blue),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.blue[300]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, bool isTablet) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(controller.errorMessage.value),
          TextButton(
            onPressed: () => controller.fetchProducts(),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isTablet) {
    return const Center(child: Text('Produk tidak ditemukan'));
  }

  Widget _buildThemeToggle(bool isTablet) {
    return Consumer<ThemeService>(
      builder: (_, theme, __) {
        return IconButton(
          icon: Icon(theme.isDarkMode ? Icons.light_mode : Icons.dark_mode),
          onPressed: theme.toggleTheme,
        );
      },
    );
  }

  Widget _buildCartFloatingButton(BuildContext context, bool isTablet) {
    return FloatingActionButton.extended(
      onPressed: () => controller.goToCheckout(),
      backgroundColor: Colors.pink,
      label: Text(
        '${controller.cartItemCount} Item | Rp ${controller.cartTotalPrice}',
        style: const TextStyle(color: Colors.white),
      ),
      icon: const Icon(Icons.shopping_cart, color: Colors.white),
    );
  }

  void _showLogoutDialog(BuildContext context, bool isTablet) {
    Get.defaultDialog(
      title: "Logout",
      middleText: "Yakin ingin keluar?",
      textConfirm: "Ya",
      textCancel: "Tidak",
      onConfirm: () async {
        final auth = Get.find<AuthProvider>();
        await auth.logout();
        Get.offAll(() => const LoginView());
      },
    );
  }
}
