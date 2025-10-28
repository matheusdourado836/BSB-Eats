import 'dart:io';
import 'package:bsb_eats/service/firebase_messaging_service.dart';
import 'package:bsb_eats/service/restaurant_service.dart';
import 'package:bsb_eats/service/social_media_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../shared/model/app_feedback.dart';
import '../shared/model/enums.dart';
import '../shared/model/favorite.dart';
import '../shared/model/notification.dart';
import '../shared/model/post.dart';
import '../shared/model/user.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _database = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseMessagingService _messagingService = FirebaseMessagingService();
  final SocialMediaService _socialMediaService = SocialMediaService();
  final RestaurantService _restaurantService = RestaurantService();

  Future<List<MyUser>> fetchUsers() async {
    List<MyUser> users = [];
    final docs = await _database.collection('users').get();
    for(final doc in docs.docs) {
      if(doc.exists) {
        final user = MyUser.fromJson(doc.data());
        users.add(user);
      }
    }

    return users;
  }

  Future<int> getUserCount() async {
    AggregateQuerySnapshot snapshot = await _database
      .collection("users")
      .count()
      .get();

    return snapshot.count ?? 0;
  }

  Future<int> getUserPostsCount(String? userId) async {
    AggregateQuerySnapshot snapshot = await _database
      .collection("posts")
      .where('authorID', isEqualTo: userId)
      .count()
      .get();

    return snapshot.count ?? 0;
  }

  Future<int> getFeedbacksCount() async {
    AggregateQuerySnapshot snapshot = await _database
      .collection("feedbacks")
      .count()
      .get();

    return snapshot.count ?? 0;
  }

  Future<int> getNotificationsCount(List<String>? seenNotifications, List<String>? deletedNotifications) async {
    Future<AggregateQuerySnapshot> snapshot = _database
      .collection('users')
      .doc(_auth.currentUser!.uid)
      .collection('notifications')
      .where('read', isEqualTo: false)
      .count()
      .get();
    final globalQuery = _database.collection('notifications').get();
    final results = await Future.wait([
      snapshot,
      globalQuery,
    ]);

    final globalDocs = results[1] as QuerySnapshot<Map<String, dynamic>>;
    final unseenGlobal = globalDocs.docs.where((doc) => !seenNotifications!.contains(doc.id) && !deletedNotifications!.contains(doc.id)).toList();
    final unseenUser = results[0] as AggregateQuerySnapshot;

    final total = (unseenUser.count ?? 0) + (unseenGlobal.length);

    return total;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getGlobalNotificationStream() {
    return _database.collection('notifications').snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getUserNotificationStream() {
    return _database
      .collection('users')
      .doc(_auth.currentUser!.uid)
      .collection('notifications')
      .where('read', isEqualTo: false)
      .snapshots();
  }

  Future<List<MyNotification>?> getNotifications() async {
    List<MyNotification> notifications = [];
    final docs = _database.collection('users').doc(_auth.currentUser!.uid).collection('notifications').get();
    final globalDocs = _database.collection('notifications').get();
    final results = await Future.wait([
      docs,
      globalDocs,
    ]);
    for(final doc in [...results[0].docs, ...results[1].docs]) {
      if(doc.exists) {
        final notification = MyNotification.fromJson(doc.data());
        notification.id = doc.id;
        notifications.add(notification);
      }
    }

    return notifications;
  }

  Future<void> deleteAllNotifications() async {
    final docs = await _database.collection('users').doc(_auth.currentUser!.uid).collection('notifications').get();
    for(final doc in docs.docs) {
      if(doc.exists) {
        await doc.reference.delete();
      }
    }
    return;
  }

  Future<List<Favorite>?> getFavorites() async {
    try {
      List<Favorite> favorites = [];
      await _database.collection('users').doc(_auth.currentUser?.uid).collection('favorites').get().then((res) async {
        if(res.docs.isNotEmpty) {
          final docs = res.docs;
          for(final doc in docs) {
            if(doc.exists) {
              final restaurant = await _restaurantService.getRestaurantById(id: doc.id);
              favorites.add(Favorite(
                name: restaurant?.nome,
                photoUrl: restaurant?.image,
                categoriaIndex: restaurant?.categoria?.code,
                rating: restaurant?.avaliacao,
                placeId: doc.id,
              ));
            }
          }
        }
      });

      return favorites;

    }catch(e) {
      return null;
    }
  }

  Future<void> toggleFavorite(bool isFavorite, Favorite favorite) async {
    if(isFavorite) {
      await _database.collection('users').doc(_auth.currentUser?.uid).collection('favorites').doc(favorite.placeId).delete();
      return;
    }
    return await _database.collection('users').doc(_auth.currentUser?.uid).collection('favorites').doc(favorite.placeId).set({});
  }

  Future<void> removeFollower(Follower follower) async {
    await _database.collection('users').doc(_auth.currentUser?.uid).collection('followers').doc(follower.id).delete();
    await _database.collection('users').doc(follower.id).collection('following').doc(_auth.currentUser?.uid).delete();
    return;
  }

  Future<void> toggleFollow(bool isFollowing, Follower follower, String username) async {
    if(isFollowing) {
      await _database.collection('users').doc(_auth.currentUser?.uid).collection('following').doc(follower.id).delete();
      await _database.collection('users').doc(follower.id).collection('followers').doc(_auth.currentUser?.uid).delete();
      return;
    }
    sendFollowerNotification(targetId: follower.id!, userId: _auth.currentUser!.uid, username: username);
    final userFollowerJson = {
      'id': _auth.currentUser?.uid,
      'nome': _auth.currentUser?.displayName,
    };
    await _database.collection('users').doc(follower.id).collection('followers').doc(_auth.currentUser?.uid).set(userFollowerJson);
    return await _database.collection('users').doc(_auth.currentUser?.uid).collection('following').doc(follower.id).set(follower.toJson());
  }

  Future<bool> checkIfIsFollowing({required String userId}) async {
    final doc = await _database.collection('users').doc(_auth.currentUser?.uid).collection('following').doc(userId).get();
    return doc.exists;
  }

  Future<void> toggleLike(bool isLiked, Post post, Like like, String username) async {
    if(isLiked) {
      await _database.collection('users').doc(_auth.currentUser?.uid).collection('likes').doc(like.id).delete();
      await _database.collection('posts').doc(like.id).collection('likes').doc(_auth.currentUser?.uid).delete();
      return;
    }
    if(post.authorID != _auth.currentUser?.uid) {
      sendLikeNotification(targetId: post.authorID!, postId: like.id!, username: username);
    }
    final userFollowerJson = {
      'id': _auth.currentUser?.uid,
      'nome': _auth.currentUser?.displayName,
    };
    await _database.collection('posts').doc(like.id).collection('likes').doc(_auth.currentUser?.uid).set(userFollowerJson);
    return await _database.collection('users').doc(_auth.currentUser?.uid).collection('likes').doc(like.id).set(like.toJson());
  }

  Future<void> sendLikeNotification({
    required String targetId, 
    required String postId, 
    required String username
  }) async => _messagingService.sendLikeNotification(targetId: targetId, postId: postId, username: username);

  Future<void> sendFollowerNotification({
    required String targetId,
    required String username,
    required String userId,
  }) async => _messagingService.sendFollowerNotification(targetId: targetId, userId: userId, username: username);

  Future<void> sendCommentNotification({
    required String? targetId,
    required String? postId,
    required String? username,
    required String? commentText}) async => _messagingService.sendCommentNotification(targetId: targetId, postId: postId, username: username, commentText: commentText);

  Future<MyUser?> getUserById({required String? id}) async {
    try {
      MyUser? user;
      await _database.collection("users").doc(id).get().then((DocumentSnapshot doc) async {
        if (doc.exists) {
          final dbUser = doc.data() as Map<String, dynamic>;
          user = MyUser.fromJson(dbUser);
        }
      });

      return user;
    }catch(e) {
      return null;
    }
  }

  Future<void> setVisitedRestaurant({required String? restaurantId, bool value = true}) async {
    if(value) {
      return await _database.collection('users').doc(_auth.currentUser?.uid).collection('visited').doc(restaurantId).set({'createdAt': FieldValue.serverTimestamp()});
    }else {
      return await _database.collection('users').doc(_auth.currentUser?.uid).collection('visited').doc(restaurantId).delete();
    }
  }

  Future<List<Map<String, dynamic>>> getVisitedRestaurants() async {
    final docs = await _database.collection('users').doc(_auth.currentUser?.uid).collection('visited').get();

    return docs.docs.nonNulls.map((doc) {
      final data = doc.data();
      data["id"] = doc.id;
      return data;
    }).toList();
  }

  Future<List<Post>> getLikedPosts({String? userId}) async {
    List<Post> likedPosts = [];
    final likesSnapshot = await _database.collection("users").doc(userId).collection('likes').get();
    final likes = likesSnapshot.docs.map((doc) => Like.fromJson(doc.data())).toList();
    if(likes.isNotEmpty) {
      final likeIds = likes.map((like) => like.id).toList();
      final postSnapshot = await _database.collection('posts').where('id', whereIn: likeIds).get();
      for(final post in postSnapshot.docs) {
        final postModel = await _socialMediaService.fetchPostById(post.id);
        if(postModel != null) {
          postModel.restaurant = await _restaurantService.getRestaurantById(id: postModel.taggedRestaurant!.first);
          likedPosts.add(postModel);
        }
      }
    }

    return likedPosts;
  }

  Future<List<Follower>?> getFollowersAndFollowing({required String? userId, required String collection}) async {
    try {
      List<Follower> followers = [];
      await _database.collection('users').doc(userId).collection(collection).get().then((res) {
        if(res.docs.isNotEmpty) {
          final docs = res.docs;
          for(final doc in docs) {
            if(doc.exists) {
              final follower = Follower.fromJson(doc.data());
              followers.add(follower);
            }
          }
        }
      });

      return followers;

    }catch(e) {
      return null;
    }
  }

  Future<int> getFollowersAndFollowingCount({required String? userId, required String collection}) async {
    AggregateQuerySnapshot snapshot = await _database
      .collection("users")
      .doc(userId)
      .collection(collection)
      .count()
      .get();

    return snapshot.count ?? 0;
  }

  Future<List<AppFeedback>> fetchFeedbacks() async {
    List<AppFeedback> feedbacks = [];
    final docs = await _database.collection('feedbacks').get();
    for(final doc in docs.docs) {
      if(doc.exists) {
        final feedback = AppFeedback.fromJson(doc.data());
        feedback.user = await getUserById(id: feedback.authorId);
        feedbacks.add(feedback);
      }
    }
    return feedbacks;
  }

  Future<void> sendFeedback({required AppFeedback feedback}) async {
    final ref = await _database.collection('feedbacks').add(feedback.toJson());
    final feedbackId = ref.id;
    await _database.collection('feedbacks').doc(feedbackId).update({'id': feedbackId, 'createdAt': FieldValue.serverTimestamp()});
    return;
  }

  Future<bool> setNotification(Map<String, dynamic> data) async => _messagingService.sendGroupNotification(data);

  Future<void> setNotificationRead({required String notificationId, NotificationType? type}) async {
    if(type == NotificationType.GLOBAL) {
      updateUserData({"globalNotificationsRead": FieldValue.arrayUnion([notificationId])});
      return;
    }
    return await _database
      .collection('users')
      .doc(_auth.currentUser?.uid)
      .collection('notifications')
      .doc(notificationId)
      .update({'read': true});
  }

  Future<String?> updateUserProfilePicture(MyUser user) async {
    try {
      final file = File(user.profilePhotoUrl!);
      final fileName = file.path.split('/').last;
      final timeStamp = DateTime.now().microsecondsSinceEpoch;
      final uploadRef = _storage.ref().child('users/${user.id!}/$timeStamp-$fileName');
      final files = await _storage.ref().child('users/${user.id!}').listAll();
      if(files.items.isNotEmpty) {
        await files.items.first.delete();
      }
      await uploadRef.putFile(file).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw 'Upload timeout limit reached'
      );

      String photoURL = await uploadRef.getDownloadURL();
      user.profilePhotoUrl = photoURL;
      await _auth.currentUser!.updatePhotoURL(photoURL);
      await updateUserData({'profilePhotoUrl': photoURL}, userId: user.id!);
      return photoURL;
    }on FirebaseException catch(_) {
      return null;
    }
  }

  Future<bool> isUsernameAvailable(String username) async {
    final snapshot = await _database
        .collection('usernames')
        .get();

    return snapshot.docs.where((doc) => doc.id == username.toLowerCase()).isEmpty;
  }

  Future<void> updateUsername({required String username, required String oldUsername}) async {
    await _database.collection('usernames').doc(oldUsername).delete();
    await _database.collection('usernames').doc(username).set({});
    return;
  }

  Future<void> updateUserData(Map<String, dynamic> info, {String? userId}) async {
    if(userId == null && _auth.currentUser == null) return;
    return await _database.collection('users').doc(userId ?? _auth.currentUser?.uid).update(info);
  }

  Future<String?> getToken() async => _messagingService.getToken();
}