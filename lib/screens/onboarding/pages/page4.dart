import 'package:flutter/material.dart';

import '../base_container.dart';

class Page4 extends StatelessWidget {
  const Page4({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseContainer(
      icon: Icon(Icons.dinner_dining_outlined, color: Colors.white, size: 88),
      title: 'Pronto para começar?',
      body: 'Sua jornada gastronômica por Brasília está prestes a começar. Vamos descobrir sabores incríveis juntos!',
    );
  }
}