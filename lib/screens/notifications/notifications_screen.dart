import 'package:bsb_eats/controller/user_controller.dart';
import 'package:bsb_eats/shared/util/extensions.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../shared/widgets/notification_image.dart';

class NotificationsScreen extends StatelessWidget {
  final EventBus? eventBus;
  const NotificationsScreen({super.key, this.eventBus});

  @override
  Widget build(BuildContext context) {
    final userController = Provider.of<UserController>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) => userController.getNotifications().whenComplete(() => eventBus?.fire('refresh_notifications')));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        centerTitle: true,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            onPressed: () => userController.deleteAllNotifications().whenComplete(() => eventBus?.fire('refresh_notifications')),
            icon: const Icon(Icons.delete_forever)
          )
        ],
      ),
      body: RefreshIndicator.adaptive(
        onRefresh: () => userController.getNotifications().whenComplete(() => eventBus?.fire('refresh_notifications')),
        child: Consumer<UserController>(
          builder: (context, value, _) {
            if(value.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (value.currentUser!.notifications?.isEmpty ?? true) {
              return Column(
                children: [
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      height: 250,
                      width: 250,
                      alignment: Alignment.topCenter,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.tertiary.withAlpha(100)
                      ),
                      child: Stack(
                        children: [
                          Icon(
                            Icons.notifications,
                            size: 230,
                            color: Theme.of(context).primaryColor,
                          ),
                          Positioned(
                            right: 45,
                            top: 30,
                            child: Container(
                              height: 50,
                              width: 50,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).colorScheme.tertiary
                              ),
                              child: Text('0', style: TextStyle(fontSize: 24, color: Colors.white),),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 38,),
                  Text(
                    'Sem notificações ainda',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 26)
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Você não tem notificações agora.\nVolte mais tarde',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 64),
                  ElevatedButton(
                    onPressed: () => userController.getNotifications().whenComplete(() => eventBus?.fire('refresh_notifications')),
                    style: ElevatedButton.styleFrom(
                      fixedSize: const Size(300, 50),
                    ),
                    child: const Text('Atualizar'),
                  )
                ]
              );
            }

            return ListView.builder(
              itemCount: value.currentUser!.notifications?.length ?? 0,
              itemBuilder: (context, index) {
                final notification = value.currentUser!.notifications![index];
                return ListTile(
                  minVerticalPadding: 16,
                  onTap: () async {
                    notification.read = true;
                    if(notification.route?.isNotEmpty ?? false) {
                      if(notification.route!.contains('/splash')) {
                        final userId = notification.route!.split('/')[2];
                        final user = await userController.getUserById(userId);
                        Navigator.pushNamed(context, '/profile', arguments: user?.id);
                        userController.setNotificationRead(notificationId: notification.id!, type: notification.type).whenComplete(() => eventBus?.fire('refresh_notifications'));
                        return;
                      }
                      if(notification.route!.contains('/post')) {
                        final postId = notification.route!.split('/')[2];
                        Navigator.pushNamed(context, '/post_details', arguments: postId);
                        userController.setNotificationRead(notificationId: notification.id!, type: notification.type).whenComplete(() => eventBus?.fire('refresh_notifications'));
                        return;
                      }
                      Navigator.pushNamed(context, notification.route!, arguments: notification.arguments);
                    }
                    userController.setNotificationRead(notificationId: notification.id!, type: notification.type).whenComplete(() => eventBus?.fire('refresh_notifications'));
                  },
                  tileColor: notification.read == true ? null : Theme.of(context).colorScheme.tertiary.withValues(alpha: .2),
                  leading: notification.image?.isEmpty ?? true ? null : NotificationImage(src: notification.image!),
                  title: Text(notification.title ?? '', style: TextStyle(fontSize: 14)),
                  subtitle: Text(notification.body ?? '', style: TextStyle(fontSize: 12)),
                  trailing: Text(
                    notification.createdAt?.toDate().toCommentDate() ?? '',
                    style: const TextStyle(fontSize: 10, color: Color.fromRGBO(167, 167, 167, 1))
                  )
                );
              },
            );
          },
        ),
      ),
    );
  }
}