import 'package:bsb_eats/controller/user_controller.dart';
import 'package:bsb_eats/screens/home/tabs/feed_tab.dart';
import 'package:bsb_eats/screens/home/tabs/home_tab.dart';
import 'package:bsb_eats/screens/home/tabs/profile_tab.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final eventBus = EventBus();
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: IndexedStack(
          index: currentIndex,
          children: [
            const HomeTab(),
            FeedTab(eventBus: eventBus),
            ProfileTab(eventBus: eventBus),
          ]
        )
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() => currentIndex = index);
          if(currentIndex == 2) {
            final userController = Provider.of<UserController>(context, listen: false);
            //userController.fetchUserPosts(userController.currentUser!.id!);
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          )
        ]
      ),
    );
  }
}