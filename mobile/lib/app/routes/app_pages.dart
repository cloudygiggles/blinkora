import 'package:blinkora/app/modules/address_list/bindings/address_list_binding.dart';
import 'package:blinkora/app/modules/address_list/views/address_list_view.dart';
import 'package:blinkora/app/modules/checkout/bindings/checkout_binding.dart';
import 'package:blinkora/app/modules/checkout/views/checkout_view.dart';
import 'package:blinkora/app/modules/order_history/bindings/order_history_binding.dart';
import 'package:blinkora/app/modules/order_history/views/order_history_view.dart';
import 'package:get/get.dart';

import '../modules/auth/bindings/auth_binding.dart';
import '../modules/auth/views/login_view.dart';
import '../modules/auth/views/register_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/admin/bindings/admin_binding.dart';
import '../modules/admin/views/admin_views.dart';
import '../modules/location/bindings/address_location_binding.dart';
import '../modules/location/views/address_location_view.dart';
import '../../middleware/auth_middleware.dart';
//import '../../middleware/admin_middleware.dart';
import '../../middleware/role_check_middleware.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.LOGIN;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
      middlewares: [AuthMiddleware(), RoleCheckMiddleware()],
    ),

    GetPage(
      name: _Paths.ADMIN_DASHBOARD,
      page: () => const AdminProductView(),
      binding: AdminBinding(),
      middlewares: [AuthMiddleware(), RoleCheckMiddleware()],
    ),

    GetPage(
      name: _Paths.LOCATION,
      page: () => AddressLocationView(),
      binding: AddressLocationBinding(),
      middlewares: [AuthMiddleware(), RoleCheckMiddleware()],
    ),

    GetPage(
      name: _Paths.ADDRESS_LIST,
      page: () => const AddressListView(),
      binding: AddressListBinding(),
      middlewares: [AuthMiddleware(), RoleCheckMiddleware()],
    ),

    GetPage(
      name: _Paths.HISTORY,
      page: () => const OrderHistoryView(),
      binding: OrderHistoryBinding(),
      middlewares: [AuthMiddleware(), RoleCheckMiddleware()],
    ),

    GetPage(
      name: _Paths.CHECKOUT,
      page: () => CheckoutView(),
      binding: CheckoutBinding(),
    ),

    GetPage(
      name: _Paths.LOGIN,
      page: () => const LoginView(),
      binding: AuthBinding(),
    ),

    GetPage(
      name: _Paths.REGISTER,
      page: () => const RegisterView(),
      binding: AuthBinding(),
    ),
  ];
}
