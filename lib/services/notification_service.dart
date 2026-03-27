// import 'dart:io';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:timezone/data/latest_all.dart' as tz;

// class NotificationService {
//   static final NotificationService _instance = NotificationService._internal();

//   factory NotificationService() {
//     return _instance;
//   }

//   NotificationService._internal();

//   final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   Future<void> init() async {
//     tz.initializeTimeZones();

//     const AndroidInitializationSettings initializationSettingsAndroid =
//         AndroidInitializationSettings('@mipmap/launcher_icon');

//     const DarwinInitializationSettings initializationSettingsDarwin =
//         DarwinInitializationSettings(
//           requestAlertPermission: false,
//           requestBadgePermission: false,
//           requestSoundPermission: false,
//         );

//     const InitializationSettings initializationSettings =
//         InitializationSettings(
//           android: initializationSettingsAndroid,
//           iOS: initializationSettingsDarwin,
//         );

//     await _flutterLocalNotificationsPlugin.initialize(
//       settings: initializationSettings,
//     );
//   }

//   Future<void> requestPermissions() async {
//     if (Platform.isIOS) {
//       await _flutterLocalNotificationsPlugin
//           .resolvePlatformSpecificImplementation<
//             IOSFlutterLocalNotificationsPlugin
//           >()
//           ?.requestPermissions(alert: true, badge: true, sound: true);
//     } else if (Platform.isAndroid) {
//       final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
//           _flutterLocalNotificationsPlugin
//               .resolvePlatformSpecificImplementation<
//                 AndroidFlutterLocalNotificationsPlugin
//               >();

//       await androidImplementation?.requestNotificationsPermission();
//     }
//   }
// }
