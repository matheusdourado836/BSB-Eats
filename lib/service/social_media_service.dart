import 'dart:io';
import 'package:bsb_eats/service/firebase_messaging_service.dart';
import 'package:bsb_eats/shared/model/comment.dart';
import 'package:bsb_eats/shared/model/notification.dart';
import 'package:bsb_eats/shared/model/post.dart';
import 'package:bsb_eats/shared/model/restaurante.dart';
import 'package:bsb_eats/shared/model/user.dart';
import 'package:bsb_eats/shared/util/extensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class SocialMediaService {
  static final FirebaseFirestore _database = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseMessagingService _messagingService = FirebaseMessagingService();

  Future<List<QueryDocumentSnapshot<Object?>>> fetchPosts({int pageSize = 20, DocumentSnapshot? startAfter}) async {
    Query query = _database.collection('posts').orderBy('createdAt', descending: true).limit(pageSize);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snapshot = await query.get();

    return snapshot.docs.nonNulls.toList();
  }

  Future<List<Like>> fetchPostLikes({required String postId}) async {
    final likesSnapshot = await _database.collection('posts').doc(postId).collection('likes').get();
    final likes = likesSnapshot.docs.map((doc) => Like.fromJson(doc.data())).toList();

    return likes;
  }

  Future<List<QueryDocumentSnapshot<Object?>>> fetchUserPosts(String userId, {int pageSize = 20, DocumentSnapshot? startAfter}) async {
    Query query = _database.collection('posts')
      .where('authorID', isEqualTo: userId)
      .orderBy('isPinned', descending: true)
      .orderBy('createdAt', descending: true)
      .limit(pageSize);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snapshot = await query.get();

    return snapshot.docs.nonNulls.toList();
  }

  Future<Post?> fetchPostById(String postId) async {
    final snapshot = await _database.collection('posts').doc(postId).get();
    if(!snapshot.exists || snapshot.data() == null) return null;
    final post = Post.fromJson(snapshot.data()!);
    post.likes ??= [];
    final likesSnapshot = await _database.collection('posts').doc(post.id).collection('likes').get();
    post.likes = likesSnapshot.docs.map((doc) => Like.fromJson(doc.data())).toList();
    final userSnapshot = await _database.collection('users').doc(post.authorID).get();
    post.author = MyUser.fromJson(userSnapshot.data() ?? {});
    return post;
  }

  Future<void> uploadPost(Post post) async {
    final photosUrls = List<String>.from(post.photosUrls ?? []);
    post.photosUrls = null;
    final ref = await _database.collection('posts').add(post.toJson());
    ref.update({'id': ref.id});
    await uploadImages(ref.id, photosUrls);
    if((post.taggedPeople?.where((u) => u != post.authorID).isNotEmpty) ?? false) {
      _messagingService.sendTaggedPeopleNotification(
        targetIds: post.taggedPeople!.where((u) => u != post.authorID).toList(),
        postId: ref.id,
        username: post.author?.username
      );
    }
    return;
  }

  Future<List<String>> uploadImages(String postId, List<String> imagePaths) async {
    final storageRef = _storage.ref();
    final timestamp = DateTime.now().microsecondsSinceEpoch;

    // Mapeia todos os uploads para rodarem em paralelo
    final futures = imagePaths.map((path) async {
      final file = File(path);
      final fileName = file.path.split('/').last;
      final uploadRef = storageRef.child('posts/$postId/${timestamp}_$fileName');

      // Upload com timeout
      final uploadTask = uploadRef.putFile(file).timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw Exception('Tempo de upload excedido'),
      );

      await uploadTask;
      return await uploadRef.getDownloadURL();
    }).toList();

    // Executa todos os uploads em paralelo
    final uploadedUrls = await Future.wait(futures);

    // Atualiza o post com todas as URLs de uma vez
    await updatePostData(postId, {
      'photosUrls': FieldValue.arrayUnion(uploadedUrls),
    });

    return uploadedUrls;
  }

  Future<void> deletePost({required Post post}) async {
    final reviewId = post.avaliacao?.id;
    final futures = <Future>[];
    futures.addAll([
      _database.collection('posts').doc(post.id).delete(),
      _database.collection('restaurantes').doc(post.taggedRestaurant?.firstOrNull).collection('reviews').doc(reviewId).delete()
    ]);
    post.photosUrls?.map((p) {
      futures.add(deleteImage(p));
    }).toList();
    await Future.wait(futures);
    return;
  }

  Future<void> deleteImage(String url) async {
    final ref = _storage.refFromURL(url);
    return await ref.delete();
  }

  Future<void> editPostInfo(Post post) async {
    await _database.collection('posts').doc(post.id).update(post.toJson());
  }

  Future<List<MyUser>> searchUser(String query) async {
    if(query.isEmpty) return [];
    QuerySnapshot<Map<String, dynamic>>? snapshot;
    final queryFormatted = query.toLowerCase().removerAcentos();
    snapshot = await _database.collection('users').orderBy('usernameLowerCase').startAt([queryFormatted]).endAt(['$queryFormatted\uf8ff']).get();
    if(snapshot.docs.isEmpty) {
      snapshot = await _database.collection('users').orderBy('nomeLowerCase').startAt([queryFormatted]).endAt(['$queryFormatted\uf8ff']).get();
    }
    final users = snapshot.docs.map((doc) => MyUser.fromJson(doc.data())).toList();
    return users;
  }

  Future<List<Restaurante>> searchRestaurants(String query) async {
    if(query.isEmpty) return [];
    final queryFormatted = query.toLowerCase().removerAcentos();
    final snapshot = await _database.collection('restaurantes').orderBy('lowerCaseName').startAt([queryFormatted]).endAt(['$queryFormatted\uf8ff']).get();
    final restaurantes = snapshot.docs.map((doc) => Restaurante.fromJson(doc.data())).toList();
    if(restaurantes.isEmpty) {
      restaurantes.add(Restaurante(id: '404'));
    }
    return restaurantes;
  }

  Future<List<Comment>?> fetchComments({required String postId}) async {
    final snapshot = await _database.collection('posts').doc(postId).collection('comments').get();
    final comments = snapshot.docs.map((doc) => Comment.fromJson(doc.data())).toList();
    comments.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
    for(final comment in comments) {
      final userSnapshot = await _database.collection('users').doc(comment.authorId).get();
      comment.authorName = userSnapshot.data()?['username'];
      comment.authorPhoto = userSnapshot.data()?['profilePhotoUrl'];
      comment.verifiedUser = userSnapshot.data()?['verified'];
    }
    return comments;
  }

  Future<String> postComment({required String postId, required Comment comment}) async {
    final ref = await _database.collection('posts').doc(postId).collection('comments').add(comment.toJson());
    await ref.update({'id': ref.id});
    await updatePostData(postId, {'qtdComentarios': FieldValue.increment(1)});
    return ref.id;
  }

  Future<void> deleteComment({required String postId, required String commentId}) async {
    await _database.collection('posts').doc(postId).collection('comments').doc(commentId).delete();
    await updatePostData(postId, {'qtdComentarios': FieldValue.increment(-1)});
  }
  
  Future<int> getCommentsCount(String? postId) async {
    AggregateQuerySnapshot snapshot = await _database.collection('posts').doc(postId).collection('comments').count().get();

    return snapshot.count ?? 0;
  }

  Future<int> getLikesCount(String? postId) async {
    AggregateQuerySnapshot snapshot = await _database.collection('posts').doc(postId).collection('likes').count().get();

    return snapshot.count ?? 0;
  }

  Future<int> getGlobalNotificationsCount() async {
    AggregateQuerySnapshot snapshot = await _database.collection('notifications').count().get();

    return snapshot.count ?? 0;
  }

  Future<List<MyNotification>> getGlobalNotifications() async {
    List<MyNotification> notifications = [];
    final docs = await _database.collection('notifications').get();
    for(final doc in docs.docs) {
      if(doc.exists) {
        final notification = MyNotification.fromJson(doc.data());
        notification.id = doc.id;
        notifications.add(notification);
      }
    }

    return notifications;
  }

  Future<String> uploadNotificationImage(String? path) async {
    if(path == null) return '';
    final file = File(path);
    final storageRef = _storage.ref();
    final fileName = file.path.split('/').last;
    final uploadRef = storageRef.child('notifications/$fileName');
    final uploadTask = uploadRef.putFile(file).timeout(
      const Duration(seconds: 60),
      onTimeout: () => throw Exception('Tempo de upload excedido'),
    );

    await uploadTask;
    return await uploadRef.getDownloadURL();
  }

  Future<List<String>> getCommonImages() async {
    final storageRef = _storage.ref('notifications/common');

    // Pega a lista de todos os arquivos dentro da pasta
    final listResult = await storageRef.listAll();

    // Gera URLs de download para cada arquivo encontrado
    final urls = await Future.wait(
      listResult.items.map((item) => item.getDownloadURL()),
    );

    return urls;
  }

  Future<void> deleteAllNotifications() async {
    final snapshot = await _database.collection('notifications').get();
    await Future.wait([
      ...snapshot.docs.map((d) => d.reference.delete()),
      deleteNotificationsImages(),
    ]);
    return;
  }

  Future<void> deleteNotificationsImages() async {
    final notificationsRef = _storage.ref('notifications');

    try {
      // Lista todos os arquivos dentro de /notifications
      final listResult = await notificationsRef.listAll();

      for (final item in listResult.items) {
        // Verifica se o arquivo está dentro da pasta /common
        if (item.fullPath.startsWith('notifications/common/')) {
          // pula
          continue;
        }

        // Deleta qualquer outro arquivo dentro de /notifications
        await item.delete();
      }

      return;
    } catch (e) {
      print('❌ Erro ao deletar notificações: $e');
    }
  }

  Future<void> updatePostData(String postId, Map<String, dynamic> info) async {
    return await _database.collection('posts').doc(postId).update(info);
  }
}