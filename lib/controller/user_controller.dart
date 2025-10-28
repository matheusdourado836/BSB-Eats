import 'package:bsb_eats/service/restaurant_service.dart';
import 'package:bsb_eats/service/social_media_service.dart';
import 'package:bsb_eats/service/user_service.dart';
import 'package:bsb_eats/shared/model/enums.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../shared/model/app_feedback.dart';
import '../shared/model/favorite.dart';
import '../shared/model/notification.dart';
import '../shared/model/post.dart';
import '../shared/model/restaurante.dart';
import '../shared/model/user.dart';

class UserController extends ChangeNotifier {
  static final UserService _service = UserService();
  static final RestaurantService _restaurantService = RestaurantService();
  static final SocialMediaService _socialMediaService = SocialMediaService();
  MyUser? currentUser;
  List<MyUser> allUsers = [];
  DocumentSnapshot? lastPostDoc;
  bool loading = false;

  void notify() => notifyListeners();

  Future<void> fetchUsers() async {
    loading = true;
    notifyListeners();
    allUsers = await _service.fetchUsers();
    loading = false;
    notifyListeners();
  }

  void updateCurrentUser(MyUser? user) {
    currentUser = user;
    notifyListeners();
  }

  Future<int> getUserCount() async => _service.getUserCount();

  Future<int> getUserPostsCount(String? userId) async => _service.getUserPostsCount(userId);

  Future<int> getFeedbacksCount() async => _service.getFeedbacksCount();

  Future<int> getNotificationsCount() async => _service.getNotificationsCount(currentUser?.globalNotificationsRead, currentUser?.globalNotificationsDeleted);

  Future<List<VisitedRestaurant>> getVisitedRestaurants() async {
    final docs = await _service.getVisitedRestaurants();
    currentUser!.visitedPlaces ??= [];
    currentUser!.visitedPlaces = docs.map((doc) => doc["id"]).cast<String>().toList();
    List<VisitedRestaurant> restaurants = [];
    for(final id in currentUser!.visitedPlaces ?? []) {
      final restaurant = await _restaurantService.getRestaurantById(id: id);
      if(restaurant != null) {
        restaurants.add(VisitedRestaurant(
          restaurante: restaurant,
          visitedAt: docs.firstWhere((element) => element["id"] == id)["createdAt"].toDate(),
        ));
      }
    }
    restaurants.sort((a,b) => b.visitedAt!.compareTo(a.visitedAt!));

    return restaurants;
  }

  Future<void> setVisitedRestaurant({required String? restaurantId, bool value = true}) async {
    if(value) {
      currentUser!.visitedPlaces?.add(restaurantId!);
    }else {
      currentUser!.visitedPlaces?.removeWhere((element) => element == restaurantId);
    }
    await _service.setVisitedRestaurant(restaurantId: restaurantId, value: value);
  }

  Future<List<Post>> fetchUserPosts(String userId, {int pageSize = 20, DocumentSnapshot? startAfter}) async {
    final docs = await _socialMediaService.fetchUserPosts(userId, pageSize: pageSize, startAfter: startAfter);
    final userPosts = docs.map((doc) => Post.fromJson(doc.data()! as Map<String, dynamic>)).toList();
    for(final post in userPosts) {
      post.author = await _service.getUserById(id: post.authorID!);
      post.restaurant = await _restaurantService.getRestaurantById(id: post.taggedRestaurant!.first);
    }
    lastPostDoc = docs.lastOrNull;
    notifyListeners();

    return userPosts;
  }

  Future<void> deleteReview(String restaurantId, String? reviewId) async => await _restaurantService.deleteReview(restaurantId, reviewId);

  Stream<QuerySnapshot<Map<String, dynamic>>> get getNotificationStream => _service.getGlobalNotificationStream();

  Stream<QuerySnapshot<Map<String, dynamic>>> get getUserNotificationStream => _service.getUserNotificationStream();

  Future<void> getNotifications() async {
    loading = true;
    notifyListeners();
    currentUser!.notifications ??= [];
    currentUser!.notifications = await _service.getNotifications();
    currentUser!.notifications?.removeWhere((element) => currentUser!.globalNotificationsDeleted!.contains(element.id));
    setGlobalNotificationsRead(currentUser!.notifications);
    currentUser!.notifications?.sort((a,b) => b.createdAt!.compareTo(a.createdAt!));
    loading = false;
    notifyListeners();
    return;
  }

  void setGlobalNotificationsRead(List<MyNotification>? notifications) {
    for(final notification in notifications ?? []) {
      currentUser!.globalNotificationsRead ??= [];
      notification.read = currentUser!.globalNotificationsRead!.contains(notification.id);
    }
  }

