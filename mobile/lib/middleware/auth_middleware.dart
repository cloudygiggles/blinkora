import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../app/data/providers/auth_provider.dart';
import '../../app/routes/app_pages.dart';

class AuthMiddleware extends GetMiddleware {
  final AuthProvider _authProvider = Get.find();

  @override
  RouteSettings? redirect(String? route) {
    // Jika tidak login → redirect ke login
    if (!_authProvider.isAuthenticated) {
      return const RouteSettings(name: Routes.LOGIN);
    }
    return null;
  }
}
