import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controller/user_controller.dart';

class LocalNotificationWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? image;
  final String? route;
  final String? arguments;
  const LocalNotificationWidget({super.key, required this.title, this.subtitle, this.image, this.route, this.arguments});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () async {
        if(route?.isNotEmpty ?? false) {
          final userController = Provider.of<UserController>(context, listen: false);
          if(route!.contains('/splash')) {
            final userId = route!.split('/')[2];
            final user = await userController.getUserById(userId);
            Navigator.pushNamed(context, '/profile', arguments: user?.id);
            return;
          }
          if(route!.contains('/post')) {
            final postId = route!.split('/')[2];
            Navigator.pushNamed(context, '/post_details', arguments: postId);
            return;
          }
          Navigator.pushNamed(context, route!, arguments: arguments);
        }
      },
      tileColor: const Color(0xff2E322C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.circular(12)
      ),
      leading: (image?.isEmpty ?? true) ? null : Image.network(image!, width: 50, height: 50),
      title: Text(title),
      subtitle: Text(subtitle ?? ''),
    );
  }
}
