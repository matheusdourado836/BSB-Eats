import 'package:bsb_eats/controller/user_controller.dart';
import 'package:bsb_eats/screens/admin/widgets/delete_restaurant_dialog.dart';
import 'package:bsb_eats/shared/model/user.dart';
import 'package:bsb_eats/shared/util/extensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:flutter_svg/svg.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:provider/provider.dart';
import '../../../controller/restaurant_controller.dart';
import '../../../shared/model/enums.dart';
import '../../../shared/model/restaurante.dart';
import '../../../shared/widgets/card_list_skeleton.dart';
import '../../../shared/widgets/category_chip.dart';
import '../../../shared/widgets/post_page_error_widget.dart';
import '../../../shared/widgets/restaurante_card.dart';

class ManageRestaurantsScreen extends StatefulWidget {
  const ManageRestaurantsScreen({super.key});

  @override
  State<ManageRestaurantsScreen> createState() => _ManageRestaurantsScreenState();
}

class _ManageRestaurantsScreenState extends State<ManageRestaurantsScreen> {
  final _key = GlobalKey<ExpandableFabState>();
  late final RestaurantController _restaurantController = Provider.of<RestaurantController>(context, listen: false);
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  PagingState<DocumentSnapshot?, Restaurante> _state = PagingState();
  DocumentSnapshot? lastDoc;
  int selectedIndex = 0;
  String searchQuery = '';
  int _totalRestaurants = 0;

