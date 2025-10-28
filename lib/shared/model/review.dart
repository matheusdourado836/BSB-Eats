class Review {
  String? name;
  DateTime? publishTime;
  String? relativePublishTimeDescription;
  int? rating;
  CommentText? text;
  AuthorAttribution? authorAttribution;

  Review({
    this.name,
    this.publishTime,
    this.relativePublishTimeDescription,
    this.rating,
    this.text,
    this.authorAttribution
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
    name: json["name"],
    publishTime: DateTime.tryParse(json["publishTime"] ?? ''),
    relativePublishTimeDescription: json["relativePublishTimeDescription"],
    rating: json["rating"],
    text: json["text"] == null ? null : CommentText.fromJson(json["text"]),
    authorAttribution: json["authorAttribution"] == null ? null : AuthorAttribution.fromJson(json["authorAttribution"])
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "publishTime": publishTime?.toIso8601String(),
    "relativePublishTimeDescription": relativePublishTimeDescription,
    "rating": rating,
    "text": text?.toJson(),
    "authorAttribution": authorAttribution?.toJson()
  };
}

class AuthorAttribution {
  String? displayName;
  String? photoUri;

  AuthorAttribution({
    this.displayName,
    this.photoUri,
  });

  factory AuthorAttribution.fromJson(Map<String, dynamic> json) => AuthorAttribution(
    displayName: json["displayName"],
    photoUri: json["photoUri"]
  );

  Map<String, dynamic> toJson() => {
    "displayName": displayName,
    "photoUri": photoUri
  };
}

class CommentText {
  String? text;
  String? languageCode;

  CommentText({
    this.text,
    this.languageCode
  });

  factory CommentText.fromJson(Map<String, dynamic> json) => CommentText(
    text: json["text"],
    languageCode: json["languageCode"]
  );

  Map<String, dynamic> toJson() => {
    "text": text,
    "languageCode": languageCode
  };
}