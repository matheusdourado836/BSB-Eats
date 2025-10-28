import 'package:bsb_eats/screens/guest/tabs/guest_feed_tab.dart';
import 'package:bsb_eats/screens/guest/tabs/guest_home_tab.dart';
import 'package:flutter/material.dart';
import 'package:bsb_eats/screens/home/tabs/profile_tab.dart';

class GuestScreen extends StatefulWidget {
  const GuestScreen({super.key});

  @override
  State<GuestScreen> createState() => _GuestScreenState();
}

class _GuestScreenState extends State<GuestScreen> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: IndexedStack(
          index: currentIndex,
          children: [
            const GuestHomeTab(),
            const GuestFeedTab(),
            const SizedBox(),
          ]
        )
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() => currentIndex = index);
          if(currentIndex == 2) {
            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
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
            label: 'Entrar',
          )
        ]
      ),
    );
  }
}