import 'package:bsb_eats/controller/user_controller.dart';
import 'package:bsb_eats/shared/util/extensions.dart';
import 'package:bsb_eats/shared/widgets/ask_to_login_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:provider/provider.dart';
import '../../../shared/model/user.dart';
import '../../shared/model/post.dart';
import '../../shared/widgets/post_page_error_widget.dart';
import '../../shared/widgets/post_card.dart';
import '../../shared/widgets/user_profile_stats.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this);
  late final _userController = Provider.of<UserController>(context, listen: false);
  final EventBus eventBus = EventBus();
  bool? _isFollowing;
  PagingState<DocumentSnapshot?, Post> _state = PagingState();
  DocumentSnapshot? lastDoc;
  MyUser? selectedUser;

  void _fetchNextPage() async {
    if (_state.isLoading) return;

    setState(() {
      _state = _state.copyWith(isLoading: true, error: null);
    });

    try {
      final newKey = lastDoc;
      List<Post> newItems = await _userController.fetchUserPosts(
        selectedUser!.id!,
        startAfter: newKey,
        pageSize: 6,
      );
      final isLastPage = newItems.isEmpty;

      setState(() {
        lastDoc = isLastPage ? null : _userController.lastPostDoc;
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

  Future<void> fetchUserData() async {
    selectedUser = await _userController.getUserById(widget.userId);
    await getUserInfoCount();
    setState(() {
      lastDoc = null;
      _state = _state.reset();
    });
  }

  Future<void> getUserInfoCount() async {
    selectedUser!.postsCount = await _userController.getUserPostsCount(selectedUser?.id);
    final res = await Future.wait([
      _userController.getFollowersAndFollowingCount(userId: selectedUser!.id, collection: 'followers'),
      _userController.getFollowersAndFollowingCount(userId: selectedUser!.id, collection: 'following'),
    ]);
    selectedUser!.followersCount = res[0];
    selectedUser!.followingCount = res[1];
    return;
  }

  double _calculateExpandedHeight(String bio) {
    final baseHeight = 280.0; // altura base para foto, stats, botão
    double bioExtra = (bio.length / 40).ceil() * 30.0;
    if(bioExtra == 0) {
      bioExtra = 30.0;
    }
    return baseHeight + bioExtra;
  }


  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      selectedUser = await _userController.getUserById(widget.userId);
      await getUserInfoCount();
      _isFollowing = await _userController.checkIfIsFollowing(userId: widget.userId);
      setState(() {});
    });
    eventBus.on().listen((event) {
      if(event == 'Refresh') {
        setState(() {
          lastDoc = null;
          _state = _state.reset();
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Consumer<UserController>(
        builder: (context, value, _) {
          if(value.loading) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  pinned: true,
                  floating: true,
                  expandedHeight: _calculateExpandedHeight(selectedUser?.bio ?? ''),
                  scrolledUnderElevation: 0,
                  leadingWidth: 24,
                  title: Row(
                    spacing: 6,
                    children: [
                      Text('@${selectedUser?.username ?? ''}'),
                      if(selectedUser?.verified == true)
                        const Icon(Icons.verified, color: Colors.blue, size: 18)
                    ],
                  ),
                  actions: [
                    IconButton(
                      onPressed: () => fetchUserData(),
                      icon: const Icon(Icons.refresh)
                    ),
                  ],
                  flexibleSpace: SafeArea(
                    child: FlexibleSpaceBar(
                      background: Column(
                        spacing: 16,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: kToolbarHeight, left: 16, right: 16),
                            child: ProfileStatsRow(user: selectedUser),
                          ),
                          if(_isFollowing != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isFollowing ?? false ? Colors.grey : theme().primaryColor,
                                  padding: EdgeInsets.zero
                                ),
                                onPressed: () {
                                  if(_userController.currentUser == null) {
                                    showDialog(context: context, builder: (context) => const AskToLoginDialog());
                                    return;
                                  }
                                  final follower = Follower(
                                    id: selectedUser?.id,
                                    nome:  selectedUser?.nome,
                                  );
                                  _userController.toggleFollow(_isFollowing!, follower, _userController.currentUser!.username!);
                                  showCustomTopSnackBar(
                                    text: '${selectedUser?.username} ${_isFollowing! ? 'removido dos' : 'adicionado aos'} seguidores'
                                  );
                                  setState(() => _isFollowing = !_isFollowing!);
                                  if(_isFollowing!) {
                                    selectedUser?.followersCount = (selectedUser?.followersCount ?? 0) + 1;
                                    selectedUser?.followers?.add(
                                      Follower(
                                        id: _userController.currentUser!.id,
                                        nome: _userController.currentUser!.nome,
                                      )
                                    );
                                  }else {
                                    selectedUser?.followersCount = (selectedUser?.followersCount ?? 0) - 1;
                                    selectedUser?.followers?.removeWhere((element) => element.id == _userController.currentUser!.id);
                                  }
                                },
                                child: _isFollowing! ? const Text('Seguindo') :  const Text('Seguir')
                              ),
                            )
                        ],
                      ),
                    ),
                  ),
                  bottom: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    tabs: [
                      Tab(
                        icon: const Icon(Icons.grid_view_rounded),
                      ),
                      Tab(
                        icon: const Icon(Icons.favorite),
                      ),
                    ],
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                // Aba 1 - Feed
                if(selectedUser == null)
                  const SizedBox()
                else
                  CustomScrollView(
                    slivers: [
                      PagedSliverGrid<DocumentSnapshot?, Post>(
                        state: _state,
                        fetchNextPage: _fetchNextPage,
                        shrinkWrapFirstPageIndicators: true,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 1,
                          mainAxisSpacing: 1,
                          childAspectRatio: 12/16,
                        ),
                        builderDelegate: PagedChildBuilderDelegate<Post>(
                          itemBuilder: (context, post, index) => Stack(
                            fit: StackFit.expand,
                            children: [
                              InkWell(
                                onTap: () => Navigator.pushNamed(context, '/user_feed', arguments: {"posts": _state.items, "index": index, "eventBus": eventBus}),
                                child: CachedNetworkImage(
                                  imageUrl: post.photosUrls?.firstOrNull ?? '',
                                  progressIndicatorBuilder: (c, v, d) {
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: d.progress,
                                        strokeWidth: 1.5,
                                      ),
                                    );
                                  },
                                  errorWidget: (c, v, d) => const Icon(Icons.error),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              if((post.photosUrls?.length ?? 0) > 1)
                                const Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Icon(Icons.photo_library, color: Colors.white, size: 18)
                                ),
                              if(post.isPinned == 1)
                                const Positioned(
                                  top: 6,
                                  left: 6,
                                  child: Icon(Icons.push_pin, color: Colors.white, size: 18)
                                ),
                            ],
                          ),
                          firstPageProgressIndicatorBuilder: (context) => const Padding(
                            padding: EdgeInsets.only(top: 16.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          firstPageErrorIndicatorBuilder: (context) {
                            return FirstPageExceptionIndicator(
                              title: 'Erro ao carregar posts',
                              message: 'Algo não saiu como esperado...',
                              onTryAgain: () => setState(() {
                                lastDoc = null;
                                _state = _state.reset();
                              })
                            );
                          },
                          noItemsFoundIndicatorBuilder: (context) => const SizedBox(height: 400,child: Center(child: Text('Nenhum post encontrado...'))),
                          newPageProgressIndicatorBuilder: (context) => const Center(child: CircularProgressIndicator()),
                        ),
                      ),
                    ],
                  ),
      
                // Aba 2 - Curtidos
                CustomScrollView(
                  slivers: [
                    if(selectedUser?.likedPosts?.isEmpty ?? true)
                      const SliverFillRemaining(
                        child: Center(
                          child: Text('Nenhum post curtido ainda...'),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final post = selectedUser!.likedPosts![index];
                          return PostCard(post: post, isLiked: true);
                        },
                        childCount: selectedUser!.likedPosts!.length,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}