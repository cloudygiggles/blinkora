import 'package:blinkora/app/data/models/address_model.dart';
import 'package:blinkora/app/data/models/cart_item_model.dart';
import 'package:blinkora/app/data/models/notification_log_model.dart';
import 'package:blinkora/app/data/models/order_item_model.dart';
import 'package:blinkora/app/data/models/profile_model.dart';
import 'package:blinkora/app/data/providers/address_provider.dart';
import 'package:blinkora/app/data/providers/order_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import './app/data/providers/auth_provider.dart';
import './app/data/providers/product_provider.dart';
import './app/data/services/supabase_service.dart';
import './app/data/services/hive_service.dart';
import './app/data/services/theme_service.dart';
import './app/data/services/product_data_service.dart';
import './app/routes/app_pages.dart';
import './app/modules/auth/controllers/auth_controller.dart';
import './app/data/models/product_model.dart';
import 'app/data/services/local_storage_service.dart';
import 'app/data/services/notification_handler.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  try {
    // Initialize Hive
    await Hive.initFlutter();
    Hive.registerAdapter(ProductAdapter());
    Hive.registerAdapter(ProfileAdapter());
    Hive.registerAdapter(OrderItemAdapter());
    Hive.registerAdapter(CartItemAdapter());
    Hive.registerAdapter(AddressAdapter());
    Hive.registerAdapter(NotificationLogModelAdapter());

    await Get.putAsync(() => SupabaseService().init());
    Get.put(AddressProvider());
    await Get.putAsync<OrderProvider>(() async {
      return await OrderProvider().init();
    });

    Get.put(ProductProvider());
    Get.put(AuthProvider());
    Get.put(AuthController());

    await Get.putAsync(() => LocalStorageService().init());

    // Initialize Notification Handler
    final notificationHandler = NotificationHandler();
    await notificationHandler.initPushNotification();
    await notificationHandler.initLocalNotification();
    Get.put(notificationHandler);

    // Initialize HiveService
    await Get.putAsync(() => HiveService().init());

    // Initialize ServicesDataService terakhir (karena bergantung pada yang lain)
    await Get.putAsync(() => ProductDataService().init());

    runApp(const MyApp());
  } catch (e, stackTrace) {
    if (kDebugMode) {
      debugPrint('❌ Error during initialization:');
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Get.find<AuthProvider>();
    final authController = Get.find<AuthController>();

    // Jika tidak login, langsung ke login
    if (!authProvider.isAuthenticated) {
      return ChangeNotifierProvider(
        create: (_) => ThemeService(),
        child: _buildMaterialApp(initialRoute: Routes.LOGIN),
      );
    }

    // Jika login, tunggu role loaded dulu
    return Obx(() {
      if (!authController.isRoleLoaded.value) {
        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memuat...'),
                ],
              ),
            ),
          ),
        );
      }

      final initialRoute = authController.userRole.value == 'admin'
          ? Routes.ADMIN_DASHBOARD
          : Routes.HOME;

      debugPrint(
        '🚀 Initial route: $initialRoute (role: ${authController.userRole.value})',
      );

      return ChangeNotifierProvider(
        create: (_) => ThemeService(),
        child: _buildMaterialApp(initialRoute: initialRoute),
      );
    });
  }

  Widget _buildMaterialApp({required String initialRoute}) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          initialRoute: initialRoute,
          getPages: AppPages.routes,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeService.themeMode,
        );
      },
    );
  }
}
