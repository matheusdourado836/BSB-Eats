import 'dart:io';

import 'package:bsb_eats/shared/model/enums.dart';
import 'package:bsb_eats/shared/model/restaurante.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dio/dio.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../shared/model/avaliacao.dart';
import 'dio_client.dart';
import 'package:path/path.dart' as path;

class RestaurantService {
  static final Dio _dio = GoogleDioClient.getDio();
  static final FirebaseFirestore _database = FirebaseFirestore.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _authService = FirebaseAuth.instance;

  Future<Restaurante?> getRestaurantById({required String id}) async {
    final snapshot = await _database.collection('restaurantes').doc(id).get();
    if(snapshot.exists) {
      final restaurante = Restaurante.fromJson(snapshot.data()!);
      final reviewsSnapshot = await _database.collection('restaurantes').doc(restaurante.id).collection('reviews').get();
      restaurante.appReviews = reviewsSnapshot.docs.map((doc) => Avaliacao.fromJson(doc.data())).toList();
      return restaurante;
    }
    return null;
  }

  Future<List<QueryDocumentSnapshot<Object?>>> getRestaurants({
    int pageSize = 20,
    DocumentSnapshot? startAfter,
    int? categoryIndex,
    String? region,
    String? searchQuery,
  }) async {
    Query query = _database
        .collection('restaurantes')
        .orderBy('rating', descending: true);
    if(categoryIndex != null) {
      query = query.where('categoriaIndex', isEqualTo: categoryIndex);
    }
    if(searchQuery != null) {
      query = _database.collection('restaurantes').orderBy('lowerCaseName').startAt([searchQuery]).endAt(['$searchQuery\uf8ff']);
    }
    if(region != null) {
      query = query.where('region', isEqualTo: region);
    }

    query = query.limit(pageSize);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snapshot = await query.get();

    return snapshot.docs.nonNulls.toList();
  }

  Future<int> getRestaurantCount({
    int? categoryIndex,
    String? region,
    String? searchQuery,
  }) async {
    Query query = _database.collection('restaurantes');
    if(searchQuery != null) {
      query = query.orderBy('lowerCaseName')
        .startAt([searchQuery])
        .endAt(['$searchQuery\uf8ff']);
    }
    if(categoryIndex != null) {
      query = query.where('categoriaIndex', isEqualTo: categoryIndex);
    }
    if(region != null) {
      query = query.where('region', isEqualTo: region);
    }

    AggregateQuerySnapshot snapshot = await query
      .count()
      .get();

    return snapshot.count ?? 0;
  }

  Future<String> setRestaurantImages(String restaurantId, String image) async {
    final file = File(image);
    final fileName = file.path.split('/').last;
    final timeStamp = DateTime.now().microsecondsSinceEpoch;
    final uploadRef = _storage.ref().child('restaurants/$restaurantId/images/$timeStamp-$fileName');
    await uploadRef.putFile(file);
    String photoURL = await uploadRef.getDownloadURL();
    return photoURL;
  }

  Future<String?> setRestaurantImage(String restaurantId, String image) async {
    try {
      final file = File(image);
      final fileName = file.path.split('/').last;
      final timeStamp = DateTime.now().microsecondsSinceEpoch;
      final uploadRef = _storage.ref().child('restaurants/$restaurantId/thumb/$timeStamp-$fileName');
      final files = await _storage.ref().child('restaurants/$restaurantId/thumb').listAll();
      if(files.items.isNotEmpty) {
        await files.items.first.delete();
      }
      await uploadRef.putFile(file);

      String photoURL = await uploadRef.getDownloadURL();
      await updateRestaurantData(restaurantId, {'image': photoURL});
      return photoURL;
    }on FirebaseException catch(_) {
      return null;
    }
  }

