import 'package:flutter/material.dart';

class AskToLoginDialog extends StatelessWidget {
  const AskToLoginDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Login necessário'),
      content: const Text('Você precisa estar logado para usar este recurso!'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false),
          child: const Text('Ir para login'),
        )
      ]
    );
  }
}
