import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import '../controllers/address_location_controller.dart';
import 'package:latlong2/latlong.dart';

class AddressLocationView extends GetView<AddressLocationController> {
  const AddressLocationView({super.key});

  @override
  Widget build(BuildContext context) {
    // Inisialisasi controller jika belum di-bind di route
    // final controller = Get.put(AddAddressController());

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Text(
            controller.isEditMode.value ? 'Edit Alamat' : 'Tambah Alamat',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: isDarkMode ? Colors.pink[700] : Colors.pink[100],
        elevation: 0,
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- SECTION MAP ---
              Stack(
                children: [
                  Container(
                    height: 320,
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: FlutterMap(
                        mapController: controller.mapController,
                        options: MapOptions(
                          initialCenter:
                              controller.selectedLatLng.value ??
                              const LatLng(-6.2000, 106.8166),
                          initialZoom: 16,
                          onTap: (_, point) =>
                              controller.updateMarkerPosition(point),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                            subdomains: const ['a', 'b', 'c'],
                          ),
                          Obx(() {
                            final loc = controller.selectedLatLng.value;
                            if (loc == null) return const SizedBox();
                            return MarkerLayer(
                              markers: [
                                Marker(
                                  point: loc,
                                  width: 50,
                                  height: 50,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                    size: 50,
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  ),

                  Positioned(
                    right: 28,
                    top: 28,
                    child: Column(
                      children: [
                        _mapActionButton(
                          icon: Icons.add,
                          onPressed: () => controller.zoomIn(),
                        ),
                        const SizedBox(height: 8),
                        _mapActionButton(
                          icon: Icons.remove,
                          onPressed: () => controller.zoomOut(),
                        ),
                      ],
                    ),
                  ),
                  // Tombol Floating Lokasi Sekarang
                  Positioned(
                    right: 28,
                    bottom: 28,
                    child: FloatingActionButton.small(
                      heroTag: 'btn_gps',
                      backgroundColor: Colors.white,
                      onPressed: () => controller.moveToCurrentLocation(),
                      child: const Icon(Icons.my_location, color: Colors.pink),
                    ),
                  ),
                ],
              ),

              // --- SECTION FORM ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detail Pengiriman',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _field(
                      controller.receiverNameController,
                      'Nama Penerima',
                      Icons.person_outline,
                    ),
                    _field(
                      controller.phoneController,
                      'No HP',
                      Icons.phone_android_outlined,
                      type: TextInputType.phone,
                    ),
                    _field(
                      controller.addressController,
                      'Alamat Lengkap',
                      Icons.map_outlined,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            controller.cityController,
                            'Kota',
                            Icons.location_city_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _field(
                            controller.postalCodeController,
                            'Kode Pos',
                            Icons.mark_as_unread_outlined,
                            type: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- TOMBOL SIMPAN ---
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: Obx(
                        () => ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          onPressed: controller.isSaving.value
                              ? null
                              : () => controller.saveAddress(),
                          child: controller.isSaving.value
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  controller.isEditMode.value
                                      ? 'Perbarui Alamat'
                                      : 'Simpan Alamat',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: c,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          filled: true,
          fillColor: Colors.grey.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.pink),
          ),
        ),
      ),
    );
  }

  Widget _mapActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.pink),
        onPressed: onPressed,
        constraints:
            const BoxConstraints(), // Menghilangkan padding default icon button
      ),
    );
  }
}
