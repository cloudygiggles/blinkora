import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../app/modules/auth/controllers/auth_controller.dart';
import '../../app/routes/app_pages.dart';

class AdminMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    final authController = Get.find<AuthController>();

    debugPrint('🛡️ AdminMiddleware checking route: $route');
    debugPrint('🛡️ Role loaded: ${authController.isRoleLoaded.value}');
    debugPrint('🛡️ User role: ${authController.userRole.value}');
    debugPrint('🛡️ Is admin: ${authController.isAdmin}');

    // 1. Jika role belum di-load, biarkan lewat dulu (akan di-handle di controller)
    if (!authController.isRoleLoaded.value) {
      debugPrint('🛡️ Role not loaded yet, allowing temporary access');
      return null;
    }

    // 2. Jika sudah loaded dan bukan admin, redirect ke home
    if (!authController.isAdmin) {
      debugPrint('🛡️ Access denied - User is not admin');
      
      // Tampilkan snackbar hanya jika bukan dari redirect otomatis
      if (Get.currentRoute != Routes.HOME) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.snackbar(
            'Access Denied',
            'Admin privileges required',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
        });
      }
      
      return const RouteSettings(name: Routes.HOME);
    }

    debugPrint('🛡️ Admin access granted');
    return null;
  }
}