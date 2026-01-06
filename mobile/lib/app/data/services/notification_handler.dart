import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:blinkora/app/data/services/supabase_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../providers/notification_provider.dart';
import '../models/notification_log_model.dart';
import '../../routes/app_pages.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Pesan diterima di background: ${message.notification?.title}');
  // Note: We can't easily access Hive/GetX here without initializing them in background isolate.
  // For simplicity, we might skip logging background messages here or setup Hive again.
}

class NotificationHandler {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotification =
      FlutterLocalNotificationsPlugin();

  // Gunakan find jika sudah di-put di main.dart
  NotificationProvider get _notificationProvider {
    try {
      return Get.find<NotificationProvider>();
    } catch (e) {
      return Get.put(NotificationProvider());
    }
  }

  SupabaseService get _supabaseService {
    try {
      return Get.find<SupabaseService>();
    } catch (e) {
      return Get.put(SupabaseService());
    }
  }

  // Penting: Samakan ID ini dengan yang ada di Edge Function & AndroidManifest
  final _androidChannel = const AndroidNotificationChannel(
    'channel_notification', // ID yang sama
    'Order Updates', // Nama yang muncul di setting HP
    description: 'Notifikasi update status pemesanan',
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('blink'),
  );

  Future<void> initPushNotification() async {
    // 1. Request Permission (iOS & Android 13+)
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Buat Notification Channel di Android
    await _localNotification
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);

    // 3. Handle Terminated State (Klik notifikasi saat app mati total)
    RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage();
    if (initialMessage != null) {
      _handleMessageNavigation(initialMessage);
    }

    // 4. Handle Background State
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 5. Handle Foreground State (App sedang terbuka)
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;

      _localNotification.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            icon: '@mipmap/ic_launcher',
            sound: _androidChannel.sound,
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        // Kirim data payload agar bisa diproses saat diklik
        payload: jsonEncode(message.data),
      );

      _logNotification(notification.title, notification.body, 'push');
    });

    // 6. Handle Background/Suspended State (Klik notifikasi saat app di background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageNavigation);
  }

  // Fungsi baru untuk navigasi
  void _handleMessageNavigation(RemoteMessage message) {
    final String? orderId = message.data['order_id'];

    if (orderId != null) {
      // Jika sudah diambil atau batal, arahkan ke tab/halaman history
      Get.toNamed(Routes.HISTORY);
    }
  }

  Future<void> initLocalNotification() async {
    tz.initializeTimeZones();
    // ... logika timezone tetap sama ...

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);

    await _localNotification.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          final Map<String, dynamic> data = jsonDecode(details.payload!);
          if (data['order_id'] != null) {
            Get.toNamed(Routes.HISTORY, arguments: data['order_id']);
          }
        }
      },
    );
  }
  
  Future<void> updateTokenToSupabase() async {
    try {
      final user = _supabaseService.client.auth.currentUser;
      if (user == null) return;

      final profile = await _supabaseService.client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      if (profile['role'] == 'admin') {
        print('ℹ️ User adalah admin, token tidak akan disimpan');
        return; 
      }

      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _supabaseService.client
            .from('profiles')
            .update({'fcm_token': token})
            .eq('id', user.id);
        print('✅ Customer FCM Token Synced');
      }
    } catch (e) {
      print('❌ Sync Token Error: $e');
    }
  }

  void _logNotification(String? title, String? body, String type) {
    if (title == null) return;
    _notificationProvider.addLog(
      NotificationLogModel(
        title: title,
        body: body ?? '',
        timestamp: DateTime.now(),
        type: type,
      ),
    );
  }
}
