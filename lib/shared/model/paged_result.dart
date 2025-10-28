import 'package:bsb_eats/shared/model/restaurante.dart';

class PagedResult{
  final List<Restaurante>? places;
  final String? nextPageToken;

  const PagedResult({
    this.places,
    this.nextPageToken
  });

  factory PagedResult.fromJson(Map<String, dynamic> json) {
    final nextPageToken = json['nextPageToken'] as String?;
    return PagedResult(
      places: json['places'],
      nextPageToken: nextPageToken
    );
  }
}