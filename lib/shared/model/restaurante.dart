import 'package:bsb_eats/shared/model/avaliacao.dart';
import 'package:bsb_eats/shared/model/enums.dart';
import 'package:bsb_eats/shared/model/review.dart';
import 'package:bsb_eats/shared/model/weekday.dart';
import 'package:bsb_eats/shared/util/extensions.dart';

class Restaurante {
  String? id;
  String? nome;
  String? nomeLowerCase;
  CategoriaTipo? categoria;
  List<CategoriaTipo>? categorias;
  String? primaryType;
  String? regiao;
  String? endereco;
  String? enderecoLowerCase;
  Location? location;
  double? avaliacao;
  bool? abertoAgora;
  String? image;
  List<String>? listImages;
  List<Photo>? googleImages;
  CurrentOpeningHours? currentOpeningHours;
  String? phone;
  String? websiteUri;
  int? userRatingCount;
  List<Review>? reviews;
  List<Avaliacao>? appReviews;

  Restaurante({
    this.id,
    this.nome,
    this.nomeLowerCase,
    this.categorias,
    this.categoria,
    this.primaryType,
    this.regiao,
    this.endereco,
    this.enderecoLowerCase,
    this.location,
    this.avaliacao,
    this.abertoAgora,
    this.image,
    this.listImages,
    this.googleImages,
    this.currentOpeningHours,
    this.phone,
    this.websiteUri,
    this.userRatingCount,
    this.reviews,
    this.appReviews
  });

  factory Restaurante.fromJson(Map<String, dynamic> json) {
    final categorias = json['types'] == null ? null : List<CategoriaTipo>.from(json['types'].map((x) => CategoriaTipo.valueOf(x)));
    final currentOpeningHours = json["currentOpeningHours"] == null ? null : CurrentOpeningHours.fromJson(json["currentOpeningHours"]);
    final weeklyOpeningHours = WeeklyOpeningHours.fromWeekdayDescriptions(currentOpeningHours?.weekdayDescriptions ?? []);
    return Restaurante(
      id: json['id'],
      nome: json['displayName'] is Map ? json['displayName']['text'] : json['displayName'],
      nomeLowerCase: json['lowerCaseName'],
      categorias: categorias,
      categoria: CategoriaTipo.valueOf(json["categoriaIndex"]),
      primaryType: json["primaryType"],
      regiao: json["region"],
      endereco: json["formattedAddress"] == null ? null : json['formattedAddress'],
      enderecoLowerCase: json['addressLowerCase'],
      location: json['location'] == null ? null : Location.fromJson(json['location']),
      avaliacao: json['rating'] == null ? null : (json['rating'] as num).toDouble(),
      currentOpeningHours: json["currentOpeningHours"] == null ? null : CurrentOpeningHours.fromJson(json["currentOpeningHours"]),
      abertoAgora: weeklyOpeningHours.isOpenNow(moment: DateTime.now()),
      //abertoAgora: json['currentOpeningHours']?["openNow"],
      image: json['image'],
      googleImages: json['photos'] == null ? null : List<Photo>.from(json['photos'].map((x) => Photo.fromJson(x))),
      listImages: json['listImages'] == null ? null : List<String>.from(json['listImages']),
      phone: json["phone"] ?? json["internationalPhoneNumber"],
      websiteUri: json["websiteUri"],
      userRatingCount: json["userRatingCount"],
      reviews: json["reviews"] != null && json["reviews"] is List
          ? List<Review>.from(json["reviews"].map((review) => Review.fromJson(review)))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'displayName': nome,
    'lowerCaseName': nome?.trim().toLowerCase().removerAcentos(),
    'categoriaIndex': categoria?.code,
    'types': categorias?.map((categoria) => categoria.name.toLowerCase()).toList(),
    'region': regiao,
    'formattedAddress': endereco,
    'addressLowerCase': endereco?.trim().toLowerCase().removerAcentos(),
    'location': location?.toJson(),
    'rating': avaliacao,
    'currentOpeningHours': currentOpeningHours?.toJson(),
    'image': image,
    'listImages': listImages,
    'phone': phone,
    'websiteUri': websiteUri,
    'userRatingCount': userRatingCount,
    'reviews': reviews?.map((review) => review.toJson()).toList(),
  };
}

class Photo {
  String? name;
  int? width;
  int? height;
  List<AuthorAttribution>? authorAttributions;

