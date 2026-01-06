
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/notification_log_model.dart';

class LocalStorageService extends GetxService {
  static const String notificationBoxName = 'notification_log_box';

  late final Box<NotificationLogModel> _notificationBox;

  Box<NotificationLogModel> get notificationBox => _notificationBox;

  Future<LocalStorageService> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(NotificationLogModelAdapter().typeId)) {
      Hive.registerAdapter(NotificationLogModelAdapter());
    }

    _notificationBox =
        await Hive.openBox<NotificationLogModel>(notificationBoxName);

    return this;
  }

  Future<void> close() async {
    await _notificationBox.close();
  }
}
