import 'dart:convert';
import 'dart:math';
import 'package:bsb_eats/service/user_service.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../main.dart';
import '../shared/model/custom_notification.dart';
import '../shared/widgets/show_simple_notification.dart';
import 'notification_service.dart';

class FirebaseMessagingService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final NotificationService _notificationService = NotificationService();
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;
  static final UserService _service = UserService();

  Future<void> initialize() async {
    await _messaging.requestPermission();
    await _messaging.setForegroundNotificationPresentationOptions(
      badge: true,
      sound: true,
      alert: true,
    );
    _tokenRefresh();
    _onMessage();
    _onMessageOpenedApp();
  }

  Future<String?> getToken() async => await _messaging.getToken();

  Future<void> _tokenRefresh() async {
    _messaging.onTokenRefresh.listen((String? token) {
      assert(token != null);

      _service.updateUserData({"fcmToken": token});
    });
  }

  Future<void> deleteToken() async => await _messaging.deleteToken();

  void _onMessage() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _foregroundNotification(message);
    });
  }

  void _onMessageOpenedApp() {
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      Sentry.captureMessage("🔔 Push recebido: message.data = ${message.data}");
      Sentry.captureMessage("🔗 PASSOU PELO onMessageOpenedApp");
      navigatorKey.currentState?.pushNamed(message.data["route"] ?? '', arguments: message.data["arguments"]);
    });
    _messaging.getInitialMessage().then((message) {
      if (message != null) {
        Sentry.captureMessage("🔗 PASSOU PELO getInitialMessage()");
        WidgetsBinding.instance.addPostFrameCallback((_) => _handleMessageNavigation(message));
      }
    });
  }

  void _handleMessageNavigation(RemoteMessage message) {
    final route = message.data["route"];
    final argsString = message.data["arguments"];

    Sentry.captureMessage("🔗 Navegando para $route com data: ${message.data}");

    // 🔹 Decodifica os argumentos se vierem em JSON
    dynamic arguments;
    if (argsString != null && argsString.isNotEmpty) {
      try {
        arguments = jsonDecode(argsString);
      } catch (_) {
        arguments = argsString; // fallback
      }
    }

    if (route?.isNotEmpty ?? false) {
      Sentry.captureMessage("🔗 Navegando para $route com args: $arguments");
      navigatorKey.currentState?.pushNamed(route, arguments: arguments);
    } else {
      Sentry.captureMessage("⚠️ Notificação sem rota válida: ${message.data}");
    }
  }

  void _foregroundNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;

    if(notification != null) {
      final random = Random.secure();
      final id = random.nextInt(100000000);
      // TODO NAO TA VINDO COMO STRING
      final arguments = message.data["arguments"] != null && message.data["arguments"].isNotEmpty
          ? jsonDecode(message.data["arguments"] ?? '{}') ?? {}
          : {} as Map<String, dynamic>;
      Sentry.logger.fmt.info("Arguments received %s", [arguments]);
      // final rewardPayload = jsonEncode({
      //   "id": arguments["id"],
      //   "points": arguments["points"],
      //   "route": "/reward"
      // });
      final route = message.data["route"];

      showNotification(
        id: id,
        title: notification.title ?? '',
        subtitle: notification.body,
        image: message.data["image"],
        route: route,
        arguments: arguments
      );


      // _notificationService.showNotification(
      //   CustomNotification(
      //     id: id,
      //     title: notification.title ?? '',
      //     body: notification.body ?? '',
      //     route: route,
      //     arguments: arguments,
      //     image: message.data["image"] ?? '',
      //     payload: route.contains('/reward') ? rewardPayload : route
      //   ),
      //   message.data["route"]
      // );
    }
  }

  Future<bool> sendGroupNotification(Map<String, dynamic> data) async {
    final callable = _functions.httpsCallable('sendNotification');

    final res = await callable.call(data);
    return res.data["success"] = true;
  }

  Future<void> sendLikeNotification({required String targetId, required String postId, required String username}) async {
    final callable = _functions.httpsCallable('notifyPostLiked');

    await callable.call({
      'targetUserId': targetId,
      'username': username,
      'postId': postId,
    });
  }

  Future<void> sendFollowerNotification({required String targetId, required String userId, required String username}) async {
    final callable = _functions.httpsCallable('notifyNewFollower');

    await callable.call({
      'targetUserId': targetId,
      'userId': userId,
      'username': username,
    });
  }

  Future<void> sendCommentNotification({required String? targetId, required String? postId, required String? username, required String? commentText}) async {
    final callable = _functions.httpsCallable('notifyNewComment');

    await callable.call({
      'targetUserId': targetId,
      'postId': postId,
      'username': username,
      'commentText': commentText,
    });
  }

  Future<void> sendCommentAnswerNotification({
    required String? postId,
    required String? postOwnerId,
    required String? commentId,
    required String? replyAuthorId,
    required String? replyAuthorName
  }) async {
    final callable = _functions.httpsCallable('notifyCommentReply');

    await callable.call({
      'postId': postId,
      'postOwnerId': postOwnerId,
      'commentId': commentId,
      'replyAuthorId': replyAuthorId,
      'replyAuthorName': replyAuthorName,
    });
  }

  Future<void> sendTaggedPeopleNotification({required List<String>? targetIds, required String? postId, required String? username}) async {
    final callable = _functions.httpsCallable('notifyTaggedPeople');

    await callable.call({
      'targetIds': targetIds,
      'postId': postId,
      'username': username,
    });
  }

  Future<void> sendUserStatusNotification({
    required String? userId,
    required String? type,
    required bool? newValue,
  }) async {
    final callable = _functions.httpsCallable('sendUserStatusNotification');

    await callable.call({
      'userId': userId,
      'type': type,
      'newValue': newValue,
    });
  }

  Future<List<ActiveNotification>> getAllActiveNotifications() async => _notificationService.getAllActiveNotifications();

  Future<void> cancelNotification(int id) async => _notificationService.cancelNotification(id);

  Future<void> cancelAllNotifications() async => _notificationService.cancelAllNotifications();
}