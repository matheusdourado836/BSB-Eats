enum CategoriaTipo {
  todos(0, '🍽️ Todos', 'all'),
  brasileira(1, '🇧🇷 Brasileira', 'brazilian_food'),
  pizza(2, '🍕 Pizza', 'pizza_restaurant'),
  japonesa(3, '🍣 Japonesa', 'japanese_restaurant'),
  chinesa(4, '🥡 Chinesa', 'chinese_restaurant'),
  italiana(5, '🍝 Italiana', 'italian_restaurant'),
  mexicana(6, '🌮 Mexicana', 'mexican_restaurant'),
  hamburguer(7, '🍔 Hambúrguer', 'hamburger_restaurant'),
  churrasco(8, '🍖 Churrasco', 'steak_house'),
  vegano(9, '🥗 Vegano', 'vegan_restaurant'),
  cafeteria(10, '☕ Cafeteria', 'coffee_shop'),
  libanesa(11, '🥙 Libanesa', 'lebanese_restaurant'),
  bar(12, '🍻 Bar', 'bar'),
  frutosDoMar(13, '🦞 Frutos do Mar', 'seafood_restaurant'),
  acai(14, '🥤 Açaí', 'acai_shop'),
  pastelaria(15, '🥟 Pastelaria', 'Pastelaria'),
  doces(16, '🍰 Doces', 'Desserts'),
  fastFood(17, '🍟 Fast Food', 'Fast Food'),
  sandwichShop(18, '🥪 Sanduíche', 'sandwich_shop'),
  hotDog(19, '🌭 Cachorro Quente', 'hot_dog'),
  restaurante(20, '🍽️ Restaurante', 'Restaurant');

  final int code;
  final String description;
  final String name;
  const CategoriaTipo(this.code, this.description, this.name);

  static CategoriaTipo? valueOf(dynamic v) {
    if (v == null) {
      return CategoriaTipo.restaurante;
    }
    if (v is String) {
      return CategoriaTipo.values.firstWhere(
            (element) => element.name == v,
        orElse: () => CategoriaTipo.restaurante,
      );
    }
    if (v is int && v > 0) {
      return CategoriaTipo.values.firstWhere((element) => element.code == v);
    }

    return CategoriaTipo.restaurante;
  }
}

enum NotificationType {
  GLOBAL('global'),
  USER('');
  final String? name;
  const NotificationType(this.name);

  static NotificationType valueOf(dynamic v) {
    if (v == null) {
      return NotificationType.USER;
    }
    if (v is String) {
      return NotificationType.values.firstWhere(
            (element) => element.name == v,
        orElse: () => NotificationType.USER,
      );
    }

    return NotificationType.USER;
  }
}