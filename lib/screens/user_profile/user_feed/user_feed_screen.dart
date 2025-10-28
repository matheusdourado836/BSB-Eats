import 'package:bsb_eats/controller/user_controller.dart';
import 'package:bsb_eats/shared/model/post.dart';
import 'package:bsb_eats/shared/widgets/card_list_skeleton.dart';
import 'package:bsb_eats/shared/model/user.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../../shared/widgets/post_card.dart';

class UserFeedScreen extends StatefulWidget {
  final List<Post> posts;
  final int index;
  final EventBus? eventBus;
  const UserFeedScreen({super.key, required this.posts, required this.index, this.eventBus});

  @override
  State<UserFeedScreen> createState() => _UserFeedScreenState();
}

class _UserFeedScreenState extends State<UserFeedScreen> {
  late final _userController = Provider.of<UserController>(context, listen: false);
  late final MyUser user = _userController.currentUser!;
  List<Post> _posts = [];

  @override
  void initState() {
    _posts = List<Post>.from(widget.posts);
    widget.eventBus?.on().listen((event) {
      if(event is Map && event.keys.first == 'deleted') {
        final postId = event.values.first;
        setState(() => _posts.removeWhere((p) => p.id == postId));
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts'),
      ),
      body: SafeArea(
        child: Consumer<UserController>(
          builder: (context, value, _) {
            if(value.loading) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: CardListSkeleton(),
              );
            }

            if(_posts.isEmpty) {
              return const Center(
                child: Text('Nenhum post encontrado'),
              );
            }

            return ScrollablePositionedList.builder(
              initialScrollIndex: widget.index,
              itemCount: _posts.length,
              itemBuilder: (context, index) {
                final post = _posts[index];
                return PostCard(
                  post: post,
                  isLiked: _userController.currentUser?.likes?.any((like) => like.id == post.id) ?? false,
                  eventBus: widget.eventBus
                );
              }
            );
          },
        ),
      ),
    );
  }
}
