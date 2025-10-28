import 'package:bsb_eats/screens/onboarding/base_container.dart';
import 'package:flutter/material.dart';

class Page1 extends StatelessWidget {
  const Page1({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseContainer(
      icon: Icon(Icons.location_on_outlined, color: Colors.white, size: 80),
      title: 'Descrubra Brasília',
      body: 'Encontre os melhores restaurantes da capital federal. Sabores únicos em cada cantinho da cidade.',
    );
  }
}
