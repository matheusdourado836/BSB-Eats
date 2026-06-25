import 'package:bsb_eats/controller/user_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';

class RewardScreen extends StatelessWidget {
  final String? notificationId;
  final int qtdPoints;
  const RewardScreen({super.key, this.notificationId, required this.qtdPoints});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: null,
      backgroundColor: const Color(0xff183A13),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Coin3DSpin(),
            Text('Parabéns!', style: theme.textTheme.headlineLarge?.copyWith(color: theme.colorScheme.secondary),),
            const SizedBox(height: 16),
            Text(
              'Você recebeu um prêmio de $qtdPoints moedas',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.secondary)
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8),
        child: ElevatedButton(
          onPressed: () async {
            final userController = Provider.of<UserController>(context, listen: false);
            bool? notificationExists = await userController.getNotification(notificationId);
            if(notificationExists != true) {
              showDialog(context: context, builder: (context) => const InvalidRewardDialog());
              await userController.deleteNotification(notificationId!);
              return;
            }
            final userPoints = userController.currentUser?.pontos ?? 0;
            await userController.updateUserData({"pontos": userPoints + qtdPoints});
            if(notificationId?.isNotEmpty ?? false) {
              await userController.deleteNotification(notificationId!);
            }
            Navigator.pushNamedAndRemoveUntil(context, '/splash', (route) => false);
          },
          style: ElevatedButton.styleFrom(
            fixedSize: const Size(300, 50),
            backgroundColor: theme.colorScheme.secondary
          ),
          child: const Text('Aperte aqui para receber')
        ),
      ),
    );
  }
}

class Coin3DSpin extends StatefulWidget {
  const Coin3DSpin({super.key});

  @override
  State<Coin3DSpin> createState() => _Coin3DSpinState();
}

class _Coin3DSpinState extends State<Coin3DSpin> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  void _spin() => _controller.forward(from: 0);

  @override
  void initState() {
    super.initState();

    // Controla o giro
    _controller = AnimationController(
      vsync: this,
      duration: 2000.ms,
    );

    // Gira 3x (3 * 2π radianos)
    _animation = Tween<double>(begin: 0, end: 2 * math.pi * 3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _spin(),
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final value = _animation.value;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(value);

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: Image.asset(
              'assets/images/coin.png',
              width: 200,
              height: 200,
            ),
          );
        },
      ).animate()
       .fadeIn(duration: 300.ms)
       .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: 400.ms),
    );
  }
}

class InvalidRewardDialog extends StatelessWidget {
  const InvalidRewardDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Erro ao resgatar recompensa'),
      content: const Text('Você já resgatou essa recompensa anteriormente'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/splash', (route) => false),
          child: const Text('OK')
        )
      ]
    );
  }
}
