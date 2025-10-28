class Comment {
  String? id;
  String? authorId;
  String? authorName;
  String? authorPhoto;
  bool? verifiedUser;
  String? text;
  DateTime? createdAt;

  Comment({
    this.id,
    this.authorId,
    this.authorName,
    this.authorPhoto,
    this.verifiedUser,
    this.text,
    this.createdAt
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