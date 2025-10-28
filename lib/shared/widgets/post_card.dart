import 'package:bsb_eats/controller/social_media_controller.dart';
import 'package:bsb_eats/controller/user_controller.dart';
import 'package:bsb_eats/screens/home/widgets/comments_widget.dart';
import 'package:bsb_eats/shared/model/post.dart';
import 'package:bsb_eats/shared/model/user.dart';
import 'package:bsb_eats/shared/util/extensions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:event_bus/event_bus.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:view_more/view_more.dart';
import '../../service/firebase_analytics_service.dart';
import 'ask_to_login_dialog.dart';
import 'user_avatar_widget.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final bool isLiked;
  final EventBus? eventBus;
  const PostCard({super.key, required this.post, required this.isLiked, this.eventBus});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(vsync: this);
  late final _userController = Provider.of<UserController>(context, listen: false);
  late final _socialMediaController = Provider.of<SocialMediaController>(context, listen: false);
  final PageController _pageController = PageController();
  int _page = 1;
  bool _isLiked = false;

  Widget _postHeader() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              if(widget.post.authorID == _userController.currentUser?.id) {
                Navigator.pushNamed(context, '/user_profile');
                _userController.fetchUserPosts(_userController.currentUser!.id!);
              }else {
                if(widget.post.author == null) return;
                Navigator.pushNamed(context, '/profile', arguments: widget.post.author?.id);
              }
            },
            child: CircleAvatar(
              radius: 25,
              backgroundImage: CachedNetworkImageProvider(
                widget.post.author?.profilePhotoUrl ?? '',
                errorListener: (e) => const NoBgUser(),
              ),
              onBackgroundImageError: (e, s) => const NoBgUser(),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                spacing: 4,
                children: [
                  Text(widget.post.author?.username ?? 'Anônimo', style: TextStyle(fontWeight: FontWeight.bold),),
                  if(widget.post.author?.verified == true)
                    const Icon(Icons.verified, size: 14, color: Colors.blue),
                ],
              ),
              if(widget.post.restaurant != null)
                InkWell(
                  onTap: () => Navigator.pushNamed(context, '/restaurant_details', arguments: widget.post.restaurant?.id),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, size: 14),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 200),
                        child: Text(
                          widget.post.restaurant!.nome ?? '',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              decoration: TextDecoration.underline,
                              fontSize: 12
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 2),
                      Text(
                        (widget.post.restaurant!.avaliacao ?? 0.0).toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const Spacer(),
          if (widget.post.author?.id == _userController.currentUser?.id)
            IconButton(
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => showModalBottomSheet(
                  context: context,
                  showDragHandle: true,
                  builder: (context) => _MoreWidget(
                    post: widget.post,
                    isPinned: widget.post.isPinned == 1
                  ),
                ).then((res) {
                  if(res == 'edited') {
                    setState(() {});
                    widget.eventBus?.fire({
                      'edited': {
                        'post': widget.post
                      }
                    });
                  }else if(res is Map) {
                    if(res.keys.first == 'pin') {
                      _socialMediaController.togglePin(widget.post, res['pin']);
                      showCustomTopSnackBar(
                        text: res['pin'] == 1 ? 'Post fixado com sucesso!' : 'Post desfixado com sucesso!',
                      );
                      widget.eventBus?.fire({
                        'pinned': {
                          'postId': widget.post.id,
                          'isPinned': res['pin'] == 1
                        }
                      });
                    }else if(res.keys.first == 'deleted') {
                      _socialMediaController
                        .deletePost(post: widget.post)
                        .whenComplete(() {
                          //_userController.fetchUserPosts(_userController.currentUser!.id!);
                          widget.eventBus?.fire({'deleted': widget.post.id});
                          showCustomTopSnackBar(text: 'Post deletado com sucesso!');
                        });
                    }
                  }
                }),
              icon: const Icon(Icons.more_vert),
            ),
        ],
      ),
    );
  }

  Widget _postBody() => SizedBox(
    height: 400,
    width: double.infinity,
    child: GestureDetector(
      onDoubleTap: () {
        if(_userController.currentUser == null) return;
        if(!_isLiked) {
          final like = Like(id: widget.post.id, nome: widget.post.author?.nome);
          _userController.toggleLike(_isLiked, widget.post, like, _userController.currentUser!.username!);
          setState(() => _isLiked = true);
          widget.post.likes?.add(like);
          widget.post.qtdCurtidas =(widget.post.qtdCurtidas ?? 0) + 1;
          _socialMediaController.editPostData(widget.post);
        }
        controller.forward(from: 0);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.post.photosUrls?.length ?? 0,
            onPageChanged: (index) => setState(() => _page = index + 1),
            itemBuilder: (context, index) {
              final image = widget.post.photosUrls?[index];
              return CachedNetworkImage(
                imageUrl: image ?? '',
                fit: BoxFit.cover,
                progressIndicatorBuilder: (c, v, d) {
                  return Center(
                    child: CircularProgressIndicator(
                      value: d.progress,
                      strokeWidth: 1.5,
                    ),
                  );
                },
                errorWidget: (c, v, d) => const Icon(Icons.error),
              );
            },
          ),
          if (widget.post.taggedPeople?.isNotEmpty ?? false)
            Positioned(
              bottom: 4,
              left: 4,
              child: IconButton.filled(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  showDragHandle: true,
                  builder: (context) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 8.0,
                            bottom: 24,
                          ),
                          child: Text(
                            'Nesta foto',
                            style: theme().textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        _TaggedPeopleModal(
                          post: widget.post,
                          toggleFollow: toggleFollow
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.person, size: 22),
              ),
            ),
          if((widget.post.photosUrls?.length ?? 0) > 1)
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  '$_page/${widget.post.photosUrls?.length}',
                  style: TextStyle(color: theme().colorScheme.surface),
                ),
              ),
            ),
          if((widget.post.photosUrls?.length ?? 0) > 1)
            Positioned(
              bottom: 10,
              width: MediaQuery.of(context).size.width,
              child: Center(
                child: SmoothPageIndicator(
                  controller: _pageController,  // PageController
                  count: widget.post.photosUrls?.length ?? 0,
                  effect: WormEffect(
                      dotWidth: 10,
                      dotHeight: 10,
                      activeDotColor: theme().primaryColor
                  ),
                  onDotClicked: (index) => _pageController.animateToPage(index, duration: 300.ms, curve: Curves.easeIn)
                ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Icon(
              Icons.favorite,
              size: 150,
              color: Colors.red,
              shadows: kElevationToShadow[4],
              ).animate(controller: controller, value: 1)
                  .scaleXY(begin: .8, duration: 180.ms)
                  .scaleXY(begin: 1.2, delay: 180.ms)
                  .scaleXY(begin: 1.2, duration: 180.ms)
                  .scaleXY(begin: .8, delay: 360.ms)
                  .fadeOut(delay: 500.ms)
            )
        ],
      ),
    ),
  );

  Widget _postFooter() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          _iconRow(
            _isLiked ? Icons.favorite : Icons.favorite_border,
            color: _isLiked ? Colors.red : null,
            widget.post.qtdCurtidas?.toString() ?? '0',
            onPressed: () {
              if(_userController.currentUser == null) {
                showDialog(context: context, builder: (context) => const AskToLoginDialog());
                return;
              }
              final like = Like(id: widget.post.id, nome: widget.post.author?.nome);
              _userController.toggleLike(_isLiked, widget.post, like, _userController.currentUser!.username!);
              setState(() => _isLiked = !_isLiked);
              if(_isLiked) {
                widget.post.likes?.add(like);
                widget.post.qtdCurtidas =(widget.post.qtdCurtidas ?? 0) + 1;
              }else {
                widget.post.likes?.removeWhere((element) => element.id == like.id);
                widget.post.qtdCurtidas =(widget.post.qtdCurtidas ?? 0) - 1;
              }
              _socialMediaController.editPostData(widget.post);
            },
          ),
          _iconRow(
            Icons.chat_bubble_outline_rounded,
            widget.post.qtdComentarios?.toString() ?? '0',
            onPressed: () => showModalBottomSheet(
              context: context,
              showDragHandle: true,
              useSafeArea: true,
              isScrollControlled: true,
              backgroundColor: theme().colorScheme.surface,
              builder: (context) => CommentsSection(
                post: widget.post,
                ownerName: widget.post.author?.nome ?? 'anônimo'
              )
            ),
          ),
          IconButton(
            onPressed: () {
              share(
                title: 'Compartilhar post',
                text: 'Olhe que legal este post que vi no app BSB Eats\n${dotenv.get('BSB_EATS_FRIENDLY_BASE_URL')}/post/${widget.post.id}'
              ).then((res) {
                if(res == ShareResultStatus.success) {
                  final name = widget.post.author!.nome!;
                  AnalyticsService.instance.logEvent(
                      name: 'post_shared',
                      parameters: {
                        'created_at': DateTime.now().toIso8601String(),
                        'user_id': _userController.currentUser!.id!,
                        'username': _userController.currentUser!.nome!,
                        'post_id': widget.post.id!,
                        'name': name
                      }
                  );
                }
              });
            },
            icon: const Icon(Icons.share)
          ),
        ],
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(12.0, 4, 4, 4),
        child: ViewMore(
          widget.post.caption ?? '',
          colorClickableText: theme().primaryColor,
          trimLength: 70,
          preDataText: widget.post.author?.username ?? 'Anônimo',
          preDataTextStyle: TextStyle(fontWeight: FontWeight.bold),
          trimCollapsedText: 'ver mais',
          trimExpandedText: 'ver menos',
          moreStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          lessStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
      _reviewContainer(),
      Padding(
        padding: const EdgeInsets.only(left: 14.0),
        child: Text(
          widget.post.createdAt?.toFriendlyDate() ?? '',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ),
    ],
  );

  Widget _iconRow(IconData icon, String text, {required Function() onPressed, Color? color}) {
    return IconButton(
      onPressed: onPressed,
      icon: Row(
        spacing: 6,
        children: [
          Icon(icon, color: color),
          Text(text, style: TextStyle(fontSize: 16),),
        ],
      )
    );
  }

  Widget _reviewContainer() {
    final preco = widget.post.avaliacao?.price ?? 1;
    final atmosphere = widget.post.avaliacao?.atmosphere ?? 1;
    final food = widget.post.avaliacao?.food ?? 1;
    final service = widget.post.avaliacao?.service ?? 1;
    final average = (preco + atmosphere + food + service) / 4;

    Widget buildStarRow(String label, int value) => Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        spacing: 4,
        children: [
          Text(label, style: theme().textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w500)),
          const Spacer(),
          ...List.generate(5, (index) => index + 1 <= value ? Icon(Icons.star, color: Colors.yellow) : Icon(Icons.star_border, color: Colors.yellow))
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme().primaryColor.withValues(alpha: .75),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpandablePanel(
        theme: ExpandableThemeData(
          tapBodyToCollapse: true,
          iconColor: theme().colorScheme.onPrimary
        ),
        header: Row(
          spacing: 8,
          children: [
            Text('Avaliação geral', style: theme().textTheme.titleLarge?.copyWith(fontSize: 18)),
            Row(
              spacing: 4,
              children: [
                Icon(Icons.star, color: Colors.yellow),
                Text(average.toStringAsFixed(1), style: theme().textTheme.titleLarge?.copyWith(fontSize: 18)),
              ],
            )
          ],
        ),
        collapsed: Text(
            widget.post.avaliacao?.text ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme().textTheme.labelSmall?.copyWith(fontSize: 16, fontWeight: FontWeight.w500)
        ),
        expanded: Column(
          children: [
            const SizedBox(height: 24),
            buildStarRow('Preço', preco),
            buildStarRow('Ambiente', atmosphere),
            buildStarRow('Comida', food),
            buildStarRow('Serviço', service),
            const SizedBox(height: 24),
            if(widget.post.avaliacao?.text?.isNotEmpty ?? false)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme().colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(widget.post.avaliacao!.text!),
              )
          ],
        )
      ),
    );
  }

  Future<void> toggleFollow(MyUser user) async {
    final isFollowing = (_userController.currentUser!.following?.any((f) => f.id == user.id) ?? false);
    await _userController.toggleFollow(
      isFollowing,
      Follower(id: user.id, nome: user.nome),
      _userController.currentUser!.username!
    );
    showCustomTopSnackBar(text: isFollowing ? '${user.username} removido dos seguidores' : '${user.username} adicionado aos seguidores');
    setState(() {});
  }

  @override
  void initState() {
    controller.stop();
    _isLiked = widget.isLiked;
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      width: mediaQuery().size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [_postHeader(), _postBody(), _postFooter()],
      ),
    );
  }
}

