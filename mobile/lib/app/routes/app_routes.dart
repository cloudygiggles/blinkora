
part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  static const LOGIN = _Paths.LOGIN;
  static const REGISTER = _Paths.REGISTER;
  static const HOME = _Paths.HOME;
  static const ADMIN_DASHBOARD = _Paths.ADMIN_DASHBOARD;
  static const LOCATION = _Paths.LOCATION;
  static const CHECKOUT = _Paths.CHECKOUT;
  static const HISTORY = _Paths.HISTORY;
  static const ADDRESS_LIST = _Paths.ADDRESS_LIST;
}

abstract class _Paths {
  _Paths._();
  static const LOGIN = '/login';
  static const REGISTER = '/register';
  static const HOME = '/home';
  static const ADMIN_DASHBOARD = '/admin-dashboard';
  static const LOCATION = '/location';
  static const ADDRESS_LIST = '/address-list';
  static const CHECKOUT = '/checkout';
  static const HISTORY = '/history';
}
