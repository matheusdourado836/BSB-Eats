class Categoria {
  int? id;
  String? label;
  String? icon;

  Categoria({
    this.id,
    this.label,
    this.icon,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'],
      label: json['label'],
      icon: json['icon'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'icon': icon,
    };
  }
}