  void _fetchNextPage() async {
    if (_state.isLoading) return;

    setState(() {
      _state = _state.copyWith(isLoading: true, error: null);
    });

    try {
      final newKey = lastDoc;
      List<Restaurante> newItems = await _restaurantController.fetchRestaurants(
        startAfter: newKey,
        pageSize: 10,
        categoryIndex: selectedIndex == 0 ? null : selectedIndex,
        searchQuery: searchQuery.isEmpty ? null : searchQuery.toLowerCase().removerAcentos().trim(),
      );
      final isLastPage = newItems.isEmpty;

      setState(() {
        lastDoc = isLastPage ? null : _restaurantController.lastDoc;
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

  void updateFilteredRestaurantes() {
    setState(() {
      searchQuery = '';
      lastDoc = null;
      _state = _state.reset();
    });
    getRestaurantsCount();
  }

  Future<void> getRestaurantsCount() async {
    final count = await _restaurantController.getRestaurantCount(
      categoryIndex: selectedIndex == 0 ? null : selectedIndex,
      searchQuery: searchQuery.isEmpty ? null : searchQuery.toLowerCase().removerAcentos().trim(),
    );
    setState(() => _totalRestaurants = count);
  }

  Future<void> addRestaurantPage() async {
    final userController = Provider.of<UserController>(context, listen: false);
    MyUser? user;
    if((userController.currentUser?.adminSupremo != true)) {
      user = await userController.getUserById(userController.currentUser!.id!);
      if(user?.qtdRestaurantsAdded == 5) {
        showCustomTopSnackBar(text: 'Você já adicionou 5 restaurantes este mês.');
        return;
      }
    }
    Navigator.pushNamed(context, '/admin/manage_restaurants/add_restaurant', arguments: user ?? userController.currentUser!);
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async => await getRestaurantsCount());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gerenciar Restaurantes"),
        centerTitle: true,
      ),
      body: RefreshIndicator.adaptive(
        onRefresh: () async => updateFilteredRestaurantes(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      onSubmitted: (value) async {
                        if (value.length >= 3) {
                          setState(() {
                            searchQuery = value;
                            lastDoc = null;
                            _state = _state.reset();
                          });
                          SystemChannels.textInput.invokeMethod('TextInput.hide');
                          _focusNode.unfocus();
                          await getRestaurantsCount();
                        }
                      },
                      autofocus: false,
                      decoration: InputDecoration(
                        hintText: "Buscar restaurantes...",
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          onPressed: () => _controller.clear(),
                          icon: const Icon(Icons.clear),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      ),
                    ),
                  ),
                  IconButton.filled(
                    onPressed: () async {
                      if (_controller.text.length >= 3) {
                        setState(() {
                          searchQuery = _controller.text;
                          lastDoc = null;
                          _state = _state.reset();
                        });
                        SystemChannels.textInput.invokeMethod('TextInput.hide');
                        _focusNode.unfocus();
                        await getRestaurantsCount();
                      }
                    },
                    style: IconButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.search)
                  )
                ],
              ),
              SizedBox(
                height: 56,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: CategoriaTipo.values.length,
                  itemBuilder: (context, index) {
                    final category = CategoriaTipo.values[index];
                    bool selected = selectedIndex == category.code;
                    return Row(
                      children: [
                        CategoryChip(
                          label: category.description,
                          selected: selected,
                          onSelected: (v) {
                            setState(() {
                              selectedIndex = category.code;
                              updateFilteredRestaurantes();
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Todos os restaurantes',
                    style: theme().textTheme.labelLarge,
                  ),
                  if (_state.isLoading)
                    const CircularProgressIndicator(strokeWidth: 1.5)
                  else
                    Text(
                      '$_totalRestaurants resultado(s)',
                      style: theme().textTheme.labelMedium,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: PagedListView<DocumentSnapshot?, Restaurante>(
                  state: _state,
                  fetchNextPage: _fetchNextPage,
                  shrinkWrap: true,
                  builderDelegate: PagedChildBuilderDelegate<Restaurante>(
                    itemBuilder: (context, item, index) => Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton.filled(
                              onPressed: () => Navigator.pushNamed(context, '/admin/manage_restaurants/edit_restaurant', arguments: item).then((res) {
                                if(res == true) {
                                  showCustomTopSnackBar(text: 'Dados atualizados com sucesso!');
                                  updateFilteredRestaurantes();
                                }
                              }),
                              style: IconButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.edit),
                            ),
                            IconButton.filled(
                              onPressed: () => showDialog(
                                  context: context,
                                  builder: (context) => DeleteRestaurantDialog(restaurante: item)
                              ).then((res) {
                                if(res == true) {
                                  showCustomTopSnackBar(text: 'Restaurante excluído com sucesso!');
                                  updateFilteredRestaurantes();
                                }
                              }),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.delete),
                            )
                          ],
                        ),
                        RestauranteCard(restaurante: item),
                      ],
                    ),
                    firstPageProgressIndicatorBuilder: (context) => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: CardListSkeleton(),
                    ),
                    firstPageErrorIndicatorBuilder: (context) {
                      return FirstPageExceptionIndicator(
                          title: 'Erro ao carregar restaurantes',
                          message: 'Algo não saiu como esperado...',
                          onTryAgain: () => setState(() => _state = _state.reset())
                      );
                    },
                    noItemsFoundIndicatorBuilder: (context) => const Center(child: Text('Nenhum restaurante encontrado')),
                    newPageProgressIndicatorBuilder: (context) => const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: ExpandableFab(
        key: _key,
        openButtonBuilder: RotateFloatingActionButtonBuilder(
          child: const Icon(Icons.add),
          fabSize: ExpandableFabSize.regular,
        ),
        type: ExpandableFabType.up,
        childrenAnimation: ExpandableFabAnimation.none,
        distance: 70,
        overlayStyle: ExpandableFabOverlayStyle(
          color: Colors.white.withValues(alpha: 0.6),
        ),
        children: [
          FloatingActionButton.extended(
            heroTag: 'google',
            onPressed: addRestaurantPage,
            label: Text(
              'Adicionar do Google',
              style: theme().textTheme.labelMedium,
            ),
            icon: SvgPicture.asset('assets/icons/google.svg', width: 25, height: 25,),
          ),
          FloatingActionButton.extended(
            heroTag: 'manual',
            onPressed: () => Navigator.pushNamed(context, '/admin/manage_restaurants/create_restaurant').then((res) {
              if(res == true) {
                _key.currentState?.close();
                showCustomTopSnackBar(text: 'Restaurante adicionado com sucesso!');
                updateFilteredRestaurantes();
              }
            }),
            label: Text(
              'Adicionar manualmente',
              style: theme().textTheme.labelMedium,
            ),
            icon: const Icon(Icons.add),
          )
        ]
      )
    );
  }
}
