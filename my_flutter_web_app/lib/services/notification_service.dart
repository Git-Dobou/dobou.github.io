import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// For web, you might need to ensure 'notification.js' from the plugin is correctly set up if manual steps are needed.
// Usually, the plugin handles this.

class NotificationService {
  static final NotificationService _notificationService = NotificationService._internal();
  factory NotificationService() => _notificationService;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // For Web, initialization is often simpler as it uses browser capabilities.
    // The plugin's documentation for web setup should be followed.
    // For web, specific 'webInitializationSettings' might not be needed for basic setup,
    // but permission request is key.

    // Initialization settings for different platforms (only web relevant for now based on project)
    // Android Initialization Settings (Example if you were to add Android)
    // const AndroidInitializationSettings initializationSettingsAndroid =
    //     AndroidInitializationSettings('@mipmap/ic_launcher'); // Default icon

    // Darwin (iOS/macOS) Initialization Settings (Example)
    // const DarwinInitializationSettings initializationSettingsDarwin =
    //     DarwinInitializationSettings(
      // onDidReceiveLocalNotification: onDidReceiveLocalNotification, // For older iOS versions
    // );

    // Web specific: The plugin should handle JS interop. 
    // We mainly ensure the plugin is initialized.
    const InitializationSettings initializationSettings = InitializationSettings(
      // android: initializationSettingsAndroid, // Uncomment if adding Android
      // iOS: initializationSettingsDarwin,       // Uncomment if adding iOS
      // macOS: initializationSettingsDarwin,     // Uncomment if adding macOS
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      // onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      // onDidReceiveBackgroundNotificationResponse: onDidReceiveBackgroundNotificationResponse, // If handling background
    );
    print("NotificationService initialized.");
  }

  // Optional: Callback for when a notification is tapped and app is already open (Foreground)
  // void onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async {
  //   final String? payload = notificationResponse.payload;
  //   if (notificationResponse.payload != null) {
  //     print('notification payload: \$payload');
  //   }
  //   // Example: navigate to a specific screen based on payload
  //   // await Navigator.push(context, MaterialPageRoute<void>(builder: (context) => SecondScreen(payload)));
  // }

  Future<void> requestPermissions() async {
    // For web, this might not be explicitly called via the plugin in the same way as mobile.
    // The browser usually handles permission requests upon the first attempt to show a notification.
    // This method can be a good place for platform-specific permission requests if needed.
    // For web, we can rely on the browser's first-use prompt when show() is called.
    print("Permissions for notifications will be requested by the browser on first use if not already granted, or if this method is adapted for dart:html's Notification.requestPermission().");
    
    // Example for requesting Android permissions explicitly (if targeting Android)
    // if (Theme.of(context).platform == TargetPlatform.android) { // Requires context or different check
    // final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
    //     flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
    //         AndroidFlutterLocalNotificationsPlugin>();
    // final bool? granted = await androidImplementation?.requestNotificationsPermission();
    // print("Android Notification Permission Granted: \$granted");
    // }
  }

  Future<void> showNotification(int id, String title, String body, String payload) async {
    // For web, NotificationDetails is basic. For mobile, it's more specific.
    const NotificationDetails notificationDetails = NotificationDetails(); 

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
    print("Notification shown: id=\$id, title=\$title");
  }

  Future<void> scheduleTestNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
    String payload = 'test_payload',
  }) async {
    // Web browsers do not support true background scheduled notifications via JavaScript like mobile OSes do.
    // flutter_local_notifications for web can show notifications immediately or with a delay if the tab is active.
    // It cannot schedule a notification to appear if the browser/tab is closed and then reopened at a later time.

    final now = DateTime.now();
    if (scheduledDateTime.isAfter(now)) {
      final delay = scheduledDateTime.difference(now);
      print("Web: Notification for id=\$id, title='\$title' is scheduled in \$delay. It will show if app tab is active.");
      Future.delayed(delay, () {
        // Re-check if app context is still valid if this were a long-lived service
        showNotification(id, title, body, payload);
      });
    } else {
      // If scheduled time is past or now, show immediately for test purposes
      print("Web: Notification for id=\$id, title='\$title' is past due, showing immediately.");
      await showNotification(id, title, body, payload);
    }
  }
}