  Photo({
    this.name,
    this.width,
    this.height,
    this.authorAttributions
  });

  factory Photo.fromJson(Map<String, dynamic> json) => Photo(
    name: json["name"],
    width: json["widthPx"],
    height: json["heightPx"],
    authorAttributions: json["authorAttributions"] == null
        ? null
        : List<AuthorAttribution>.from(json["authorAttributions"].map((x) => AuthorAttribution.fromJson(x)))

  );
}

class Location {
  double? lat;
  double? long;

  Location({
    this.lat,
    this.long
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      lat: json['latitude'],
      long: json['longitude']
    );
  }

  Map<String, dynamic> toJson() => {
    'latitude': lat,
    'longitude': long
  };
}

class RestaurantType {
  String? id;
  String? name;

  RestaurantType({
    this.id,
    this.name
  });

  factory RestaurantType.fromJson(Map<String, dynamic> json) {
    return RestaurantType(
      id: json['fsq_category_id'],
      name: CategoriaTipo.valueOf(json["short_name"])?.description
    );
  }
}

class GoogleRestaurant {
  String? id;
  List<String>? types;
  String? formattedAddress;
  Location? location;
  double? rating;
  DisplayName? displayName;
  String? phone;
  String? websiteUri;
  int? userRatingCount;
  CurrentOpeningHours? currentOpeningHours;
  List<GooglePhoto>? photos;

  GoogleRestaurant({
    this.id,
    this.types,
    this.formattedAddress,
    this.location,
    this.rating,
    this.displayName,
    this.phone,
    this.websiteUri,
    this.userRatingCount,
    this.currentOpeningHours,
    this.photos,
  });

