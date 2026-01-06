import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../../../data/models/address_model.dart';
import '../../../data/services/location_service.dart';
import '../../../data/providers/address_provider.dart';
import '../../../data/providers/auth_provider.dart';

class AddressLocationController extends GetxController {
  final LocationService _locationService = Get.find();
  final AddressProvider _addressProvider = Get.find();
  final AuthProvider _authProvider = Get.find();

  final MapController mapController = MapController();

  final isLoading = false.obs;
  final isSaving = false.obs;
  final Rx<LatLng?> selectedLatLng = Rx<LatLng?>(null);

  // --- EDIT MODE STATE ---
  final isEditMode = false.obs;
  int? editAddressId;

  // TextEditingControllers
  final receiverNameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final postalCodeController = TextEditingController();

  final zoom = 16.0.obs;

  // Fungsi Zoom In
  void zoomIn() {
    if (zoom.value < 18.0) { // Batas maksimal zoom
      zoom.value++;
      _moveMap();
    }
  }

  // Fungsi Zoom Out
  void zoomOut() {
    if (zoom.value > 1.0) { // Batas minimal zoom
      zoom.value--;
      _moveMap();
    }
  }

  void _moveMap() {
    final target = selectedLatLng.value ?? const LatLng(-6.2000, 106.8166);
    mapController.move(target, zoom.value);
  }

  
  Future<void> moveToCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentPosition(useGps: false);
      if (position != null) {
        final newLatLng = LatLng(position.latitude, position.longitude);
        selectedLatLng.value = newLatLng;
        
        mapController.move(newLatLng, zoom.value); 
      }
    } catch (e) {
      Get.snackbar('Info', 'Pastikan GPS Anda aktif');
    }
  }

  @override
  void onInit() {
    super.onInit();
    // Cek arguments untuk mode edit
    if (Get.arguments != null && Get.arguments is Address) {
      _setupEditMode(Get.arguments as Address);
    } else {
      _initLocation();
    }
  }

  void _setupEditMode(Address data) {
    isEditMode.value = true;
    editAddressId = data.id;

    receiverNameController.text = data.receiverName;
    phoneController.text = data.phoneNumber;
    addressController.text = data.address;
    cityController.text = data.city ?? '';
    postalCodeController.text = data.postalCode ?? '';

    if (data.latitude != null && data.longitude != null) {
      selectedLatLng.value = LatLng(data.latitude!, data.longitude!);
      
      // Delay agar MapController siap sebelum dipindahkan
      Future.delayed(const Duration(milliseconds: 500), () {
        if (selectedLatLng.value != null) {
          mapController.move(selectedLatLng.value!, 16);
        }
      });
    }
  }

  Future<void> _initLocation() async {
    try {
      isLoading.value = true;
      final position = await _locationService.getCurrentPosition(useGps: true);
      if (position != null) {
        selectedLatLng.value = LatLng(position.latitude, position.longitude);
      }
    } catch (e) {
      debugPrint('Gagal mendapatkan lokasi awal: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void updateMarkerPosition(LatLng latLng) {
    selectedLatLng.value = latLng;
  }

  Future<void> saveAddress() async {
    // Validasi input wajib
    if (receiverNameController.text.isEmpty ||
        addressController.text.isEmpty ||
        selectedLatLng.value == null) {
      Get.snackbar(
        'Peringatan',
        'Lengkapi Nama, Alamat, dan Lokasi Peta',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isSaving.value = true;

      final addressData = Address(
        // Jika edit gunakan id lama, jika baru gunakan 0 (supaya Supabase generate ID baru)
        id: isEditMode.value ? editAddressId! : 0,
        receiverName: receiverNameController.text.trim(),
        phoneNumber: phoneController.text.trim(),
        address: addressController.text.trim(),
        city: cityController.text.trim(),
        postalCode: postalCodeController.text.trim(),
        latitude: selectedLatLng.value?.latitude,
        longitude: selectedLatLng.value?.longitude,
      );

      // Menggunakan fungsi upsert di Provider
      await _addressProvider.addOrUpdateAddress(addressData);

      Get.back(result: true); // Kirim 'true' agar List View tahu data berubah
      Get.snackbar('Berhasil', isEditMode.value ? 'Alamat diperbarui' : 'Alamat disimpan');
    } catch (e) {
      Get.snackbar('Gagal', 'Gagal menyimpan: $e');
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    receiverNameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    cityController.dispose();
    postalCodeController.dispose();
    super.onClose();
  }
}