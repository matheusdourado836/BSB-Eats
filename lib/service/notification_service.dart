import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../main.dart';
import '../shared/model/custom_notification.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static final FlutterLocalNotificationsPlugin localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  factory NotificationService() => _instance;

  NotificationService._internal() {
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
      String route = notificationResponse!.payload!;
      Map<String, dynamic>? arguments;
      if(!notificationResponse.payload!.contains('/post') || !notificationResponse.payload!.contains('/user')) {
        final data = jsonDecode(notificationResponse.payload!);
        route = data["route"];
        arguments = data;
      }

      navigatorKey.currentState?.pushNamedAndRemoveUntil(route, (route) => false, arguments: arguments);
    } catch (e) {
      debugPrint('Erro ao tratar payload: $e');
    }
  }

  void showNotification(CustomNotification notification, String? channelInfo) {
    final channel = (channelInfo == null) ? 'basic' : channelInfo;
    final androidNotificationDetails = AndroidNotificationDetails(
      '${channel}_notification',
      channel,
      importance: Importance.max,
      priority: Priority.max,
      enableVibration: true,
      colorized: true,
      color: navigatorKey.currentContext == null ? null : Theme.of(navigatorKey.currentContext!).primaryColor,
    );

    localNotificationsPlugin.show(
      notification.id ?? 0,
      notification.title,
      notification.body,
      NotificationDetails(android: androidNotificationDetails),
      payload: notification.payload,
    );
  }

  Future<List<ActiveNotification>> getAllActiveNotifications() async => await localNotificationsPlugin.getActiveNotifications();

  Future<void> cancelNotification(int id) async => localNotificationsPlugin.cancel(id);

  Future<void> cancelAllNotifications() async => localNotificationsPlugin.cancelAll();
}