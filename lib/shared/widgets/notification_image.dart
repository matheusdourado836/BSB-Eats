import 'dart:io';
import 'package:flutter/material.dart';

class NotificationImage extends StatelessWidget {
  final String? src;
  final bool? isFile;
  const NotificationImage({super.key, required this.src, this.isFile = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      width: 45,
      decoration: BoxDecoration(
        borderRadius: BorderRadiusDirectional.circular(12),
      ),
      child: (isFile ?? false)
        ? Image.file(
            File(src ?? ''),
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
          )
        : Image.network(
            src ?? '',
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.error);
            }
          ),
    );
  }
}