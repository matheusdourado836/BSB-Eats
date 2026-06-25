import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SocialLoginContainer extends StatelessWidget {
  final String path;
  final String provider;
  final Color backgroundColor;
  final Function() onTap;
  const SocialLoginContainer({super.key, required this.path,required this.onTap, required this.backgroundColor, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: backgroundColor,
              border: Border.all()
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(path, width: 25, height: 25,),
              const SizedBox(width: 12),
              Text('Entrar com $provider', style: TextStyle(color: (backgroundColor == Colors.black) ? Colors.white : Colors.black),)
            ],
          ),
        ),
      ),
    );
  }
}