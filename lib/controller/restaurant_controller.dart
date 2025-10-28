import 'package:bsb_eats/service/restaurant_service.dart';
import 'package:bsb_eats/service/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:maps_launcher/maps_launcher.dart';
import '../shared/model/restaurante.dart';

class RestaurantController extends ChangeNotifier {
  static final RestaurantService _service = RestaurantService();
  static final UserService _userService = UserService();
  List<Restaurante> _restaurantes = [];
  List<Restaurante> get restaurantes => _restaurantes;
  List<Restaurante> _filteredRestaurantes = [];
  List<Restaurante> get filteredRestaurantes => _filteredRestaurantes;
  Restaurante? restaurante;
  DocumentSnapshot? lastDoc;
  bool loading = false;

  Future<List<Restaurante>> fetchRestaurants({
    int pageSize = 20,
    DocumentSnapshot? startAfter,
    int? categoryIndex,
    String? region,
    String? searchQuery,
  }) async {
    final docs = await _service.getRestaurants(
      pageSize: pageSize,
      startAfter: startAfter,
      categoryIndex: categoryIndex,
      region: region,
      searchQuery: searchQuery
    );
    final restaurants = docs.map((doc) => Restaurante.fromJson(doc.data()! as Map<String, dynamic>)).toList();
    _restaurantes = restaurants;
    _filteredRestaurantes = _restaurantes;
    lastDoc = docs.lastOrNull;
    return _restaurantes;
  }

  Future<Restaurante?> getRestaurantById({required String id}) async => _service.getRestaurantById(id: id);

  Future<int> getRestaurantCount({
    int? categoryIndex,
    String? region,
    String? searchQuery,
  }) async => _service.getRestaurantCount(
    categoryIndex: categoryIndex,
    region: region,
    searchQuery: searchQuery
  );

  Future<List<Restaurante>?> searchPlaceByText({required String query}) async {
    final results = await _service.searchPlaceByText(query: query);
    return results;
  }

  Future<void> createRestaurant(Restaurante restaurante, String thumbnail, {List<String> images = const []}) async => _service.createRestaurant(restaurante, thumbnail, images: images);

  Future<void> addRestaurant(Restaurante restaurante) async => _service.addRestaurant(restaurante);

  Future<void> setRestaurantThumb({required String restaurantId, required String image}) async => _service.setRestaurantThumb(restaurantId: restaurantId, image: image);

  Future<bool> deleteRestaurant({required String restauranteId}) async => _service.deleteRestaurant(restauranteId: restauranteId);

  Future<void> removeImages(String restaurantId, List<String> imageUrls) async => _service.removeImages(restaurantId, imageUrls);

  Future<void> fetchPlaceDetails(String? placeId) async {
    loading = true;
    notifyListeners();
    //restaurante = await _service.fetchPlaceDetails(placeId);
    restaurante = await _service.getRestaurantById(id: placeId ?? '');
    restaurante?.appReviews ??= [];
    restaurante?.reviews ??= [];
    restaurante?.appReviews!.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
    restaurante?.reviews!.sort((a, b) => b.publishTime!.compareTo(a.publishTime!));
    loading = false;
    notifyListeners();
    return;
  }

  //Future<String?> getPhotoUrl({required Photo? photo}) async => _service.getPhotoUrl(photo: photo);

  Future<void> openMaps({required double? lat, required double? long, required String? restaurantId}) async {
    if(lat == null || long == null) return;
    final res = await MapsLauncher.launchCoordinates(lat, long);
    if(res) {
      await _userService.setVisitedRestaurant(restaurantId: restaurantId);
      notifyListeners();
    }
  }

  Future<bool> sendSuggestion({required String name, required String location}) async => _service.sendSuggestion(name: name, location: location);

  Future<void> updateRestaurantData(String restaurantId, Map<String, dynamic> info) async => _service.updateRestaurantData(restaurantId, info);

  Future<bool> checkIfRestaurantExists(String? restaurantId) async => _service.checkIfRestaurantExists(restaurantId);

  void changeApiUrl(String url) => _service.changeApiUrl(url);
}