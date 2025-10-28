import 'package:bsb_eats/shared/model/restaurante.dart';
import 'package:bsb_eats/shared/util/extensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:provider/provider.dart';
import '../../../controller/restaurant_controller.dart';
import '../../../service/firebase_analytics_service.dart';
import '../../../shared/model/enums.dart';
import '../../../shared/widgets/card_list_skeleton.dart';
import '../../../shared/widgets/category_chip.dart';
import '../../../shared/widgets/restaurante_card.dart';
import '../widgets/guest_app_bar.dart';

class GuestHomeTab extends StatefulWidget {
  const GuestHomeTab({super.key});

  @override
  State<GuestHomeTab> createState() => _GuestHomeTabState();
}

class _GuestHomeTabState extends State<GuestHomeTab> {
  late final RestaurantController _restaurantController = Provider.of<RestaurantController>(context, listen: false);
  DocumentSnapshot? lastDoc;
  int selectedIndex = 0;
  String? selectedRegion;
  String searchQuery = '';
  int _totalRestaurants = 0;

  PagingState<DocumentSnapshot?, Restaurante> _state = PagingState();

  void _fetchNextPage() async {
    if (_state.isLoading) return;

    setState(() {
      _state = _state.copyWith(isLoading: true, error: null);
    });

    try {
      final newKey = lastDoc;
      List<Restaurante> newItems = await _restaurantController.fetchRestaurants(
        startAfter: newKey,
        pageSize: 6,
        categoryIndex: selectedIndex == 0 ? null : selectedIndex,
        searchQuery: searchQuery.isEmpty ? null : searchQuery.toLowerCase().removerAcentos().trim(),
        region: selectedRegion == 'tudo' ? null : selectedRegion,
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

  Future<void> updateFilteredRestaurantes() async {
    searchQuery = '';
    lastDoc = null;
    _state = _state.reset();
    await getRestaurantsCount();
    setState(() {});
  }

  Future<void> getRestaurantsCount() async {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    final count = await _restaurantController.getRestaurantCount(
      categoryIndex: selectedIndex == 0 ? null : selectedIndex,
      searchQuery: searchQuery.isEmpty ? null : searchQuery.toLowerCase().removerAcentos().trim(),
      region: selectedRegion == 'tudo' ? null : selectedRegion,
    );
    _totalRestaurants = count;
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) => getRestaurantsCount());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GuestHomeAppBar(
        onSearch: (value) async {
          searchQuery = value!;
          lastDoc = null;
          _state = _state.reset();
          await getRestaurantsCount();
          setState(() {});
          if(selectedRegion != null) {
            AnalyticsService.instance.logEvent(
              name: 'region_selected',
              parameters: {
                'created_at': DateTime.now().toIso8601String(),
                'username': 'guest-${DateTime.now().toIso8601String()}',
                'region': selectedRegion!
              }
            );
          }
        },
        onChanged: (value) => setState(() => selectedRegion = value),
      ),
      body: Consumer<RestaurantController>(
        builder: (context, value, child) {
          return RefreshIndicator.adaptive(
            onRefresh: () async => updateFilteredRestaurantes(),
            child: CustomScrollView(
              slivers: [
                // 🔹 Cabeçalho com filtros
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Explore por categoria',
                          style: theme()
                              .textTheme
                              .labelLarge
                              ?.copyWith(fontSize: 22),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Encontre exatamente o que você está procurando',
                          style: theme().textTheme.labelMedium,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 56,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: CategoriaTipo.values.where((c) => c.name != 'Restaurant').length,
                            itemBuilder: (context, index) {
                              final category = CategoriaTipo.values[index];
                              bool selected = selectedIndex == category.code;
                              return Row(
                                children: [
                                  CategoryChip(
                                    label: category.description,
                                    selected: selected,
                                    onSelected: (v) {
                                      selectedIndex = category.code;
                                      updateFilteredRestaurantes();
                                      AnalyticsService.instance.logEvent(
                                        name: 'category_selected',
                                        parameters: {
                                          'created_at': DateTime.now().toIso8601String(),
                                          'username': 'guest-${DateTime.now().toIso8601String()}',
                                          'name': category.name
                                        }
                                      );
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
                            Text(
                              '$_totalRestaurants resultado(s)',
                              style: theme().textTheme.labelMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                PagedSliverList<DocumentSnapshot?, Restaurante>(
                  state: _state,
                  fetchNextPage: _fetchNextPage,
                  shrinkWrapFirstPageIndicators: true,
                  builderDelegate: PagedChildBuilderDelegate<Restaurante>(
                    itemBuilder: (context, item, index) => RestauranteCard(restaurante: item),
                    firstPageProgressIndicatorBuilder: (context) => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: CardListSkeleton(),
                    ),
                    firstPageErrorIndicatorBuilder: (context) {
                      return FirstPageExceptionIndicator(
                          title: 'Erro ao carregar restaurantes',
                          message: 'Algo não saiu como esperado...',
                          onTryAgain: () => updateFilteredRestaurantes()
                      );
                    },
                    noItemsFoundIndicatorBuilder: (context) => const Center(child: Text('Nenhum restaurante encontrado')),
                    newPageProgressIndicatorBuilder: (context) => const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Basic layout for indicating that an exception occurred.
class FirstPageExceptionIndicator extends StatelessWidget {
  const FirstPageExceptionIndicator({
    required this.title,
    this.message,
    this.onTryAgain,
    super.key,
  });

  final String title;
  final String? message;
  final VoidCallback? onTryAgain;

  @override
  Widget build(BuildContext context) {
    final message = this.message;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 32,
          horizontal: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (message != null) ...[
              const SizedBox(
                height: 16,
              ),
              Text(
                message,
                textAlign: TextAlign.center,
              ),
            ],
            if (onTryAgain != null) ...[
              const SizedBox(
                height: 48,
              ),
              SizedBox(
                width: 200,
                child: ElevatedButton.icon(
                  onPressed: onTryAgain,
                  icon: const Icon(Icons.refresh),
                  label: const Text(
                    'Tentar novamente',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}