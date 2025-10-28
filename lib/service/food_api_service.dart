import 'package:dio/dio.dart';
import 'dio_client.dart';

class FoodApiService {
  static final Dio _dio = DioClient.getDio();
  
  Future<String?> getFoodImage() async {
    try{
      final response = await _dio.get('/api/');

      if(response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        return response.data['image'];
      } else {
        return null;
      }

    }catch(e) {
      return null;
    }
  }
}