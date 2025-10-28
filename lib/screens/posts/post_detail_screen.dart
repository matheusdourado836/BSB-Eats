import 'package:bsb_eats/controller/social_media_controller.dart';
import 'package:bsb_eats/shared/widgets/app_logo_widget.dart';
import 'package:bsb_eats/shared/widgets/post_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controller/user_controller.dart';

class PostDetailScreen extends StatelessWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    final socialMediaController = Provider.of<SocialMediaController>(context, listen: false);
    final userController = Provider.of<UserController>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
          icon: Icon(Icons.adaptive.arrow_back_rounded)
        ),
        leadingWidth: 38,
        title: const AppLogoWidget(
          onWhiteBackground: true,
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 8, bottom: 36),
        child: FutureBuilder(
          future: socialMediaController.fetchPostById(postId),
          builder: (context, snapshot) {
            if(snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                width: double.infinity,
                height: MediaQuery.sizeOf(context).height,
                alignment: Alignment.center,
                child: CircularProgressIndicator()
              );
            }
            if(snapshot.hasError || snapshot.data == null) {
              return Container(
                width: double.infinity,
                height: MediaQuery.sizeOf(context).height,
                alignment: Alignment.center,
                child: Text(snapshot.error.toString())
              );
            }
        
            final post = snapshot.data!;
        
            return PostCard(
              post: post,
              isLiked: userController.currentUser?.likes?.any((like) => like.id == post.id) ?? false,
            );
          }
        ),
      ),
    );
  }
}
