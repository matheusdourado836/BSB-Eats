import 'package:bsb_eats/service/user_service.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../main.dart';
import '../shared/model/custom_notification.dart';
import '../shared/widgets/show_simple_notification.dart';
import 'notification_service.dart';

class FirebaseMessagingService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final NotificationService _notificationService = NotificationService();
  static final FirebaseFunctions functions = FirebaseFunctions.instance;
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

  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

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
      navigatorKey?.currentState?.pushNamed(message.data["route"] ?? '', arguments: message.data["arguments"]);
    });
    FirebaseMessaging.instance.getInitialMessage().then((message) => {
      if(message != null) {
        navigatorKey?.currentState?.pushNamed(message.data["route"] ?? '', arguments: message.data["arguments"])
      }
    });
  }

  void _foregroundNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    AppleNotification? ios = message.notification?.apple;

    if(notification != null) {
      final id = android?.hashCode ?? ios?.hashCode ?? 0;

      showNotification(
        title: notification.title ?? '',
        subtitle: notification.body,
        image: message.data["image"],
        route: message.data["route"],
        arguments: message.data["arguments"]
      );


      _notificationService.showNotification(
        CustomNotification(
          id: id,
          title: notification.title ?? '',
          body: notification.body ?? '',
          route: message.data["route"] ?? '',
          arguments: message.data["arguments"] ?? '',
          image: message.data["image"] ?? '',
          payload: message.data["route"] ?? ''
        ),
        message.data["route"]
      );
    }
  }

  Future<bool> sendGroupNotification(Map<String, dynamic> data) async {
    final callable = functions.httpsCallable('sendNotification');

    final res = await callable.call(data);
    return res.data["success"] = true;
  }

  Future<void> sendLikeNotification({required String targetId, required String postId, required String username}) async {
    final callable = functions.httpsCallable('notifyPostLiked');

    await callable.call({
      'targetUserId': targetId,
      'username': username,
      'postId': postId,
    });
  }

  Future<void> sendFollowerNotification({required String targetId, required String userId, required String username}) async {
    final callable = functions.httpsCallable('notifyNewFollower');

    await callable.call({
      'targetUserId': targetId,
      'userId': userId,
      'username': username,
    });
  }

  Future<void> sendCommentNotification({required String? targetId, required String? postId, required String? username, required String? commentText}) async {
    final callable = functions.httpsCallable('notifyNewComment');

    await callable.call({
      'targetUserId': targetId,
      'postId': postId,
      'username': username,
      'commentText': commentText,
    });
  }

  Future<void> sendTaggedPeopleNotification({required List<String>? targetIds, required String? postId, required String? username}) async {
    final callable = functions.httpsCallable('notifyTaggedPeople');

    await callable.call({
      'targetIds': targetIds,
      'postId': postId,
      'username': username,
    });
  }
}