class _TaggedPeopleModal extends StatelessWidget {
  final Post post;
  final Future<void> Function(MyUser user) toggleFollow;
  const _TaggedPeopleModal({required this.post, required this.toggleFollow});

  @override
  Widget build(BuildContext context) {
    final userController = Provider.of<UserController>(context, listen: false);
    final socialMediaController = Provider.of<SocialMediaController>(context, listen: false);
    if(post.users == null) socialMediaController.getTaggedPeople(post);
    if(userController.currentUser?.following == null) {
      userController.getFollowersAndFollowing(userId: userController.currentUser?.id, collection: 'following').then((res) {
        userController.currentUser?.following = res ?? [];
        userController.notify();
      });
    }
    return Consumer2<SocialMediaController, UserController>(
      builder: (context, social, userC, _) {
        if(post.users?.isEmpty ?? true) const SizedBox();

        return ListView.builder(
          shrinkWrap: true,
          itemCount: post.users!.length,
          itemBuilder: (context, index) {
            final user = post.users![index];
            return ListTile(
              onTap: () {
                if(user.id == userC.currentUser?.id) {
                  Navigator.pushNamed(context, '/user_profile');
                }else {
                  Navigator.pushNamed(context, '/profile', arguments: user.id);
                }
              },
              horizontalTitleGap: 8,
              leading: Container(
                decoration: BoxDecoration(
                    border: Border.all(width: .2),
                    shape: BoxShape.circle
                ),
                child: CircleAvatar(
                  radius: 25,
                  backgroundImage: CachedNetworkImageProvider(
                    user.profilePhotoUrl ?? '',
                    errorListener: (e) => const NoBgUser(),
                  ),
                ),
              ),
              title: Row(
                spacing: 4,
                children: [
                  Flexible(child: Text(user.username ?? '', overflow: TextOverflow.ellipsis)),
                  if(user.verified ?? false)
                    const Icon(Icons.verified, size: 14, color: Colors.blue),
                ],
              ),
              subtitle: Text(user.nome ?? '', overflow: TextOverflow.ellipsis),
              trailing: (user.id == userC.currentUser?.id) ? null : ElevatedButton(
                onPressed: () {
                  if(userC.currentUser == null) {
                    showDialog(context: context, builder: (context) => const AskToLoginDialog());
                    return;
                  }
                  toggleFollow(user);
                },
                style: ElevatedButton.styleFrom(
                  fixedSize: const Size(110, 30),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  backgroundColor: userC.currentUser?.following?.any((f) => f.id == user.id) ?? false
                    ? Colors.grey
                    : Theme.of(context).primaryColor,
                ),
                child: userC.currentUser?.following?.any((f) => f.id == user.id) ?? false
                  ? const Text('Seguindo')
                  : const Text('Seguir'),
              ),
            );
          }
        );
      },
    );
  }
}


class _MoreWidget extends StatelessWidget {
  final Post post;
  final bool isPinned;
  const _MoreWidget({required this.post, required this.isPinned});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/edit_post', arguments: {"post": post}).then((res) {
              if(res == true) {
                Navigator.pop(context, 'edited');
              }
            }),
            style: TextButton.styleFrom(alignment: Alignment.centerLeft),
            label: const Text('Editar'),
            icon: const Icon(Icons.edit),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, {'pin': !isPinned == true ? 1 : 0}),
            style: TextButton.styleFrom(alignment: Alignment.centerLeft),
            label: (isPinned) ? const Text('Desfixar do feed') : const Text('Fixar no feed'),
            icon: const Icon(Icons.push_pin),
          ),
          TextButton.icon(
            onPressed: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Confirmar ação'),
                content: const Text('Deseja realmente excluir?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Excluir'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
            ).then((res) {
              if (res == true) {
                Navigator.pop(context, {
                  'deleted': {'postId': post.id}
                });
              }
            }),
            style: TextButton.styleFrom(alignment: Alignment.centerLeft),
            label: const Text('Excluir', style: TextStyle(color: Colors.red)),
            icon: const Icon(Icons.delete, color: Colors.red),
          ),
        ],
      ),
    );
  }
}
