import 'package:bsb_eats/controller/social_media_controller.dart';
import 'package:bsb_eats/shared/util/extensions.dart';
import 'package:bsb_eats/shared/widgets/notification_image.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';

import 'add_notification_screen.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  late final SocialMediaController _controller = Provider.of<SocialMediaController>(context, listen: false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => showDialog(context: context, builder: (context) => AlertDialog(
              title: const Text('Deletar todas as notificações?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                TextButton(
                  onPressed: () async {
                    await _controller.deleteAllNotifications();
                    Navigator.pop(context);
                    showCustomSnackBar(child: const Text('Notificações deletadas com sucesso!'));
                    setState(() {});
                  },
                  child: Text('Deletar'),
                )
              ],
            )),
            icon: const Icon(Icons.delete_forever),
          )
        ],
      ),
      body: RefreshIndicator.adaptive(
        onRefresh: () async => setState(() {}),
        child: FutureBuilder(
          future: _controller.getGlobalNotifications(),
          builder: (context, snapshot) {
            if(snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if(snapshot.hasError) {
              return const Center(child: Text('Erro ao carregar notificações'));
            }
            if(snapshot.data?.isEmpty ?? true) {
              return const Center(child: Text('Nenhuma notificação encontrada'));
            }

            return ListView.builder(
              itemCount: snapshot.data!.length,
              padding: EdgeInsets.only(bottom: 100),
              itemBuilder: (context, index) {
                final notification = snapshot.data![index];
                return ListTile(
                  minVerticalPadding: 16,
                  leading: NotificationImage(src: notification.image),
                  title: Text(notification.title ?? '', style: TextStyle(fontSize: 14)),
                  subtitle: Text(notification.body ?? '', style: TextStyle(fontSize: 12)),
                  trailing: Text(
                    notification.createdAt?.toDate().toCommentDate() ?? '',
                    style: const TextStyle(fontSize: 10, color: Color.fromRGBO(167, 167, 167, 1))
                  )
                );
              }
            );
          }
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, PageTransition(
          type: PageTransitionType.rightToLeftWithFade,
          child: const AddNotificationScreen(),
        )),
        child: const Icon(Icons.add),
      )
    );
  }
}
