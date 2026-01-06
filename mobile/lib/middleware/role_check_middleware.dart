import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../app/modules/auth/controllers/auth_controller.dart';
import '../../app/data/providers/auth_provider.dart';
import '../../app/routes/app_pages.dart';

class RoleCheckMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    final authProvider = Get.find<AuthProvider>();
    final authController = Get.find<AuthController>();

    if (!authProvider.isAuthenticated) {
      return null; // AuthMiddleware handle
    }

    if (!authController.isRoleLoaded.value) {
      return null; // wait role
    }

    final role = authController.userRole.value;

    // ADMIN RULE
    if (role == 'admin') {
      // Admin dilarang ke HOME, redirect ke ADMIN DASHBOARD
      if (route == Routes.HOME) {
        return const RouteSettings(name: Routes.ADMIN_DASHBOARD);
      }
      return null;
    }

    // USER RULE
    if (role == 'user') {
      // User dilarang ke admin dashboard
      if (route == Routes.ADMIN_DASHBOARD) {
        // tampilkan warning
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.snackbar(
            'Access Denied',
            'Admin privileges required',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
        });

        return const RouteSettings(name: Routes.HOME);
      }
      return null;
    }

    return null;
  }
}