  Future<String> uploadImageToStorage(String? restaurantId, String photoUri, {String folder = 'images'}) async {
    final dio = Dio();
    final response = await dio.get<List<int>>(
      photoUri,
      options: Options(responseType: ResponseType.bytes),
    );
    Uint8List imageData = Uint8List.fromList(response.data!);
    final extension = path.extension(photoUri).toLowerCase();
    String contentType;
    if (extension == '.png') {
      contentType = 'image/png';
    } else if (extension == '.gif') {
      contentType = 'image/gif';
    } else {
      contentType = 'image/jpeg'; // padrão
    }
    final fileName = path.basename(Uri.parse(photoUri).path);
    // 3️⃣ Cria referência no Storage
    final storageRef = _storage
        .ref()
        .child('restaurants/$restaurantId/$folder/$fileName');

    // 4️⃣ Faz o upload
    final uploadTask = storageRef.putData(
      imageData,
      SettableMetadata(contentType: contentType),
    );

    await uploadTask;

    // 5️⃣ Retorna URL de download
    final downloadUrl = await storageRef.getDownloadURL();

    return downloadUrl;
  }

  Future<String?> getPhotoUrl({required String? photoName}) async {
    try{
      final token = await FirebaseAppCheck.instance.getToken();
      final response = await _dio.post(
        'https://us-central1-foodfinderapp-b2c0d.cloudfunctions.net/getPhotoUrl',
        options: Options(
          headers: {
            'X-Firebase-AppCheck': token
          }
        ),
        data: {'photoName': photoName},
      );
      if (response.statusCode == 200) {
        return response.data['photoUri'] as String?;
      }
      return null;
    }catch(e) {
      return null;
    }
  }

  Future<void> createRestaurant(Restaurante restaurante, String thumbnail, {List<String> images = const []}) async {
    final restaurantRef = await _database.collection('restaurantes').add(restaurante.toJson());
    restaurante.id = restaurantRef.id;
    await updateRestaurantData(restaurante.id!, {"id": restaurante.id});
    final ref = await setRestaurantImage(restaurante.id!, thumbnail);
    restaurante.image = ref;
    restaurante.listImages ??= [];
    for(final photo in images) {
      final downloadUrl = await setRestaurantImages(restaurante.id!, photo);
      restaurante.listImages!.add(downloadUrl);
    }
    await updateRestaurantData(restaurante.id!, {"listImages": restaurante.listImages});
    return;
  }

  Future<void> addRestaurant(Restaurante restaurante) async {
    final restaurantRef = _database.collection('restaurantes').doc(restaurante.id);
    restaurante.listImages ??= [];

    if (restaurante.googleImages != null) {
      final futures = restaurante.googleImages!.map((photo) async {
        final photoUrl = await getPhotoUrl(photoName: photo.name);
        if (photoUrl == null) return null;
        final downloadUrl = await uploadImageToStorage(restaurante.id, photoUrl);
        restaurante.listImages!.add(downloadUrl);
        return downloadUrl;
      }).toList();

      await Future.wait(futures);
    }

    restaurante.categoria = CategoriaTipo.valueOf(restaurante.primaryType);
    final restaurantJson = restaurante.toJson();
    await restaurantRef.set(restaurantJson);
  }

  Future<void> setRestaurantThumb({required String restaurantId, required String image}) async {
    final restaurantRef = _database.collection('restaurantes').doc(restaurantId);
    final thumbUrl = await uploadImageToStorage(restaurantId, image, folder: 'thumb');
    return await restaurantRef.update({'image': thumbUrl});
  }

