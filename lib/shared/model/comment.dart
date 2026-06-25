import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  String? id;
  String? authorId;
  String? authorName;
  String? authorPhoto;
  bool? verifiedUser;
  String? text;
  List<Comment>? answers;
  int? qtdAnswers;
  QueryDocumentSnapshot<Object?>? lastAnswerDoc;
  DateTime? createdAt;
  bool? loadingAnswers;

  Comment({
    this.id,
    this.authorId,
    this.authorName,
    this.authorPhoto,
    this.verifiedUser,
    this.text,
    this.answers,
    this.qtdAnswers,
    this.lastAnswerDoc,
    this.createdAt,
    this.loadingAnswers
  });

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
    id: json['id'],
    authorId: json['authorId'],
    text: json['text'],
    createdAt: DateTime.tryParse(json['createdAt']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'authorId': authorId,
    'text': text,
    'createdAt': createdAt?.toIso8601String(),
  };
}