import 'package:bsb_eats/controller/restaurant_controller.dart';
import 'package:bsb_eats/controller/social_media_controller.dart';
import 'package:bsb_eats/controller/user_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late final UserController _userController = Provider.of<UserController>(context, listen: false);
  late final RestaurantController _restaurantController = Provider.of<RestaurantController>(context, listen: false);
  late final SocialMediaController _socialMediaController = Provider.of<SocialMediaController>(context, listen: false);
  int totalRestaurantes = 0;
  int totalUsuarios = 0;
  int totalFeedbacks = 0;
  int totalNotifications = 0;
  bool _loading = false;

  Future<void> _fetchInfo() async {
    setState(() => _loading = true);
    totalRestaurantes = await _restaurantController.getRestaurantCount();
    totalUsuarios = await _userController.getUserCount();
    totalFeedbacks = await _userController.getFeedbacksCount();
    totalNotifications = await _socialMediaController.getGlobalNotificationsCount();
    setState(() => _loading = false);
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchInfo());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Painel do Administrador"),
      ),
      body: RefreshIndicator.adaptive(
        onRefresh: _fetchInfo,
        child: _loading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              spacing: 8,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    onTap: () => Navigator.pushNamed(context, '/admin/manage_restaurants'),
                    leading: Icon(Icons.restaurant, color: Theme.of(context).primaryColor),
                    title: const Text("Restaurantes cadastrados"),
                    subtitle: Text("$totalRestaurantes"),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded),
                  ),
                ),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    onTap: () => Navigator.pushNamed(context, '/admin/manage_users'),
                    leading: Icon(Icons.people, color: Theme.of(context).primaryColor),
                    title: const Text("Usuários cadastrados"),
                    subtitle: Text("$totalUsuarios"),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded),
                  ),
                ),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    onTap: () => Navigator.pushNamed(context, '/admin/feedbacks'),
                    leading: Icon(Icons.feedback, color: Theme.of(context).primaryColor),
                    title: const Text("Feedbacks recebidos"),
                    subtitle: Text("$totalFeedbacks"),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded),
                  ),
                ),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    onTap: () => Navigator.pushNamed(context, '/admin/notifications'),
                    leading: Icon(Icons.notifications, color: Theme.of(context).primaryColor),
                    title: const Text("Notificações globais"),
                    subtitle: Text("$totalNotifications"),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded),
                  ),
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: .2,
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          onTap: null,
                          leading: Icon(Icons.local_offer, color: Theme.of(context).primaryColor),
                          title: const Text("Cupons"),
                          subtitle: Text("100"),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded),
                        ),
                      ),
                    ),
                    Center(
                      child: Text('Em breve...', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18),),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}