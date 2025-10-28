import 'package:bsb_eats/shared/util/extensions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class UserAvatarWidget extends StatelessWidget {
  final String? photoUrl;
  final String? username;
  final double? radius;
  const UserAvatarWidget({super.key, required this.photoUrl, this.username, this.radius});

  @override
  Widget build(BuildContext context) {
    if(photoUrl?.isEmpty ?? true) {
      return NoBgUser(
        username: username,
        radius: radius,
      );
    }

    return CircleAvatar(
      radius: radius ?? 70,
      backgroundImage: CachedNetworkImageProvider(
        photoUrl!,
        errorListener: (error) => const NoBgUser(),
      ),
    );
  }
}

class NoBgUser extends StatelessWidget {
  final String? username;
  final double? radius;
  const NoBgUser({super.key, this.username, this.radius});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius ?? 70,
      backgroundColor: Theme.of(context).primaryColor,
      child: Text(
        username?.initials() ?? 'SN',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
