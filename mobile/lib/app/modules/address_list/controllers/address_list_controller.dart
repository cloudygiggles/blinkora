import 'package:get/get.dart';
import '../../../data/models/address_model.dart';
import '../../../data/providers/address_provider.dart';
import 'package:flutter/material.dart';
import '../../../routes/app_pages.dart';

class AddressListController extends GetxController {
  final AddressProvider _addressProvider = Get.find<AddressProvider>();

  // Memudahkan akses list alamat dari provider
  RxList<Address> get addresses => _addressProvider.addresses;
  RxBool get isLoading => _addressProvider.isLoading;

  @override
  void onInit() {
    super.onInit();
    fetchAddresses();
  }

  Future<void> fetchAddresses() async {
    await _addressProvider.getAllAddresses();
  }

  void editAddress(Address address) {
    // Arahkan ke View lokasi dengan mengirim argumen data alamat
    Get.toNamed(Routes.LOCATION, arguments: address)?.then((value) {
      if (value == true) fetchAddresses(); // Refresh jika ada perubahan
    });
  }

  Future<void> deleteAddress(Address address) async {
    Get.defaultDialog(
      title: "Hapus Alamat",
      middleText: "Apakah Anda yakin ingin menghapus alamat ini?",
      textConfirm: "Hapus",
      textCancel: "Batal",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        Get.back(); // tutup dialog
        await _addressProvider.deleteAddress(address);
        Get.snackbar("Sukses", "Alamat berhasil dihapus");
      },
      onCancel: () {
        Get.back(); // tutup dialog
      },
    );
  }
}