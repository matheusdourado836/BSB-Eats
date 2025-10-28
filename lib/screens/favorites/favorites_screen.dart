import 'package:bsb_eats/controller/auth_controller.dart';
import 'package:bsb_eats/controller/restaurant_controller.dart';
import 'package:bsb_eats/controller/user_controller.dart';
import 'package:bsb_eats/shared/model/enums.dart';
import 'package:bsb_eats/shared/model/favorite.dart';
import 'package:bsb_eats/shared/model/restaurante.dart';
import 'package:bsb_eats/shared/util/extensions.dart';
import 'package:bsb_eats/shared/widgets/user_avatar_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> with TickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this);
  late final userController = Provider.of<UserController>(context, listen: false);
  late final restauranteController = Provider.of<RestaurantController>(context, listen: false);
  List<VisitedRestaurant> _visitedRestaurants = [];

  Future<void> _loadData() async {
    await userController.getFavorites();
    _visitedRestaurants = await userController.getVisitedRestaurants();
    setState(() {});
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurantes'),
        centerTitle: true,
      ),
      body: RefreshIndicator.adaptive(
        onRefresh: _loadData,
        child: Column(
          children: [
            Container(
              color: Theme.of(context).canvasColor,
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Favoritos'),
                  Tab(text: 'Já visitados')
                ],
              ),
            ),
            Flexible(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _Favorites(),
                  _Visited(
                    visitedRestaurants: _visitedRestaurants,
                    onRefresh: userController.getVisitedRestaurants,
                  )
                ]
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _Favorites extends StatefulWidget {
  const _Favorites();

  @override
  State<_Favorites> createState() => _FavoritesState();
}

class _FavoritesState extends State<_Favorites> {
  late final authController = Provider.of<AuthController>(context, listen: false);
  List<Favorite> _filterefFavorites = [];

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserController, RestaurantController>(
      builder: (context, userC, rest, _) {
        if(userC.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if(userC.currentUser!.favorites?.isEmpty ?? true) {
          return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Nenhum restaurante favorito encontrado'),
                  IconButton(
                      onPressed: () => userC.getFavorites(),
                      icon: const Icon(Icons.refresh_rounded)
                  )
                ],
              )
          );
        }

        _filterefFavorites = userC.currentUser!.favorites ?? [];

        return ListView.builder(
          padding: EdgeInsets.all(12),
          itemCount: _filterefFavorites.length,
          itemBuilder: (context, index) {
            final favorite = _filterefFavorites[index];
            return Card(
              elevation: 1,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                onTap: () => Navigator.pushNamed(context, '/restaurant_details', arguments: favorite.placeId),
                leading: CircleAvatar(
                    backgroundImage: CachedNetworkImageProvider(favorite.photoUrl ?? ''),
                    radius: 24,
                    onBackgroundImageError: (exception, stackTrace) => const NoBgUser()
                ),
                title: Text(favorite.name ?? 'N/A'),
                subtitle: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(CategoriaTipo.valueOf(favorite.categoriaIndex)?.description ?? 'N/A'),
                    Row(
                      spacing: 2,
                      children: [
                        Text(favorite.rating.toString()),
                        const Icon(Icons.star, color: Colors.amber, size: 16)
                      ],
                    )
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded),
              ),
            );
          },
        );
      },
    );
  }
}

class _Visited extends StatefulWidget {
  final List<VisitedRestaurant> visitedRestaurants;
  final Future<List<VisitedRestaurant>> Function() onRefresh;
  const _Visited({required this.visitedRestaurants, required this.onRefresh});

  @override
  State<_Visited> createState() => _VisitedState();
}

class _VisitedState extends State<_Visited> {
  List<VisitedRestaurant> _visitedRestaurants = [];
  bool _loading = false;

  Future<void> _onRefresh() async {
    setState(() => _loading = true);
    _visitedRestaurants = await widget.onRefresh();
    setState(() {
      _visitedRestaurants;
      _loading = false;
    });
  }

  Future<void> _showDeleteBottomSheet(String? restaurantId) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar ação'),
        content: Text('Deseja remover este restaurante da lista de visitados?'),
        actions: [
          TextButton(
            onPressed: () async {
              final userController = Provider.of<UserController>(context, listen: false);
              await userController.setVisitedRestaurant(restaurantId: restaurantId, value: false);
              Navigator.pop(context);
              showCustomSnackBar(
                child: const Text('Restaurante removido com sucesso!')
              );
              _onRefresh();
            },
            child: const Text(
              'Remover',
              style: TextStyle(color: Colors.red),
            )
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      )
    );
  }

  @override
  void initState() {
    _visitedRestaurants = widget.visitedRestaurants;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator.adaptive(
      onRefresh: _onRefresh,
      child: Consumer<RestaurantController>(
        builder: (context, rest, _) {
          if(_loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if(_visitedRestaurants.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Nenhum restaurante visitado ainda'),
                  IconButton(
                    onPressed: _onRefresh,
                    icon: const Icon(Icons.refresh_rounded)
                  )
                ],
              )
            );
          }

          return Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: ListView.builder(
              itemCount: _visitedRestaurants.length,
              itemBuilder: (context, index) {
                final visited = _visitedRestaurants[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(' visitado ${visited.visitedAt?.toFriendlyDate().toLowerCase() ?? ''}', style: const TextStyle(fontSize: 14)),
                      Card(
                        elevation: 1,
                        child: ListTile(
                          onTap: () => Navigator.pushNamed(context, '/restaurant_details', arguments: visited.restaurante?.id),
                          leading: CircleAvatar(
                            backgroundImage: CachedNetworkImageProvider(visited.restaurante?.image ?? ''),
                            radius: 24,
                            onBackgroundImageError: (exception, stackTrace) => const NoBgUser()
                          ),
                          horizontalTitleGap: 8,
                          title: Text(visited.restaurante?.nome ?? 'N/A'),
                          subtitle: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(visited.restaurante?.categoria?.description ?? 'N/A'),
                              Row(
                                spacing: 2,
                                children: [
                                  Text(visited.restaurante?.avaliacao?.toString() ?? '0.0'),
                                  const Icon(Icons.star, color: Colors.amber, size: 16)
                                ],
                              )
                            ],
                          ),
                          trailing: IconButton.filled(
                            onPressed: () => _showDeleteBottomSheet(visited.restaurante?.id),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6)
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                            iconSize: 18,
                            icon: const Icon(Icons.delete)
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
