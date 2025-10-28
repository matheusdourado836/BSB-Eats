import 'package:flutter/material.dart';

class AppLogoWidget extends StatelessWidget {
  final bool? onWhiteBackground;
  final CrossAxisAlignment? crossAxisAlignment;
  final void Function()? onPressed;
  const AppLogoWidget({super.key, this.onWhiteBackground, this.crossAxisAlignment, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleTextStyle = onWhiteBackground == true ? theme.textTheme.labelLarge?.copyWith(fontSize: 14) : theme.textTheme.titleLarge?.copyWith(fontSize: 18);
    final subtitleTextStyle = onWhiteBackground == true ? theme.textTheme.labelMedium?.copyWith(fontSize: 12) : theme.textTheme.titleSmall?.copyWith(fontSize: 10);
    return InkWell(
      onTap: onPressed,
      child: Row(
        mainAxisAlignment: crossAxisAlignment == CrossAxisAlignment.start
          ? MainAxisAlignment.start
          : MainAxisAlignment.center,
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
              image: const DecorationImage(
                image: AssetImage('assets/images/logo_alt.png'),
                fit: BoxFit.cover
              )
            ),
          ),
          const SizedBox(width: 8.0),
          Column(
            crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.center,
            children: [
              Text(
                'BSB Eats',
                style: titleTextStyle,
              ),
              Text(
                'Brasília na palma da mão',
                style: subtitleTextStyle,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
