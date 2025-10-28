import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../shared/model/user.dart';
import '../../../shared/widgets/user_avatar_widget.dart';

class ProfilePictureSelected extends StatelessWidget {
  final MyUser? user;
  final MyUser currentUser;
  const ProfilePictureSelected({super.key, required this.user, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        height: 300,
        child: Stack(
          children: [
            SizedBox(
              height: 300,
              width: 300,
              child: InteractiveViewer(
                child: (user?.profilePhotoUrl?.isEmpty ?? true)
                    ? NoBgUser()
                    : CachedNetworkImage(
                    imageUrl: user!.profilePhotoUrl!,
                    fit: BoxFit.cover,
                    errorListener: (o) => Container()
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: Container(
                width: 300,
                height: 50,
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.black38),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                          user?.username ?? 'S/N',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 18)
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        if(user?.id == currentUser.id) {
                          Navigator.pushNamed(context, '/user_profile');
                        }else {
                          Navigator.pushNamed(context, '/profile', arguments: user?.id);
                        }
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                        textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.blue
                        )
                      ),
                      child: const Text('Ver perfil')
                    ),
                    const SizedBox(width: 8)
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}