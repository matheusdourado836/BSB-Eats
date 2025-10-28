import 'package:bsb_eats/controller/user_controller.dart';
import 'package:bsb_eats/shared/util/extensions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:view_more/view_more.dart';

import '../../../shared/widgets/user_avatar_widget.dart';
import '../widgets/profile_picture_selected.dart';

class FeedbacksScreen extends StatefulWidget {
  const FeedbacksScreen({super.key});

  @override
  State<FeedbacksScreen> createState() => _FeedbacksScreenState();
}

class _FeedbacksScreenState extends State<FeedbacksScreen> {
  late final UserController _userController = Provider.of<UserController>(context, listen: false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Feedbacks'),
      ),
      body: FutureBuilder(
        future: _userController.fetchFeedbacks(),
        builder: (context, snapshot) {
          if(snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if(snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar feedbacks'));
          }

          final feedbacks = snapshot.data ?? [];
          if(feedbacks.isEmpty) {
            return const Center(child: Text('Nenhum feedback encontrado...'));
          }

          return ListView.builder(
            itemCount: feedbacks.length,
            itemBuilder: (context, index) {
              final feedback = feedbacks[index];
              return ListTile(
                horizontalTitleGap: 6,
                titleAlignment: ListTileTitleAlignment.top,
                leading: InkWell(
                  onTap: () => showDialog(
                    context: context,
                    builder: (context) => ProfilePictureSelected(
                      user: feedback.user,
                      currentUser: _userController.currentUser!,
                    )
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage: CachedNetworkImageProvider(
                      feedback.user?.profilePhotoUrl ?? "",
                      errorListener: (e) => const NoBgUser(),
                    ),
                    onBackgroundImageError: (exception, stackTrace) => const NoBgUser()
                  ),
                ),
                title: Text(feedback.user?.username ?? 'Sem nome'),
                subtitle: ViewMore(
                  feedback.text ?? '',
                  trimLines: 5,
                  colorClickableText: theme().primaryColor,
                  trimMode: Trimer.line,
                  preDataTextStyle: TextStyle(fontWeight: FontWeight.bold),
                  trimCollapsedText: 'ver mais',
                  trimExpandedText: 'ver menos',
                  moreStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  lessStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              );
            }
          );
        }
      ),
    );
  }
}