  Future<void> deleteAllNotifications() async {
    await _service.deleteAllNotifications();
    final globalNotifications = currentUser!.notifications?.where((n) => n.type == NotificationType.GLOBAL).toList();
    final globalNotificationsIds = globalNotifications?.map((n) => n.id).nonNulls.toList();
    currentUser!.globalNotificationsDeleted ??= [];
    currentUser?.globalNotificationsDeleted!.addAll(globalNotificationsIds!);
    updateUserData({"globalNotificationsDeleted": FieldValue.arrayUnion(globalNotificationsIds!)});
    currentUser!.notifications = [];
    notifyListeners();
    return;
  }

  Future<bool> setNotification(Map<String, dynamic> data) async => _service.setNotification(data);

  Future<void> setNotificationRead({required String notificationId, NotificationType? type}) async {
    currentUser!.globalNotificationsRead ??= [];
    currentUser!.globalNotificationsRead?.add(notificationId);
    return await _service.setNotificationRead(notificationId: notificationId, type: type);
  }

  Future<void> getFavorites() async {
    loading = true;
    notifyListeners();
    currentUser!.favorites ??= [];
    currentUser!.favorites = await _service.getFavorites();
    loading = false;
    notifyListeners();
    return;
  }

  Future<void> toggleFavorite(bool isFavorite, Favorite favorite) async {
    if(isFavorite) {
      currentUser!.favorites?.removeWhere((element) => element.placeId == favorite.placeId);
    }else {
      currentUser!.favorites?.add(favorite);
    }
    notifyListeners();
    return _service.toggleFavorite(isFavorite, favorite);
  }

  Future<void> removeFollower(Follower follower) async {
    currentUser!.followers?.removeWhere((element) => element.id == follower.id);
    notifyListeners();
    return _service.removeFollower(follower);
  }

  Future<void> toggleFollow(bool isFollowing, Follower follower, String username) async {
    currentUser?.following ??= [];
    if(isFollowing) {
      currentUser!.followingCount = (currentUser!.followingCount ?? 1) - 1;
      currentUser!.following?.removeWhere((element) => element.id == follower.id);
    }else {
      currentUser!.followingCount = (currentUser!.followingCount ?? 0) + 1;
      currentUser!.following?.add(follower);
    }
    notifyListeners();
    return _service.toggleFollow(isFollowing, follower, username);
  }

  Future<bool> checkIfIsFollowing({required String userId}) async => _service.checkIfIsFollowing(userId: userId);

  Future<List<Follower>?> getFollowersAndFollowing({required String? userId, required String collection}) async {
    return await _service.getFollowersAndFollowing(userId: userId, collection: collection);
  }

  Future<int> getFollowersAndFollowingCount({required String? userId, required String collection}) async {
    return await _service.getFollowersAndFollowingCount(userId: userId, collection: collection);
  }

  Future<void> getLikedPosts() async {
    currentUser!.likedPosts ??= [];
    currentUser!.likedPosts = await _service.getLikedPosts(userId: currentUser!.id!);
  }

  Future<void> toggleLike(bool isLiked, Post post, Like like, String username) async {
    currentUser!.likedPosts ??= [];
    if(isLiked) {
      currentUser!.likedPosts?.removeWhere((element) => element.id == like.id);
      currentUser!.likes?.removeWhere((element) => element.id == like.id);
    }else {
      currentUser!.likedPosts?.add(post);
      currentUser!.likes?.add(like);
    }
    notifyListeners();
    return _service.toggleLike(isLiked, post, like, username);
  }

  Future<MyUser?> getUserById(String? id) async => await _service.getUserById(id: id);

  Future<void> updateUserProfilePicture(MyUser user) async {
    final photoUrl = await _service.updateUserProfilePicture(user);
    currentUser!.profilePhotoUrl = photoUrl;
  }

  Future<List<AppFeedback>> fetchFeedbacks() async => _service.fetchFeedbacks();

  Future<void> sendFeedback({required AppFeedback feedback}) async => _service.sendFeedback(feedback: feedback);

  Future<bool> isUsernameAvailable(String username) async => _service.isUsernameAvailable(username);

  Future<void> updateUsername({required String username, required String oldUsername}) async => _service.updateUsername(username: username, oldUsername: oldUsername);

  Future<void> updateUserData(Map<String, dynamic> info, {String? userId}) async => _service.updateUserData(info, userId: userId);

  Future<String?> getToken() async => _service.getToken();
}