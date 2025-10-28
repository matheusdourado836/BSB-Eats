import 'package:bsb_eats/shared/model/favorite.dart';
import 'package:bsb_eats/shared/model/notification.dart';
import 'package:bsb_eats/shared/model/post.dart';
import 'package:bsb_eats/shared/model/user_ref.dart';
import 'package:bsb_eats/shared/util/extensions.dart';

class MyUser {
  String? id;
  String? fcmToken;
  String? email;
  String? nome;
  String? nomeLowerCase;
  String? username;
  String? usernameLowerCase;
  String? bio;
  String? profilePhotoUrl;
  List<Favorite>? favorites;
  List<Follower>? followers;
  List<Follower>? following;
  int? followersCount;
  int? followingCount;
  int? postsCount;
  List<Like>? likes;
  List<Post>? likedPosts;
  List<String>? visitedPlaces;
  List<MyNotification>? notifications;
  List<String>? globalNotificationsRead;
  List<String>? globalNotificationsDeleted;
  bool? emailVerified;
  bool? verified;
  bool? admin;
  bool? adminSupremo;
  int? qtdRestaurantsAdded;
  bool? reviewed;
  int? pontos;

  MyUser({
    this.id,
    this.fcmToken,
    this.nome,
    this.nomeLowerCase,
    this.username,
    this.usernameLowerCase,
    this.email,
    this.bio,
    this.profilePhotoUrl,
    this.favorites,
    this.followers,
    this.following,
    this.followersCount,
    this.followingCount,
    this.postsCount,
    this.likes,
    this.likedPosts,
    this.visitedPlaces,
    this.notifications,
    this.globalNotificationsRead,
    this.globalNotificationsDeleted,
    this.emailVerified,
    this.verified,
    this.admin,
    this.adminSupremo,
    this.qtdRestaurantsAdded,
    this.reviewed,
    this.pontos,
  });

  factory MyUser.fromJson(Map<String, dynamic> json) => MyUser(
    id: json["id"],
    fcmToken: json["fcmToken"],
    nome: json["nome"],
    nomeLowerCase: json["nomeLowerCase"],
    username: json["username"],
    usernameLowerCase: json["usernameLowerCase"],
    email: json["email"],
    bio: json["bio"],
    profilePhotoUrl: json["profilePhotoUrl"],
    verified: json["verified"],
    admin: json["admin"],
    adminSupremo: json["adminSupremo"],
    qtdRestaurantsAdded: json["qtdRestaurantsAdded"],
    reviewed: json["reviewed"],
    pontos: json["pontos"],
    globalNotificationsRead: List<String>.from(json["globalNotificationsRead"] ?? []),
    globalNotificationsDeleted: List<String>.from(json["globalNotificationsDeleted"] ?? [])
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "fcmToken": fcmToken,
    "nome": nome,
    "nomeLowerCase": nome?.toLowerCase().removerAcentos().trim(),
    "username": username,
    "usernameLowerCase": username?.toLowerCase().removerAcentos().trim(),
    "email": email,
    "bio": bio,
    "profilePhotoUrl": profilePhotoUrl,
    "verified": verified,
    "admin": admin,
    "adminSupremo": adminSupremo,
    "qtdRestaurantsAdded": qtdRestaurantsAdded,
    "reviewed": reviewed,
    "pontos": pontos,
    "globalNotificationsRead": globalNotificationsRead,
    "globalNotificationsDeleted": globalNotificationsDeleted,
  };

}

class Follower implements UserRef {
  @override
  String? id;
  @override
  String? nome;

  Follower({this.id, this.nome});

  factory Follower.fromJson(Map<String, dynamic> json) => Follower(
    id: json["id"],
    nome: json["nome"],
  );

  @override
  Map<String, dynamic> toJson() => {
    "id": id,
    "nome": nome,
  };

}