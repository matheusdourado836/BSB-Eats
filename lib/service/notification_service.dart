import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../main.dart';
import '../shared/model/custom_notification.dart';

class NotificationService {
  late FlutterLocalNotificationsPlugin localNotificationsPlugin;
  late AndroidNotificationDetails androidNotificationDetails;

  NotificationService() {
    localNotificationsPlugin = FlutterLocalNotificationsPlugin();
    _setupNotifications();
  }

  Future<void> _setupNotifications() async {
    await _setupTimezone();
    await _initializeNotifications();
  }

  Future<void> _setupTimezone() async {
    tz.initializeTimeZones();
    final timezone = await FlutterTimezone.getLocalTimezone();
    final String timeZoneName = timezone.identifier;
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  }

  Future<void> _initializeNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings();
    await localNotificationsPlugin.initialize(
      const InitializationSettings(android: android, iOS: iOS),
      onDidReceiveNotificationResponse: _onSelectedNotification,
    );
  }

  void _onSelectedNotification(NotificationResponse? notificationResponse) {
    if (notificationResponse?.payload?.isEmpty ?? true) return;

    try {
      final String route = notificationResponse!.payload!;

      navigatorKey?.currentState?.pushNamedAndRemoveUntil(route, (route) => false);
    } catch (e) {
      debugPrint('Erro ao tratar payload: $e');
    }
  }

  void showNotification(CustomNotification notification, String? channelInfo) {
    final channel = (channelInfo == null) ? 'basic' : channelInfo;
    androidNotificationDetails = AndroidNotificationDetails(
      '${channel}_notification',
      channel,
      importance: Importance.max,
      priority: Priority.max,
      enableVibration: true,
      colorized: true,
      color: navigatorKey?.currentContext == null ? null : Theme.of(navigatorKey!.currentContext!).primaryColor,
    );

    localNotificationsPlugin.show(
      notification.id ?? 0,
      notification.title,
      notification.body,
      NotificationDetails(android: androidNotificationDetails),
      payload: notification.payload,
    );
  }
}