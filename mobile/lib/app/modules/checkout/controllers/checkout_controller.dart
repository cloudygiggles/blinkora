import 'package:get/get.dart';
import '../../../data/providers/order_provider.dart';
import '../../../data/providers/address_provider.dart';
import '../../../data/models/address_model.dart';
import '../../../routes/app_pages.dart';

class CheckoutController extends GetxController {
  final OrderProvider orderProvider = Get.find<OrderProvider>();
  final AddressProvider addressProvider = Get.find<AddressProvider>();

  var isLoading = false.obs;

  // =========================
  // GETTERS
  // =========================
  List<Address> get addresses => addressProvider.addresses;
  Rxn<Address> get selectedAddress => addressProvider.address;

  double get totalPrice => orderProvider.totalPriceDouble;

  // =========================
  // LOAD ADDRESSES
  // =========================
  Future<void> loadAddresses() async {
    await addressProvider.getAllAddresses();
  }

  // =========================
  // SELECT ADDRESS
  // =========================
  void selectAddress(Address address) {
    addressProvider.selectAddress(address);
  }

  // =========================
  // ADD / UPDATE ADDRESS
  // =========================
  Future<void> addOrUpdateAddress(Address address) async {
    await addressProvider.addOrUpdateAddress(address);
  }

  // =========================
  // DELETE ADDRESS
  // =========================
  Future<void> deleteAddress(Address address) async {
    await addressProvider.deleteAddress(address);
  }

  // =========================
  // PLACE ORDER
  // =========================
  Future<void> placeOrder() async {
    if (selectedAddress.value == null) {
      Get.snackbar('Error', 'Silakan pilih alamat pengiriman terlebih dahulu');
      print('❌ Checkout gagal: alamat belum dipilih');
      return;
    }

    print(
      '🛒 Memulai checkout dengan total: ${orderProvider.totalPriceDouble}',
    );
    print('📦 Jumlah item di cart: ${orderProvider.cartItemsList.length}');
    print('🏠 Alamat dipilih: ${selectedAddress.value?.address ?? "null"}');

    isLoading.value = true;
    final success = await orderProvider.checkout();
    isLoading.value = false;

    if (success) {
      // Pastikan cart benar-benar kosong
      orderProvider.clearCart();
      print('✅ Checkout berhasil, cart sudah dikosongkan');

      Get.snackbar('Sukses', 'Pesanan berhasil dibuat');
      Get.toNamed(Routes.HOME); // kembali ke halaman sebelumnya
    } else {
      print('❌ Checkout gagal: ${orderProvider.errorMessage.value}');
      Get.snackbar('Error', orderProvider.errorMessage.value);
    }
  }
}
