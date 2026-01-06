import 'package:blinkora/app/data/services/supabase_service.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../../data/providers/auth_provider.dart';
import '../../../core/app_strings.dart';
import '../../../routes/app_pages.dart';

class AuthController extends GetxController {
  final AuthProvider _authProvider = Get.find();
  final SupabaseService _supabase = Get.find();
  

  final isLoading = false.obs;

  /// role nullable karena:
  /// - profile dibuat via trigger
  /// - bisa delay beberapa ms
  final userRole = Rx<String?>(null);
  final isRoleLoaded = false.obs;

  @override
  void onInit() {
    super.onInit();
    _restoreAuthSession();
  }

  // =========================
  // RESTORE SESSION
  // =========================
  Future<void> _restoreAuthSession() async {
    isRoleLoaded.value = false;
    userRole.value = null;

    final user = _authProvider.currentUser;
    if (user == null) {
      isRoleLoaded.value = true;
      return;
    }

    await _ensureProfileLoaded(user.id);
    isRoleLoaded.value = true;
  }

  /// Tunggu sampai profile benar-benar ada (hasil trigger)
  Future<void> _ensureProfileLoaded(String userId) async {
    try {
      // Retry max 3x
      for (int i = 0; i < 3; i++) {
        final role = await _authProvider.getUserRole(userId);
        if (role != null) {
          userRole.value = role;
          return;
        }
        await Future.delayed(const Duration(milliseconds: 300));
      }
    } catch (_) {
      userRole.value = null;
    }
  }

  // =========================
  // LOGIN
  // =========================
  Future<void> login(String email, String password) async {
    isLoading.value = true;
    try {
      final response = await _authProvider.login(email.trim(), password);

      final userId = response.user?.id;
      if (userId == null) {
        throw Exception('Login failed');
      }

      await _ensureProfileLoaded(userId);

      Get.snackbar(
        'Success',
        AppStrings.loginSuccess,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      Get.offAllNamed(Routes.HOME);
    } catch (e) {
      userRole.value = null;
      Get.snackbar(
        'Error',
        '${AppStrings.loginFailed}: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // =========================
  // REGISTER
  // =========================
  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    isLoading.value = true;
    try {
      // Kita kirim name dan phone ke dalam user_metadata
      // Trigger di Supabase akan mengambil data ini lewat: new.raw_user_meta_data->>'name'
      await _supabase.client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'name': name, 'phone': phone},
      );

      Get.snackbar(
        'Success',
        'Akun berhasil dibuat! Silakan cek email untuk verifikasi (jika aktif).',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      Get.offAllNamed(Routes.LOGIN);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Registrasi Gagal: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // =========================
  // LOGOUT
  // =========================
  Future<void> logout() async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text(AppStrings.logout),
        content: const Text(AppStrings.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text(AppStrings.logout),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    isLoading.value = true;
    try {
      await _authProvider.logout();

      userRole.value = null;
      isRoleLoaded.value = true;

      Get.offAllNamed(Routes.LOGIN);

      Get.snackbar(
        'Success',
        'Logged out successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Logout failed: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // =========================
  // HELPERS
  // =========================
  bool get isAuthenticated => _authProvider.currentUser != null;

  bool get isAdmin => userRole.value == 'admin';
  bool get isUser => userRole.value == 'user';

  Future<void> refreshAuthState() async {
    await _restoreAuthSession();
  }

  // =========================
  // VALIDATORS
  // =========================
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.pleaseEnterEmail;
    }
    if (!value.contains('@')) {
      return AppStrings.pleaseEnterValidEmail;
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.pleaseEnterPassword;
    }
    if (value.length < 6) {
      return AppStrings.passwordMinLength;
    }
    return null;
  }

  String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return AppStrings.pleaseConfirmPassword;
    }
    if (value != password) {
      return AppStrings.passwordsDoNotMatch;
    }
    return null;
  }
}
