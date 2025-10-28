abstract class UserRef {
  String? get id;
  String? get nome;

  Map<String, dynamic> toJson();
}