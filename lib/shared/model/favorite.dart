class Favorite {
  String? placeId;
  String? name;
  String? photoUrl;
  int? categoriaIndex;
  double? rating;
  int? visitsCount;

  Favorite({
    this.placeId,
    this.name,
    this.photoUrl,
    this.categoriaIndex,
    this.rating,
    this.visitsCount
  });

  factory Favorite.fromJson(Map<String, dynamic> json) => Favorite(
    placeId: json["placeId"],
    name: json["name"],
    photoUrl: json["photoUrl"],
    categoriaIndex: json["categoriaIndex"],
    rating: json["rating"] == null ? null : (json["rating"] as num).toDouble(),
    visitsCount: json["visitsCount"],
  );

  Map<String, dynamic> toJson() => {
    "placeId": placeId,
    "name": name,
    "photoUrl": photoUrl,
    "categoriaIndex": categoriaIndex,
    "rating": rating,
    "visitsCount": visitsCount,
  };
}