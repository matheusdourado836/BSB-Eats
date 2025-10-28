import 'package:bsb_eats/shared/model/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppFeedback {
  String? id;
  String? authorId;
  MyUser? user;
  String? text;
  DateTime? createdAt;

  AppFeedback({
    this.id,
    this.authorId,
    this.user,
    this.text,
    this.createdAt
  });

  factory AppFeedback.fromJson(Map<String, dynamic> json) => AppFeedback(
    id: json["id"],
    authorId: json["authorId"],
    text: json["text"],
    createdAt: json["createdAt"] == null ? null : (json["createdAt"] as Timestamp).toDate(),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "authorId": authorId,
    "text": text,
    "createdAt": createdAt,
  };
}