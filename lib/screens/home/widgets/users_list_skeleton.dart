import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class UsersListSkeleton extends StatelessWidget {
  const UsersListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey,
      highlightColor: Colors.white,
      child: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle
              ),
            ),
            title: Container(
              width: double.infinity,
              height: 10,
              color: Colors.grey,
            ),
            subtitle: Container(
              width: double.infinity,
              height: 10,
              color: Colors.grey,
            ),
          );
        }
      ),
    );
  }
}
