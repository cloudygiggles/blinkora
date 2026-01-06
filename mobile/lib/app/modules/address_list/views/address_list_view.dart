import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/address_list_controller.dart';
import '../../../routes/app_pages.dart';

class AddressListView extends GetView<AddressListController> {
  const AddressListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Alamat Saya',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.addresses.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.addresses.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.addresses.length,
          itemBuilder: (context, index) {
            final addr = controller.addresses[index];
            return _buildAddressCard(addr);
          },
        );
      }),
      bottomNavigationBar: _buildAddButton(),
    );
  }

  Widget _buildAddressCard(addr) {
    return Card(
      margin: const EdgeInsets.all(
        8,
      ), // Mengurangi margin sedikit agar lebih rapat
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    addr.receiverName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: Colors.blue,
                        size: 20,
                      ),
                      onPressed: () => controller.editAddress(addr),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: () => controller.deleteAddress(addr),
                    ),
                  ],
                ),
              ],
            ),
            Text(addr.phoneNumber, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(addr.address),
            if (addr.city != null)
              Text("${addr.city}, ${addr.postalCode ?? ''}"),

            // --- BAGIAN TAMBAHAN KOORDINAT ---
            const Divider(height: 20),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  "Lat: ${addr.latitude?.toStringAsFixed(6) ?? '-'}, Lon: ${addr.longitude?.toStringAsFixed(6) ?? '-'}",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontFamily:
                        'monospace', // Menggunakan monospace agar angka sejajar
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            "Belum ada alamat tersimpan",
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pink,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () => Get.toNamed(
          Routes.LOCATION,
        )?.then((_) => controller.fetchAddresses()),
        icon: const Icon(Icons.add),
        label: const Text(
          "Tambah Alamat Baru",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