  factory GoogleRestaurant.fromJson(Map<String, dynamic> json) => GoogleRestaurant(
    id: json["id"],
    types: json["types"] == null ? [] : List<String>.from(json["types"]!.map((x) => x)),
    formattedAddress: json["formattedAddress"],
    location: json["location"] == null ? null : Location.fromJson(json["location"]),
    rating: json["rating"] == null ? null : (json["rating"] as num).toDouble(),
    displayName: json["displayName"] == null ? null : DisplayName.fromJson(json["displayName"]),
    phone: json["internationalPhoneNumber"],
    websiteUri: json["websiteUri"],
    userRatingCount: json["userRatingCount"],
    currentOpeningHours: json["currentOpeningHours"] == null ? null : CurrentOpeningHours.fromJson(json["currentOpeningHours"]),
    photos: json["photos"] == null ? [] : List<GooglePhoto>.from(json["photos"]!.map((x) => GooglePhoto.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "types": types == null ? [] : List<dynamic>.from(types!.map((x) => x)),
    "formattedAddress": formattedAddress,
    "location": location?.toJson(),
    "rating": rating,
    "displayName": displayName?.text,
    "lowerCaseName": displayName?.text?.trim().toLowerCase().removerAcentos(),
    "phone": phone,
    "websiteUri": websiteUri,
    "userRatingCount": userRatingCount,
    "currentOpeningHours": currentOpeningHours?.toJson(),
    "photos": photos == null ? [] : List<dynamic>.from(photos!.map((x) => x.toJson())),
  };
}

class CurrentOpeningHours {
  bool? openNow;
  List<Period>? periods;
  List<String>? weekdayDescriptions;
  DateTime? nextCloseTime;

  CurrentOpeningHours({
    this.openNow,
    this.periods,
    this.weekdayDescriptions,
    this.nextCloseTime,
  });

  factory CurrentOpeningHours.init() => CurrentOpeningHours(
    weekdayDescriptions: [
      "monday: 08:00–18:00",
      "tuesday: 08:00–18:00",
      "wednesday: 08:00–18:00",
      "thursday: 08:00–18:00",
      "friday: 08:00–18:00",
      "saturday: 08:00–18:00",
      "sunday: 08:00–18:00",
    ]
  );

  factory CurrentOpeningHours.fromJson(Map<String, dynamic> json) => CurrentOpeningHours(
    openNow: json["openNow"],
    periods: json["periods"] == null ? [] : List<Period>.from(json["periods"]!.map((x) => Period.fromJson(x))),
    weekdayDescriptions: json["weekdayDescriptions"] == null ? [] : List<String>.from(json["weekdayDescriptions"]!.map((x) => x)),
    nextCloseTime: json["nextCloseTime"] == null ? null : DateTime.parse(json["nextCloseTime"]),
  );

  Map<String, dynamic> toJson() => {
    "openNow": openNow,
    "periods": periods == null ? [] : List<dynamic>.from(periods!.map((x) => x.toJson())),
    "weekdayDescriptions": weekdayDescriptions == null ? [] : List<dynamic>.from(weekdayDescriptions!.map((x) => x)),
    "nextCloseTime": nextCloseTime?.toIso8601String(),
  };
}

class Period {
  Close? open;
  Close? close;

  Period({
    this.open,
    this.close,
  });

  factory Period.fromJson(Map<String, dynamic> json) => Period(
    open: json["open"] == null ? null : Close.fromJson(json["open"]),
    close: json["close"] == null ? null : Close.fromJson(json["close"]),
  );

  Map<String, dynamic> toJson() => {
    "open": open?.toJson(),
    "close": close?.toJson(),
  };
}

class Close {
  int? day;
  int? hour;
  int? minute;
  Date? date;

  Close({
    this.day,
    this.hour,
    this.minute,
    this.date,
  });

  factory Close.fromJson(Map<String, dynamic> json) => Close(
    day: json["day"],
    hour: json["hour"],
    minute: json["minute"],
    date: json["date"] == null ? null : Date.fromJson(json["date"]),
  );

  Map<String, dynamic> toJson() => {
    "day": day,
    "hour": hour,
    "minute": minute,
    "date": date?.toJson(),
  };
}

class Date {
  int? year;
  int? month;
  int? day;

  Date({
    this.year,
    this.month,
    this.day,
  });

  factory Date.fromJson(Map<String, dynamic> json) => Date(
    year: json["year"],
    month: json["month"],
    day: json["day"],
  );

  Map<String, dynamic> toJson() => {
    "year": year,
    "month": month,
    "day": day,
  };
}

class DisplayName {
  String? text;
  String? languageCode;

  DisplayName({
    this.text,
    this.languageCode,
  });

  factory DisplayName.fromJson(Map<String, dynamic> json) => DisplayName(
    text: json["text"],
    languageCode: json["languageCode"],
  );

  Map<String, dynamic> toJson() => {
    "text": text,
    "languageCode": languageCode,
  };
}

class GooglePhoto {
  String? name;
  int? widthPx;
  int? heightPx;
  List<AuthorAttribution>? authorAttributions;
  String? flagContentUri;
  String? googleMapsUri;

  GooglePhoto({
    this.name,
    this.widthPx,
    this.heightPx,
    this.authorAttributions,
    this.flagContentUri,
    this.googleMapsUri,
  });

  factory GooglePhoto.fromJson(Map<String, dynamic> json) => GooglePhoto(
    name: json["name"],
    widthPx: json["widthPx"],
    heightPx: json["heightPx"],
    authorAttributions: json["authorAttributions"] == null ? [] : List<AuthorAttribution>.from(json["authorAttributions"]!.map((x) => AuthorAttribution.fromJson(x))),
    flagContentUri: json["flagContentUri"],
    googleMapsUri: json["googleMapsUri"],
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "widthPx": widthPx,
    "heightPx": heightPx,
    "authorAttributions": authorAttributions == null ? [] : List<dynamic>.from(authorAttributions!.map((x) => x.toJson())),
    "flagContentUri": flagContentUri,
    "googleMapsUri": googleMapsUri,
  };
}

class AuthorAttribution {
  String? displayName;
  String? uri;
  String? photoUri;

  AuthorAttribution({
    this.displayName,
    this.uri,
    this.photoUri,
  });

  factory AuthorAttribution.fromJson(Map<String, dynamic> json) => AuthorAttribution(
    displayName: json["displayName"],
    uri: json["uri"],
    photoUri: json["photoUri"],
  );

  Map<String, dynamic> toJson() => {
    "displayName": displayName,
    "uri": uri,
    "photoUri": photoUri,
  };
}

class VisitedRestaurant {
  Restaurante? restaurante;
  DateTime? visitedAt;

  VisitedRestaurant({this.restaurante, this.visitedAt});
}