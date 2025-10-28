import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ChipListSkeleton extends StatelessWidget {
  const ChipListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
        baseColor: Colors.grey,
        highlightColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: SizedBox(
            width: MediaQuery.sizeOf(context).width,
            height: 45,
            child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: 5,
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Container(
                      height: 20,
                      width: 95,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  );
                }
            ),
          ),
        )
    );
  }
}