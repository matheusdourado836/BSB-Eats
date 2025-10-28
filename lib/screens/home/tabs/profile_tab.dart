import 'package:bsb_eats/controller/user_controller.dart';
import 'package:bsb_eats/shared/model/post.dart';
import 'package:bsb_eats/shared/model/user.dart';
import 'package:bsb_eats/shared/util/extensions.dart';
import 'package:bsb_eats/shared/widgets/post_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/post_page_error_widget.dart';
import '../../../shared/widgets/user_profile_stats.dart';

class ProfileTab extends StatefulWidget {
  final EventBus? eventBus;
  const ProfileTab({super.key, this.eventBus});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this);
  late final _userController = Provider.of<UserController>(context, listen: false);
  PagingState<DocumentSnapshot?, Post> _state = PagingState();
  MyUser? currentUser;
  DocumentSnapshot? lastDoc;

  void _fetchNextPage() async {
    if (_state.isLoading) return;

    setState(() {
      _state = _state.copyWith(isLoading: true, error: null);
    });

    try {
      final newKey = lastDoc;
      List<Post> newItems = await _userController.fetchUserPosts(
        _userController.currentUser!.id!,
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
  
  Future<void> fetchUserInfo() async {
    currentUser = _userController.currentUser!;
    currentUser!.postsCount = await _userController.getUserPostsCount(currentUser?.id);
    final res = await Future.wait([
      _userController.getFollowersAndFollowingCount(userId: currentUser!.id!, collection: 'followers'),
      _userController.getFollowersAndFollowingCount(userId: currentUser!.id!, collection: 'following'),
    ]);
    final followers = res[0];
    final following = res[1];
    currentUser!.followersCount = followers;
    currentUser!.followingCount = following;
    setState(() {});
  }

  void sortItems(Map<String, dynamic>? data) {
    List<List<Post>> pages = [];
    final stateItems = List<Post>.from(_state.items ?? []);
    if (data != null) {
      final postId = data["postId"];
      final pinValue = data["isPinned"];
      final post = stateItems.firstWhere((p) => p.id == postId, orElse: () => Post());
      if (post.id != null) {
        post.isPinned = pinValue;
        stateItems.remove(post);
        stateItems.insert(0, post);
      }
    }

    stateItems.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
    stateItems.sort((a, b) => (b.isPinned ?? 0).compareTo(a.isPinned ?? 0));
    for(final page in _state.pages ?? []) {
      pages.add(stateItems.take(page.length).toList());
      stateItems.removeRange(0, page.length);
    }
    setState(() {
      lastDoc = null;
      _state = _state.copyWith(pages: pages);
    });
  }

  void editPost(Map<String, dynamic>? data) {
    List<List<Post>> pages = [];
    final stateItems = List<Post>.from(_state.items ?? []);
    if (data != null) {
      final postEdited = data["post"] as Post;
      Post post = stateItems.firstWhere((p) => p.id == postEdited.id, orElse: () => Post());
      final index = stateItems.indexWhere((p) => p.id == post.id);
      if (post.id != null) {
        stateItems.removeAt(index);
        stateItems.insert(index, postEdited);
      }
    }

    for(final page in _state.pages ?? []) {
      pages.add(stateItems.take(page.length).toList());
      stateItems.removeRange(0, page.length);
    }
    setState(() {
      lastDoc = null;
      _state = _state.copyWith(pages: pages);
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) => fetchUserInfo());
    widget.eventBus?.on().listen((event) {
      if(event is Map) {
        if(event.keys.first == 'pinned') {
          sortItems(event.values.first as Map<String, dynamic>?);
        }else if(event.keys.first == 'edited') {
          editPost(event.values.first as Map<String, dynamic>?);
        }else if(event.keys.first == 'deleted') {
          setState(() {
            lastDoc = null;
            _state = _state.reset();
          });
          _userController.getLikedPosts();
        }
      }
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
    return Consumer<UserController>(
      builder: (context, value, _) {
        if(value.loading) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.center,
            color: theme().primaryColor,
            child: Column(
              spacing: 24,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                    child: Image.asset(
                      'assets/images/logo_alt.png',
                      width: 100,
                      height: 100,
                    )
                ),
                CircularProgressIndicator(
                  color: theme().colorScheme.secondary,
                ),
              ],
            ),
          );
        }
        return Material(
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  pinned: true,
                  floating: true,
                  expandedHeight: 270,
                  scrolledUnderElevation: 0,
                  leadingWidth: 24,
                  title: Row(
                    spacing: 4,
                    children: [
                      Flexible(child: Text('@${currentUser?.username ?? ''}')),
                      if(currentUser?.verified == true)
                        const Icon(Icons.verified, color: Colors.blue, size: 16)
                    ],
                  ),
                  actions: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          lastDoc = null;
                          _state = _state.reset();
                        });
                        fetchUserInfo();
                        _userController.getLikedPosts();
                      },
                      icon: const Icon(Icons.refresh)
                    ),
                    IconButton(
                        onPressed: () => Navigator.pushNamed(context, '/user_profile_config'),
                        icon: const Icon(Icons.settings)
                    )
                  ],
                  flexibleSpace: SafeArea(
                    child: FlexibleSpaceBar(
                      background: Padding(
                        padding: const EdgeInsets.only(top: kToolbarHeight, left: 16, right: 16),
                        child: ProfileStatsRow(user: currentUser),
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
                              onTap: () => Navigator.pushNamed(context, '/user_feed', arguments: {"posts": _state.items, "index": index, "eventBus": widget.eventBus}),
                              child: CachedNetworkImage(
                                imageUrl: post.photosUrls?.firstOrNull ?? '',
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
                _LikedPosts(user: value.currentUser!)
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LikedPosts extends StatefulWidget {
  final MyUser user;
  const _LikedPosts({required this.user});

  @override
  State<_LikedPosts> createState() => _LikedPostsState();
}

class _LikedPostsState extends State<_LikedPosts> {

  Future<void> fetchUserPosts() async {
    if(widget.user.likedPosts == null) {
      await Provider.of<UserController>(context, listen: false).getLikedPosts();
    }
    setState(() {});
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) => fetchUserPosts());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserController>(
      builder: (context, value, _) {
        return CustomScrollView(
          slivers: [
            if(value.currentUser?.likedPosts?.isEmpty ?? true)
              const SliverFillRemaining(
                child: Center(
                  child: Text('Nenhum post curtido ainda...'),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final post = value.currentUser!.likedPosts![index];
                  return PostCard(post: post, isLiked: true);
                },
                  childCount: value.currentUser!.likedPosts?.length ?? 0,
                ),
              ),
          ],
        );
      },
    );
  }
}
