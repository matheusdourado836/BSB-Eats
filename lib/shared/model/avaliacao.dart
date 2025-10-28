import 'package:bsb_eats/shared/model/user.dart';

class Avaliacao {
  String? id;
  String? userId;
  MyUser? user;
  String? username;
  String? text;
  int? food;
  int? price;
  int? atmosphere;
  int? service;
  DateTime? createdAt;

  Avaliacao({
    this.id,
    this.userId,
    this.user,
    this.username,
    this.text,
    this.food,
    this.price,
    this.atmosphere,
    this.service,
    this.createdAt
  });

  factory Avaliacao.fromJson(Map<String, dynamic> json) => Avaliacao(
    id: json["id"],
    userId: json["userId"],
    username: json["username"],
    text: json["text"],
    food: json["food"],
    price: json["price"],
    atmosphere: json["atmosphere"],
    service: json["service"],
    createdAt: DateTime.tryParse(json["createdAt"] ?? '')
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "userId": userId,
    "username": username,
    "text": text,
    "food": food,
    "price": price,
    "atmosphere": atmosphere,
    "service": service,
    "createdAt": createdAt?.toIso8601String()
  };
}