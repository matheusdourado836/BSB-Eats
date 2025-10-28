import 'package:bsb_eats/shared/model/avaliacao.dart';
import 'package:bsb_eats/shared/model/restaurante.dart';
import 'package:bsb_eats/shared/model/user.dart';
import 'package:bsb_eats/shared/model/user_ref.dart';

import 'comment.dart';

class Post {
  String? id;
  String? authorID;
  MyUser? author;
  List<String>? photosUrls;
  String? caption;
  Avaliacao? avaliacao;
  int? qtdCurtidas;
  int? qtdComentarios;
  int? qtdViews;
  List<Like>? likes;
  List<Comment>? comentarios;
  List<String>? tags;
  List<String>? taggedPeople;
  List<MyUser>? users;
  List<String>? taggedRestaurant;
  Restaurante? restaurant;
  DateTime? createdAt;
  int? isPinned;

  Post({
    this.id,
    this.authorID,
    this.author,
    this.caption,
    this.avaliacao,
    this.photosUrls,
    this.qtdCurtidas,
    this.qtdComentarios,
    this.qtdViews,
    this.likes,
    this.comentarios,
    this.tags,
    this.taggedPeople,
    this.users,
    this.taggedRestaurant,
    this.restaurant,
    this.createdAt,
    this.isPinned
  });

  factory Post.fromJson(Map<String, dynamic> json) => Post(
    id: json['id'],
    authorID: json['authorID'],
    caption: json['caption'],
    avaliacao: json['avaliacao'] == null ? null : Avaliacao.fromJson(json['avaliacao']),
    photosUrls: json['photosUrls'] == null ? null : List<String>.from(json['photosUrls'].map((x) => x)),
    qtdCurtidas: json['qtdCurtidas'],
    qtdComentarios: json['qtdComentarios'],
    qtdViews: json['qtdViews'],
    createdAt: json["createdAt"] == null ? null : DateTime.parse(json['createdAt']),
    taggedPeople: json['taggedPeople'] == null ? null : List<String>.from(json['taggedPeople'].map((x) => x)),
    taggedRestaurant: json['taggedRestaurant'] == null ? null : List<String>.from(json['taggedRestaurant'].map((x) => x)),
    tags: json["tags"] == null ? null : List<String>.from(json["tags"].map((x) => x)),
    isPinned: json["isPinned"],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'authorID': authorID,
    'caption': caption,
    'avaliacao': avaliacao?.toJson(),
    'photosUrls': photosUrls == null ? null : List<dynamic>.from(photosUrls!.map((x) => x)),
    'qtdCurtidas': qtdCurtidas,
    'qtdComentarios': qtdComentarios,
    'qtdViews': qtdViews,
    'createdAt': createdAt?.toIso8601String(),
    'tags': tags,
    'taggedPeople': taggedPeople,
    'taggedRestaurant': taggedRestaurant,
    'isPinned': isPinned ?? 0,
  };
}

class Like implements UserRef {
  @override
  String? id;

  @override
  String? nome;

  Like({this.id, this.nome});

  factory Like.fromJson(Map<String, dynamic> json) => Like(
    id: json['id'],
    nome: json['nome'],
  );

  @override
  Map<String, dynamic> toJson() => {
    'id' : id,
    'nome' : nome,
  };
}