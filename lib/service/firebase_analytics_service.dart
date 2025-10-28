import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  AnalyticsService._privateConstructor();
  static final AnalyticsService instance = AnalyticsService._privateConstructor();

  Future<void> logEvent({required String name, Map<String, Object>? parameters}) async {
    return await _analytics.logEvent(
      name: name,
      parameters: parameters
    );
  }

  Future<void> setUserProperty({required String name, String? value}) async {
    return await _analytics.setUserProperty(
      name: name,
      value: value
    );
  }
}