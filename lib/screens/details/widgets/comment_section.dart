import 'package:bsb_eats/controller/user_controller.dart';
import 'package:bsb_eats/shared/model/avaliacao.dart';
import 'package:bsb_eats/shared/model/review.dart';
import 'package:bsb_eats/shared/util/extensions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/comment_skeleton.dart';


class CommentSection extends StatefulWidget {
  final List<dynamic> comments;
  final String? restaurantId;
  const CommentSection({super.key, required this.comments, this.restaurantId});

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final EventBus _eventBus = EventBus();
  late final userController = Provider.of<UserController>(context, listen: false);

  Future<void> getUsersData() async {
    final appReviews = widget.comments.whereType<Avaliacao>().toList();
    final futures = appReviews.map((r) {
      return userController.getUserById(r.userId).then((res) => r.user = res);
    }).toList();

    await Future.wait(futures);
    setState(() {});
    return;
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) => getUsersData());
    _eventBus.on().listen((event) {
      if(event is String) {
        final id = event;
        widget.comments.removeWhere((element) => element is Avaliacao && element.id == id);
        userController.deleteReview(widget.restaurantId!, id).whenComplete(() {
          showCustomTopSnackBar(text: 'Avaliação removida com sucesso!');
        });
        setState(() {});
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if(widget.comments.whereType<Avaliacao>().where((a) => a.user == null).isNotEmpty) {
      return const CommentsSkeleton();
    }else {
      return GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! > 0) {
            Navigator.pop(context);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            //TODO REMOVER ESSA LINHA NA PROXIMA ATUALIZACAO
            Center(child: Text('deslize para a direita para fechar')),
            Align(
              alignment: FractionalOffset.centerRight,
              child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                      textStyle: TextStyle(decoration: TextDecoration.underline)
                  ),
                  child: const Text('Fechar')
              ),
            ),
            Expanded(
              child: ListView.separated(
                shrinkWrap: true,
                separatorBuilder: (context, index) => const Divider(),
                itemCount: widget.comments.length,
                itemBuilder: (context, index) {
                  final comment = widget.comments[index];
                  if(comment is Review) {
                    return _GoogleComment(comment: comment);
                  }else {
                    final appReview = comment as Avaliacao?;
                    final preco = appReview?.price ?? 1;
                    final atmosphere = appReview?.atmosphere ?? 1;
                    final food = appReview?.food ?? 1;
                    final service = appReview?.service ?? 1;
                    final average = (preco + atmosphere + food + service) / 4;
                    return _AppComment(
                      appReview: appReview,
                      average: average,
                      currentUserId: userController.currentUser?.id,
                      eventBus: _eventBus,
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 16)
          ],
        ),
      );
    }
  }
}

class _AppComment extends StatelessWidget {
  final Avaliacao? appReview;
  final double average;
  final String? currentUserId;
  final EventBus eventBus;
  const _AppComment({required this.appReview, required this.average, this.currentUserId, required this.eventBus});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if(appReview?.user?.id == currentUserId) {
          Navigator.pushNamed(context, '/user_profile');
        }else {
          Navigator.pushNamed(context, '/profile', arguments: appReview?.user?.id);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
        child: Column(
          spacing: 8,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: 8,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: appReview?.user?.profilePhotoUrl?.isEmpty ?? true
                      ? null
                      : CachedNetworkImageProvider(appReview!.user!.profilePhotoUrl!),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Row(
                          spacing: 4,
                          children: [
                            Text(
                              appReview?.user?.username ?? 'N/A',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if(appReview?.user?.verified == true)
                              const Icon(Icons.verified, color: Colors.blue, size: 16)
                          ],
                        ),
                        Transform.scale(
                          scale: .8,
                          child: Chip(
                            backgroundColor: Theme.of(context).primaryColor,
                            side: BorderSide.none,
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            label: Row(
                              spacing: 4,
                              children: [
                                Text(
                                  'App',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 14),
                                ),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(100),
                                  child: Image.asset(
                                    'assets/images/logo_alt.png',
                                    width: 25,
                                    height: 25,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        if(currentUserId == appReview?.userId)
                          IconButton(
                            onPressed: () => showDialog(context: context, builder: (context) => AlertDialog(
                              title: const Text('Deseja remover sua avaliação?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    eventBus.fire(appReview?.id);
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Sim'),
                                )
                              ],
                            )),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.delete, color: Colors.red)
                          )
                      ],
                    ),
                    Row(
                      spacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            average.toInt(),
                                (index) => const Icon(Icons.star, color: Colors.amber, size: 16),
                          )
                        ),
                        Text(appReview?.createdAt?.toCommentDate() ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12))
                      ],
                    )
                  ],
                )
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(appReview?.text ?? 'N/A'),
            )
          ]
        ),
      ),
    );
  }
}

class _GoogleComment extends StatelessWidget {
  final Review comment;
  const _GoogleComment({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
      child: Column(
        spacing: 8,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            spacing: 8,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: comment.authorAttribution?.photoUri?.isEmpty ?? true
                    ? null
                    : NetworkImage(comment.authorAttribution!.photoUri!),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comment.authorAttribution?.displayName ?? 'N/A',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    spacing: 6,
                    children: [
                      Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            comment.rating ?? 0,
                                (index) => const Icon(Icons.star, color: Colors.amber, size: 16),
                          )
                      ),
                      Text(comment.publishTime?.toCommentDate() ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12))
                    ],
                  )
                ],
              )
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(comment.text?.text ?? 'N/A'),
          )
        ]
      ),
    );
  }
}