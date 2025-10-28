import 'package:flutter/material.dart';
import '../base_container.dart';

class Page3 extends StatelessWidget {
  const Page3({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseContainer(
      icon: Icon(Icons.people_alt_outlined, color: Colors.white, size: 88),
      title: 'Comunidade Local',
      body: 'Conecte-se com outros amantes da gastronomia e compartilhe suas experiências culinárias.',
    );
  }
}