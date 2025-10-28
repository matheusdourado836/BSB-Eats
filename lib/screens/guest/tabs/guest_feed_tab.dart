import 'package:bsb_eats/controller/social_media_controller.dart';
import 'package:bsb_eats/controller/user_controller.dart';
import 'package:bsb_eats/shared/model/post.dart';
import 'package:bsb_eats/shared/widgets/ask_to_login_dialog.dart';
import 'package:bsb_eats/shared/widgets/card_list_skeleton.dart';
import 'package:bsb_eats/shared/widgets/post_card.dart';
import 'package:bsb_eats/screens/home/widgets/users_list_skeleton.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/post_page_error_widget.dart';
import '../../../shared/widgets/user_avatar_widget.dart';

class GuestFeedTab extends StatefulWidget {
  const GuestFeedTab({super.key});

  @override
  State<GuestFeedTab> createState() => _GuestFeedTabState();
}

class _GuestFeedTabState extends State<GuestFeedTab> {
  late final _socialMediaController = Provider.of<SocialMediaController>(context, listen: false);
  late final _userController = Provider.of<UserController>(context, listen: false);
  PagingState<DocumentSnapshot?, Post> _state = PagingState();
  DocumentSnapshot? lastDoc;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasFocus = false;
  bool? _swap;

  void _listener() {
    if(_focusNode.hasFocus) {
      setState(() {
        _hasFocus = true;
        _swap = true;
      });
    }
  }

  void _fetchNextPage() async {
    if (_state.isLoading) return;

    setState(() {
      _state = _state.copyWith(isLoading: true, error: null);
    });

    try {
      final newKey = lastDoc;
      List<Post> newItems = await _socialMediaController.fetchPosts(
        startAfter: newKey,
        pageSize: 3,
      );
      final isLastPage = newItems.isEmpty;

      setState(() {
        lastDoc = isLastPage ? null : _socialMediaController.lastPostDoc;
        _state = _state.copyWith(
          pages: [...?_state.pages, newItems],
          keys: [...?_state.keys, newKey],
          hasNextPage: !isLastPage,
          isLoading: false,
        );
      });
    } catch (error) {
      setState(() {
        _state = _state.copyWith(
          error: error,
          isLoading: false,
        );
      });
    }
  }

  Future<void> _onRefresh() async {
    setState(() {
      lastDoc = null;
      _state = _state.reset();
    });
  }

  @override
  void initState() {
    _focusNode.addListener(_listener);
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.removeListener(_listener);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leadingWidth: 40,
        leading: !_hasFocus ? null : IconButton(
            onPressed: () => setState(() {
              _hasFocus = false;
              _swap = false;
              _searchController.clear();
              _focusNode.unfocus();
            }),
            icon: Icon(Icons.adaptive.arrow_back_rounded)
        ),
        title: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            onTapOutside: (e) => setState(() => _focusNode.unfocus()),
            onChanged: (value) => _socialMediaController.searchUser(value),
            decoration: InputDecoration(
                hintText: 'Pesquisar',
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                    onPressed: () {
                      _searchController.clear();
                      _socialMediaController.searchUser('');
                    },
                    icon: const Icon(Icons.close)
                )
            )
        ),
      ),
      body: _swap != true
          ? RefreshIndicator.adaptive(
        onRefresh: _onRefresh,
        child: PagedListView<DocumentSnapshot?, Post>(
          state: _state,
          fetchNextPage: _fetchNextPage,
          shrinkWrap: true,
          builderDelegate: PagedChildBuilderDelegate<Post>(
            itemBuilder: (context, post, index) => PostCard(
              post: post,
              isLiked: false,
            ),
            firstPageProgressIndicatorBuilder: (context) => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: CardListSkeleton(),
            ),
            noMoreItemsIndicatorBuilder: (context) => const SizedBox(height: 80),
            firstPageErrorIndicatorBuilder: (context) {
              return FirstPageExceptionIndicator(
                  title: 'Erro ao carregar posts',
                  message: 'Algo não saiu como esperado...',
                  onTryAgain: () => _onRefresh()
              );
            },
            noItemsFoundIndicatorBuilder: (context) => const Center(child: Text('Nenhum post encontrado')),
            newPageProgressIndicatorBuilder: (context) => const Center(child: CircularProgressIndicator()),
          ),
        ),
      )
          : Consumer<SocialMediaController>(
        builder: (context, value, _) {
          if(value.loading) {
            return const UsersListSkeleton();
          }

          if(value.listEmpty) {
            return const Center(
              child: Text('Nenhum usuário encontrado'),
            );
          }

          return ListView.builder(
            itemCount: value.users.length,
            itemBuilder: (context, index) {
              final user = value.users[index];
              return ListTile(
                minLeadingWidth: 0,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                horizontalTitleGap: 0,
                isThreeLine: true,
                onTap: () {
                  Future.wait([
                    _userController.getFollowersAndFollowingCount(userId: user.id, collection: 'followers'),
                    _userController.getFollowersAndFollowingCount(userId: user.id, collection: 'following'),
                  ]).then((res) {
                    user.followersCount = res[0];
                    user.followingCount = res[1];
                    Navigator.pushNamed(context, '/profile', arguments: user.id);
                  });
                },
                leading: CircleAvatar(
                  radius: 40,
                  backgroundImage: CachedNetworkImageProvider(
                    user.profilePhotoUrl ?? '',
                    errorListener: (error) => const NoBgUser(),
                  ),
                ),
                title: Row(
                  spacing: 4,
                  children: [
                    Text(user.username!),
                    if(user.verified ?? false)
                      const Icon(Icons.verified, size: 14, color: Colors.blue),
                  ],
                ),
                subtitle: Text(user.nome ?? 'anôninmo'),

              );
            }
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () => showDialog(context: context, builder: (context) => const AskToLoginDialog()),
          child: Icon(Icons.add)
      ),
    );
  }
}