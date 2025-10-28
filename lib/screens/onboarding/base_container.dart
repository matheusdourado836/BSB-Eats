import 'package:flutter/material.dart';

class BaseContainer extends StatelessWidget {
  final Widget icon;
  final String title;
  final String body;
  const BaseContainer({super.key, required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green.shade400,
          ),
          child: icon,
        ),
        const SizedBox(height: 32),
        Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 32)),
        const SizedBox(height: 16),
        Text(
          body,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w500),
        )
      ],
    );
  }
}
