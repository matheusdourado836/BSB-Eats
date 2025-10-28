import 'package:bsb_eats/shared/util/extensions.dart';
import 'package:bsb_eats/shared/widgets/people_list_modal.dart';
import 'package:bsb_eats/shared/widgets/user_avatar_widget.dart';
import 'package:bsb_eats/shared/widgets/zoom_image_widget.dart';
import 'package:flutter/material.dart';
import '../model/user.dart';

class ProfileStatsRow extends StatelessWidget {
  final MyUser? user;
  const ProfileStatsRow({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final qtdPosts = user?.postsCount ?? 0;
    final qtdFollowers = user?.followersCount ?? 0;
    final qtdFollowing = user?.followingCount ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ZoomImageWidget(
              profilePhotoUrl: user?.profilePhotoUrl,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: UserAvatarWidget(
                  photoUrl: user?.profilePhotoUrl,
                  username: user?.nome,
                  radius: 45,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user?.nome ?? 'sem nome', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(qtdPosts.toString(), style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('posts', style: TextStyle(fontSize: 12))
                        ],
                      ),
                      InkWell(
                        onTap: () {
                          if(qtdFollowers == 0) return;
                          showModalBottomSheet(
                            context: context,
                            useSafeArea: true,
                            isScrollControlled: true,
                            showDragHandle: true,
                            enableDrag: true,
                            builder: (context) => PeopleListModal(
                              userId: user!.id!,
                              field: 'followers'
                            )
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(qtdFollowers.toString().toFriendlyQuantity(), style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('seguidores', style: TextStyle(fontSize: 12))
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          if(qtdFollowing == 0) return;
                          showModalBottomSheet(
                            context: context,
                            useSafeArea: true,
                            isScrollControlled: true,
                            showDragHandle: true,
                            enableDrag: true,
                            builder: (context) => PeopleListModal(
                              userId: user!.id!,
                              field: 'following'
                            )
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(qtdFollowing.toString().toFriendlyQuantity(), style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('seguindo', style: TextStyle(fontSize: 12))
                          ],
                        ),
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
        const SizedBox(height: 12),
        Text(user?.bio ?? '')
      ],
    );
  }
}