import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // Android settings: ic_launcher is a standard launcher icon that exists on every flutter project
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle click if needed in future
      },
    );

    _initialized = true;
  }

  Future<void> requestPermission() async {
    await initialize();
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  Future<void> showChatNotification({
    required int id,
    required String senderName,
    required String messageText,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'chat_notifications_channel',
      'Pesan Chat',
      channelDescription: 'Notifikasi untuk pesan chat baru',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      id,
      senderName,
      messageText,
      notificationDetails,
    );
  }
}
