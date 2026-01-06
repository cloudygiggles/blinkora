import 'package:get/get.dart';
import '../services/supabase_service.dart';
import '../../data/models/address_model.dart';

class AddressProvider extends GetxController {
  final SupabaseService _supabase = Get.find<SupabaseService>();

  // ================= STATE =================
  var address = Rxn<Address>(); // Alamat yang sedang dipilih/aktif digunakan
  var addresses = <Address>[].obs; // Daftar semua alamat aktif milik user
  var isLoading = false.obs;

  // ================= FETCH ALL ADDRESSES =================

  Future<void> getAllAddresses() async {
    final user = _supabase.currentUser;
    if (user == null) return;

    try {
      isLoading.value = true;
      final data = await _supabase
          .from('addresses')
          .select()
          .eq('user_id', user.id)
          .eq('is_active', true) 
          .order('id', ascending: false); 

      addresses.assignAll(
        data.map<Address>((json) => Address.fromJson(json)).toList(),
      );
    } catch (e) {
      print('Failed to fetch addresses: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ================= ADD / UPDATE ADDRESS =================
  /// Menggunakan logika terpisah untuk Insert dan Update guna menghindari
  /// error Identity Column di Supabase.
  Future<void> addOrUpdateAddress(Address newAddress) async {
    final user = _supabase.currentUser;
    if (user == null) return;

    try {
      isLoading.value = true;

      // Buat payload tanpa field ID
      final payload = {
        'user_id': user.id,
        ...newAddress.toJsonForUpsert(),
        'is_active': true, // Pastikan saat simpan/update statusnya aktif
      };

      if (newAddress.id != 0) {
        // MODE UPDATE: Filter berdasarkan ID, payload tidak boleh berisi ID
        await _supabase
            .from('addresses')
            .update(payload)
            .eq('id', newAddress.id);
      } else {
        // MODE INSERT: Biarkan database generate ID secara otomatis
        await _supabase.from('addresses').insert(payload);
      }

      await getAllAddresses(); // Refresh list setelah operasi
    } catch (e) {
      print('Error saving/updating address: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  // ================= SOFT DELETE ADDRESS =================
  /// Alamat tidak benar-benar dihapus dari baris tabel untuk menjaga
  /// integritas data di tabel 'orders'.
  Future<void> deleteAddress(Address delAddress) async {
    final user = _supabase.currentUser;
    if (user == null) return;

    try {
      isLoading.value = true;

      // Soft Delete: Ubah is_active menjadi false
      await _supabase
          .from('addresses')
          .update({'is_active': false})
          .eq('id', delAddress.id)
          .eq('user_id', user.id);

      await getAllAddresses();

      // Sinkronisasi alamat terpilih (jika yang dihapus sedang terpilih)
      if (address.value?.id == delAddress.id) {
        address.value = addresses.isNotEmpty ? addresses.first : null;
      }
    } catch (e) {
      print('Failed to soft delete address: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  // ================= GET SINGLE ADDRESS =================
  Future<Address?> getAddressById(int addressId) async {
    try {
      final data = await _supabase
          .from('addresses')
          .select()
          .eq('id', addressId)
          .eq('is_active', true)
          .maybeSingle();

      return data != null ? Address.fromJson(data) : null;
    } catch (e) {
      print('Failed to fetch address by ID: $e');
      return null;
    }
  }

  // ================= SELECT ADDRESS =================
  void selectAddress(Address selected) {
    address.value = selected;
  }
}