import 'package:bsb_eats/service/social_media_service.dart';
import 'package:bsb_eats/service/user_service.dart';
import 'package:bsb_eats/shared/model/comment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../service/restaurant_service.dart';
import '../shared/model/notification.dart';
import '../shared/model/post.dart';
import '../shared/model/restaurante.dart';
import '../shared/model/user.dart';

class SocialMediaController extends ChangeNotifier {
  static final SocialMediaService _service = SocialMediaService();
  static final UserService _userService = UserService();
  static final RestaurantService _restaurantService = RestaurantService();
  List<MyUser> users = [];
  List<Post> posts = [];
  DocumentSnapshot? lastPostDoc;
  List<Comment> comments = [];
  bool loading = false;
  bool loadingComments = false;
  bool listEmpty = false;

  Future<List<Post>> fetchPosts({int pageSize = 20, DocumentSnapshot? startAfter}) async {
    final docs = await _service.fetchPosts(pageSize: pageSize, startAfter: startAfter);
    posts = docs.map((doc) => Post.fromJson(doc.data()! as Map<String, dynamic>)).toList();
    for(final post in posts) {
      await Future.wait([
        _userService.getUserById(id: post.authorID!).then((value) => post.author = value),
        _restaurantService.getRestaurantById(id: post.taggedRestaurant!.first).then((value) => post.restaurant = value),
        _service.getCommentsCount(post.id).then((value) => post.qtdComentarios = value),
        _service.getLikesCount(post.id).then((value) => post.qtdCurtidas = value),
      ]);
    }
    lastPostDoc = docs.lastOrNull;

    return posts;
  }

  Future<Post?> fetchPostById(String postId) async {
    final post = await _service.fetchPostById(postId);
    if (post == null) return null;
    post.author = await _userService.getUserById(id: post.authorID!);
    post.restaurant = await _restaurantService.getRestaurantById(id: post.taggedRestaurant?.first ?? '');
    return post;
  }

  Future<void> getTaggedPeople(Post post) async {
    if(post.taggedPeople?.isNotEmpty ?? false) {
      post.users ??= [];
      post.users!.clear();
      for(final user in post.taggedPeople ?? []) {
        final u = await _userService.getUserById(id: user);
        if(u != null) {
          post.users!.add(u);
        }
      }
      notifyListeners();
    }
  }

  Future<List<Like>> fetchPostLikes({required String postId}) async => _service.fetchPostLikes(postId: postId);
  
  Future<void> uploadPost(Post post, bool postReview) async {
    await _service.uploadPost(post);
    if(postReview) {
      await _restaurantService.addReview(post.restaurant!.id!, post.avaliacao);
    }
    fetchPosts();
  }

  Future<void> editPostData(
    Post post, {
      bool updateReview = false,
      List<String>? imagesToDelete,
      List<String>? imagesToAdd,
    }) async {
    final futures = <Future>[];

    // Upload de novas imagens
    if (imagesToAdd?.isNotEmpty ?? false) {
      futures.add(_service.uploadImages(post.id!, imagesToAdd!).then((urls) {
        post.photosUrls ??= [];
        post.photosUrls!.addAll(urls);
      }));
    }

    // Exclusão de imagens antigas
    if (imagesToDelete?.isNotEmpty ?? false) {
      futures.add(Future.wait(imagesToDelete!.map(_service.deleteImage)).then((_) {
        post.photosUrls?.removeWhere((url) => imagesToDelete.contains(url));
      }));
    }

    // Aguarda todas as operações de imagem terminarem
    await Future.wait(futures);

    // Atualiza os dados do post
    await _service.editPostInfo(post);

    // Atualiza review, se necessário
    if (updateReview && post.restaurant != null) {
      await _restaurantService.updateReview(
        post.restaurant!.id!,
        post.avaliacao,
      );
    }
  }

  Future<void> deletePost({required Post post}) async {
    await _service.deletePost(post: post);
    await deleteReview(post.restaurant!.id!, post.avaliacao?.id);
  }

  Future<void> deleteReview(String restaurantId, String? reviewId) async => await _restaurantService.deleteReview(restaurantId, reviewId);

  Future<void> searchUser(String query) async {
    loading = true;
    listEmpty = false;
    notifyListeners();
    users = await _service.searchUser(query);
    if(users.isEmpty) {
      listEmpty = true;
    } else {
      listEmpty = false;
    }
    loading = false;
    notifyListeners();
  }

  Future<List<MyUser>> fetchUsers(String query) async {
    return await _service.searchUser(query);
  }

  Future<List<Restaurante>> searchRestaurants(String query) async => _service.searchRestaurants(query);

  Future<void> getComments({required String postId}) async {
    loadingComments = true;
    notifyListeners();
    comments = await _service.fetchComments(postId: postId) ?? [];
    loadingComments = false;
    notifyListeners();
  }

  Future<void> postComment({required String postId, required String postAuthorId, required Comment comment}) async {
    final id = await _service.postComment(postId: postId, comment: comment);
    comment.id = id;
    comments.insert(0, comment);
    if(postAuthorId != comment.authorId) {
      _userService.sendCommentNotification(
        targetId: postAuthorId,
        postId: postId,
        username: comment.authorName,
        commentText: comment.text
      );
    }
    notifyListeners();
  }

  Future<void> deleteComment({required String postId, required String commentId}) async {
    await _service.deleteComment(postId: postId, commentId: commentId);
    comments.removeWhere((element) => element.id == commentId);
    notifyListeners();
  }

  Future<void> togglePin(Post post, int value) async {
    post.isPinned = value;
    notifyListeners();

    return await updatePostData(post.id!, {'isPinned': value});
  }

  Future<int> getGlobalNotificationsCount() async => await _service.getGlobalNotificationsCount();

  Future<List<MyNotification>> getGlobalNotifications() async {
    final notifications = await _service.getGlobalNotifications();
    notifications.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
    return notifications;
  }

  Future<List<String>> getCommonImages() async => await _service.getCommonImages();

  Future<String> uploadNotificationImage(String? path) async => await _service.uploadNotificationImage(path);

  Future<void> deleteAllNotifications() async => await _service.deleteAllNotifications();

  Future<void> updatePostData(String postId, Map<String, dynamic> info) async => await _service.updatePostData(postId, info);
}