import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class GoogleDioClient {
  static final GoogleDioClient _instance = GoogleDioClient._internal();
  final Dio _dio;
  factory GoogleDioClient() => _instance;

  final _logInterceptor = PrettyDioLogger(
      requestBody: true,
      requestHeader: true,
      responseHeader: true,
      responseBody: true,
      error: true
  );

  GoogleDioClient._internal()
      : _dio = Dio(BaseOptions(
    baseUrl: 'https://places.googleapis.com/v1',
    followRedirects: true,
    receiveDataWhenStatusError: true,
    listFormat: ListFormat.multi,
    connectTimeout: const Duration(seconds: 3600),
    receiveTimeout: const Duration(seconds: 7200),
    sendTimeout: const Duration(seconds: 3600),
  )) {
    _dio.interceptors.add(_logInterceptor);
  }

  static Dio getDio() {
    return _instance._dio;
  }
}

class DioClient {
  static final DioClient _instance = DioClient._internal();
  final Dio _dio;
  factory DioClient() => _instance;

  final _logInterceptor = PrettyDioLogger(
      requestBody: true,
      requestHeader: true,
      responseHeader: true,
      responseBody: true,
      error: true
  );

  DioClient._internal()
      : _dio = Dio(BaseOptions(
    baseUrl: 'https://foodish-api.com/',
    followRedirects: true,
    receiveDataWhenStatusError: true,
    listFormat: ListFormat.multi,
    connectTimeout: const Duration(seconds: 3600),
    receiveTimeout: const Duration(seconds: 7200),
    sendTimeout: const Duration(seconds: 3600),
  )) {
    _dio.interceptors.add(_logInterceptor);
  }

  void updateAuthorizationToken(String token) {
    _dio.options.headers["Authorization"] = token;
  }

  void updateBaseUrl(String url) {
    _dio.options.baseUrl = url;
  }

  static Dio getDio() {
    return _instance._dio;
  }
}