import 'package:bsb_eats/shared/model/enums.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyNotification {
  String? id;
  String? ownerId;
  String? title;
  String? body;
  String? image;
  bool? read;
  String? route;
  String? arguments;
  Timestamp? createdAt;
  NotificationType? type;

  MyNotification({
    this.id,
    this.ownerId,
    this.title,
    this.body,
    this.image,
    this.read,
    this.route,
    this.arguments,
    this.createdAt,
    this.type
  });

  factory MyNotification.fromJson(Map<String, dynamic> json) => MyNotification(
    id: json["id"],
    ownerId: json["ownerId"],
    title: json["title"],
    body: json["body"],
    image: json["image"],
    read: json["read"],
    route: json["route"],
    arguments: json["arguments"],
    createdAt: json["createdAt"],
    type: NotificationType.valueOf(json["type"])
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "ownerId": ownerId,
    "title": title,
    "body": body,
    "image": image,
    "read": read,
    "route": route,
    "arguments": arguments,
    "createdAt": createdAt,
    "type": type?.name
  };
}