  Future<List<Restaurante>?> searchPlaceByText({required String query}) async {
    final token = await FirebaseAppCheck.instance.getToken();
    final response = await _dio.post(
      'https://us-central1-foodfinderapp-b2c0d.cloudfunctions.net/searchPlaces',
      options: Options(
        headers: {
          'X-Firebase-AppCheck': token
        }
      ),
      data: {'query': query},
    );

    if (response.statusCode == 200) {
      final data = response.data['places'] ?? [];
      return data.map((p) => Restaurante.fromJson(p)).toList().cast<Restaurante>();
    }

    // POSSIVELMENTE UM CODIGO DE ADICIONAR VARIOS RESTAURANTES AO BANCO DE DADOS UTILIZANDO PAGINACAO
    // if (response.statusCode == 200) {
    //   final data = response.data;
    //   if(data.isNotEmpty) {
    //     final places = data["places"];
    //     final List<Restaurante>? restaurants = places.map((place) => Restaurante.fromJson(place)).toList().cast<Restaurante>();
    //     return restaurants;
    //   }
    // }

    // for(int i = 0; i < 5; i++) {
    //   final body = {
    //     'textQuery': query,
    //     'includePureServiceAreaBusinesses': true,
    //     'pageToken': nextPageToken
    //   };
    //
    //   final response = await _dio.post(
    //     '/places:searchText',
    //     options: Options(
    //       headers: {
    //         'Content-Type': 'application/json',
    //         'X-Goog-Api-Key': _placesAPIkey,
    //         'X-Goog-FieldMask': fields,
    //       }
    //     ),
    //     data: body
    //   );
    //
    //   if (response.statusCode == 200) {
    //     final data = response.data;
    //     if (data.isNotEmpty) {
    //       nextPageToken = data["nextPageToken"];
    //       if (nextPageToken == null) break;
    //       await Future.delayed(const Duration(seconds: 2));
    //     } else {
    //       return null;
    //     }
    //   } else {
    //     break;
    //   }
    // }

    return [];
  }

  Future<bool> deleteRestaurant({required String restauranteId}) async {
    try{
      final restaurantRef = _database.collection('restaurantes').doc(restauranteId);
      await deleteRestaurantFolder(restauranteId);
      await restaurantRef.delete();

      return true;
    }catch(e) {
      return false;
    }
  }

  Future<void> deleteRestaurantFolder(String restaurantId) async {

    // Deleta todas as imagens da pasta /images
    final imagesRef = _storage.ref("restaurants/$restaurantId/images");
    final imagesResult = await imagesRef.listAll();

    await Future.wait(imagesResult.items.map((file) => file.delete()));

    // Deleta a thumb (mesmo que tenha só 1, a lógica suporta mais)
    final thumbRef = _storage.ref("restaurants/$restaurantId/thumb");
    final thumbResult = await thumbRef.listAll();

    await Future.wait(thumbResult.items.map((file) => file.delete()));
  }

  Future<void> removeImages(String restaurantId, List<String> imageUrls) async {
    for (final url in imageUrls) {
      final ref = _storage.refFromURL(url);

      await ref.delete();
    }
  }
  
  Future<void> updateRestaurantData(String restaurantId, Map<String, dynamic> info) async {
    final restaurantRef = _database.collection('restaurantes').doc(restaurantId);
    return await restaurantRef.update(info);
  }

  Future<void> addReview(String restaurantId, Avaliacao? avaliacao) async {
    await _database.collection('restaurantes').doc(restaurantId).collection('reviews').doc(avaliacao?.id).set(avaliacao?.toJson() ?? {});
    return;
  }

  Future<void> updateReview(String restaurantId, Avaliacao? avaliacao) async {
    final ref = _database.collection('restaurantes').doc(restaurantId).collection('reviews').doc(avaliacao?.id);
    final doc = await ref.get();
    if(!doc.exists) {
      avaliacao?.createdAt = DateTime.now();
      final avaliacaoJson = avaliacao?.toJson() ?? {};
      return await ref.set(avaliacaoJson);
    }
    return await ref.update(avaliacao?.toJson() ?? {});
  }

  Future<void> deleteReview(String restaurantId, String? reviewId) async {
    return await _database.collection('restaurantes').doc(restaurantId).collection('reviews').doc(reviewId).delete();
  }
  
  Future<bool> sendSuggestion({required String name, required String location}) async {
    try {
      await _functions.httpsCallable('sendRestaurantSuggestion').call({
        'name': name,
        'location': location,
        'userId': _authService.currentUser!.uid
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> checkIfRestaurantExists(String? restaurantId) async {
    final snapshot = await _database.collection('restaurantes').doc(restaurantId).get();
    return snapshot.exists;
  }

  void changeApiUrl(String url) => DioClient().updateBaseUrl(url);
}