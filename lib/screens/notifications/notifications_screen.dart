import 'package:bsb_eats/controller/user_controller.dart';
import 'package:bsb_eats/shared/util/extensions.dart';
import 'package:bsb_eats/shared/widgets/notification_image.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NotificationsScreen extends StatefulWidget {
  final EventBus? eventBus;
  const NotificationsScreen({super.key, this.eventBus});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final UserController _userController = Provider.of<UserController>(context, listen: false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadNotifications());
  }

  Future<void> _loadNotifications() async {
    await _userController.getNotifications();
    widget.eventBus?.fire('refresh_notifications');
    setState(() {}); // força rebuild no RefreshIndicator
  }

  Future<void> _confirmDeleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar ação'),
        content: const Text('Deseja remover todas suas notificações?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Não')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sim')),
        ],
      ),
    );

    if (confirmed == true) {
      await _userController.deleteAllNotifications();
      widget.eventBus?.fire('refresh_notifications');
      if (mounted) {
        showCustomSnackBar(child: Text('Notificações removidas com sucesso!'));
      }
      setState(() {});
    }
  }

  void _undoDelete(int index, notification) {
    setState(() {
      _userController.currentUser?.notifications?.insert(index, notification);
    });
    _userController.updateNotification(
      notification,
      add: false,
      {"pendingDelete": false, "read": notification.read},
    ).whenComplete(() => widget.eventBus?.fire('refresh_notifications'));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  void _openNotification(context, notification) {
    notification.read = true;

    final route = notification.route;
    final args = notification.arguments;

    if (route?.isEmpty ?? true) return;

    if (route!.contains('/splash')) {
      Navigator.pushNamed(context, args?["route"], arguments: args);
    } else if (route.contains('/post')) {
      final postId = route.split('/')[2];
      Navigator.pushNamed(context, '/post_details', arguments: postId);
    } else {
      Navigator.pushNamed(context, route, arguments: args);
    }

    _userController.setNotificationRead(
      notificationId: notification.id!,
      type: notification.type,
    ).whenComplete(() => widget.eventBus?.fire('refresh_notifications'));
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        centerTitle: true,
        scrolledUnderElevation: 0,
        actions: [
          if (_userController.currentUser?.notifications?.isNotEmpty ?? false)
            IconButton(
              onPressed: _confirmDeleteAll,
              icon: const Icon(Icons.delete_forever),
            ),
        ],
      ),
      body: RefreshIndicator.adaptive(
        onRefresh: _loadNotifications,
        child: Consumer<UserController>(
          builder: (context, value, _) {
            final notifications = value.currentUser?.notifications ?? [];

            if (value.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (notifications.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Dismissible(
                  key: ValueKey(notification.id),
                  direction: DismissDirection.startToEnd,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    setState(() => notifications.remove(notification));
                    _userController.updateNotification(
                      notification,
                      add: true,
                      {"pendingDelete": true, "read": true},
                    ).whenComplete(() => widget.eventBus?.fire('refresh_notifications'));

                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Notificação deletada'),
                            TextButton(
                              onPressed: () => _undoDelete(index, notification),
                              child: const Text(
                                'Desfazer',
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: ListTile(
                    onTap: () => _openNotification(context, notification),
                    tileColor: notification.read == true
                        ? null
                        : theme().colorScheme.tertiary.withValues(alpha: .15),
                    leading: (notification.image?.isNotEmpty ?? false)
                        ? NotificationImage(src: notification.image!)
                        : null,
                    title: Text(notification.title ?? '', style: const TextStyle(fontSize: 14)),
                    subtitle: Text(notification.body ?? '', style: const TextStyle(fontSize: 12)),
                    trailing: Text(
                      notification.createdAt?.toDate().toCommentDate() ?? '',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final color = theme().colorScheme.tertiary.withAlpha(100);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 32),
        Center(
          child: Container(
            height: 250,
            width: 250,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.notifications, size: 230, color: theme().primaryColor),
                Positioned(
                  right: 45,
                  top: 30,
                  child: Container(
                    height: 50,
                    width: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme().colorScheme.tertiary,
                    ),
                    child: const Text('0', style: TextStyle(fontSize: 24, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 38),
        Text(
          'Sem notificações ainda',
          textAlign: TextAlign.center,
          style: theme().textTheme.headlineSmall?.copyWith(fontSize: 26),
        ),
        const SizedBox(height: 16),
        Text(
          'Você não tem notificações agora.\nVolte mais tarde',
          textAlign: TextAlign.center,
          style: theme().textTheme.bodyLarge,
        ),
        const SizedBox(height: 48),
        Center(
          child: ElevatedButton(
            onPressed: _loadNotifications,
            style: ElevatedButton.styleFrom(fixedSize: const Size(300, 50)),
            child: const Text('Atualizar'),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}