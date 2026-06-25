import 'package:bsb_eats/controller/user_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LocalNotificationWidget extends StatelessWidget {
  final int id;
  final String title;
  final String? subtitle;
  final String? image;
  final String? route;
  final Map<String, dynamic>? arguments;
  const LocalNotificationWidget({super.key, required this.id, required this.title, this.subtitle, this.image, this.route, this.arguments});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        if(route?.isNotEmpty ?? false) {
          final userController = Provider.of<UserController>(context, listen: false);
          userController.cancelNotification(id);
          if(route!.contains('/splash')) {
            final userId = route!.split('/')[2];
            Navigator.pushNamed(context, '/profile', arguments: userId);
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
