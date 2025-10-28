import 'package:flutter/material.dart';

import '../base_container.dart';

class Page2 extends StatelessWidget {
  const Page2({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseContainer(
      icon: Icon(Icons.star_border_outlined, color: Colors.yellowAccent, size: 88),
      title: 'Avaliações Reais',
      body: 'Veja avaliações detalhadas de outros usuários sobre preço, ambiente, comida e atendimento.',
    );
  }
}