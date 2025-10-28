import 'package:bsb_eats/controller/user_controller.dart';
import 'package:bsb_eats/screens/details/widgets/comment_section.dart';
import 'package:bsb_eats/shared/widgets/ask_to_login_dialog.dart';
import 'package:bsb_eats/shared/widgets/category_chip.dart';
import 'package:bsb_eats/shared/model/avaliacao.dart';
import 'package:bsb_eats/shared/model/enums.dart';
import 'package:bsb_eats/shared/model/favorite.dart';
import 'package:bsb_eats/shared/model/restaurante.dart';
import 'package:bsb_eats/shared/model/review.dart';
import 'package:bsb_eats/shared/util/extensions.dart';
import 'package:bsb_eats/shared/widgets/zoom_image_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controller/restaurant_controller.dart';
import '../../service/firebase_analytics_service.dart';
import '../../shared/model/weekday.dart';

class RestaurantDetailsScreen extends StatefulWidget {
  final String? placeId;
  const RestaurantDetailsScreen({super.key, required this.placeId});

  @override
  State<RestaurantDetailsScreen> createState() => _RestaurantDetailsScreenState();
}

class _RestaurantDetailsScreenState extends State<RestaurantDetailsScreen> {
  late final _restaurantController = Provider.of<RestaurantController>(context, listen: false);
  late final _userController = Provider.of<UserController>(context, listen: false);
  WeeklyOpeningHours? _weeklyOpeningHours;
  bool _isFollowing = false;
  bool difference = false;
  List<CategoriaTipo> foodTypes = [];

  Widget _commentItem(dynamic comment) {
    if(comment is Review) {
      return Column(
          spacing: 4,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: 4,
              children: [
                Flexible(
                  child: Text(
                    comment.authorAttribution?.displayName ?? 'N/A',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      comment.rating ?? 0,
                          (index) => const Icon(Icons.star, color: Colors.amber, size: 16),
                    )
                )
              ],
            ),
            Expanded(
                child: Text(comment.text?.text ?? 'N/A', maxLines: 2, overflow: TextOverflow.ellipsis,)
            )
          ]
      );
    }

    final appReview = comment as Avaliacao?;
    final preco = appReview?.price ?? 1;
    final atmosphere = appReview?.atmosphere ?? 1;
    final food = appReview?.food ?? 1;
    final service = appReview?.service ?? 1;
    final average = (preco + atmosphere + food + service) / 4;

    return Column(
      spacing: 4,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Row(
              spacing: 4,
              children: [
                Text(
                  appReview?.username ?? 'N/A',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    average.toInt(),
                    (index) => const Icon(Icons.star, color: Colors.amber, size: 16),
                  )
                )
              ],
            ),
            Transform.scale(
              scale: .8,
              child: Chip(
                backgroundColor: theme().primaryColor,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: EdgeInsets.fromLTRB(8, 4, 4, 4),
                label: Row(
                  spacing: 4,
                  children: [
                    Text(
                      'App',
                      style: theme().textTheme.labelSmall?.copyWith(fontSize: 14),
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
                )
              ),
            )
          ],
        ),
        Expanded(
            child: Text(appReview?.text ?? 'N/A', maxLines: 2, overflow: TextOverflow.ellipsis,)
        )
      ]
    );
  }

  Future<void> toggleFavorite(Restaurante restaurante) async {
    if(_userController.currentUser == null) {
      showDialog(context: context, builder: (context) => AskToLoginDialog());
      return;
    }
    try{
      final favorite = Favorite(
        placeId: restaurante.id,
        name: restaurante.nome,
        photoUrl: restaurante.image,
        rating: restaurante.avaliacao,
        categoriaIndex: restaurante.categoria?.code,
      );
      await _userController.toggleFavorite(_isFollowing, favorite);
      showCustomSnackBar(child: Text('${restaurante.nome} ${_isFollowing ? 'removido dos' : 'adicionado aos'} favoritos'));
      setState(() => _isFollowing = !_isFollowing);
    }catch(e) {
      showCustomSnackBar(child: Text('Não foi possível adicionar aos favoritos'));
    }
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _restaurantController.fetchPlaceDetails(widget.placeId).whenComplete(() {
        foodTypes = (_restaurantController.restaurante?.categorias ?? []).where((c) => c.code != 19).toList();
        _weeklyOpeningHours = WeeklyOpeningHours.fromWeekdayDescriptions(_restaurantController.restaurante?.currentOpeningHours?.weekdayDescriptions ?? []);
        final now = DateTime.now();
        final minutes = now.hour * 60 + now.minute;
        difference = _weeklyOpeningHours?.byWeekday[now.weekday]?.where((t) => t.difference(minutes) > 0 && t.difference(minutes) < 60).isNotEmpty ?? false;
        final followingIds = _userController.currentUser?.favorites?.map((e) => e.placeId).toList() ?? [];
        setState(() => _isFollowing = followingIds.contains(_restaurantController.restaurante?.id));
        AnalyticsService.instance.logEvent(
          name: 'screen_view',
          parameters: {
            'created_at': DateTime.now().toIso8601String(),
            'screen_name': 'restaurant_details',
            'name': _restaurantController.restaurante!.nome!,
            'user_id': _userController.currentUser?.id ?? '',
            'username': _userController.currentUser?.nome ?? ''
          }
        );
      }),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          if(_userController.currentUser?.visitedPlaces?.contains(widget.placeId) ?? false)
            Chip(
              backgroundColor: theme().primaryColor,
              side: BorderSide.none,
              label: Row(
                spacing: 6,
                children: [
                  Text('Já visitado', style: theme().textTheme.labelSmall?.copyWith(fontSize: 14)),
                  SvgPicture.asset(
                    'assets/icons/thumbs-up.svg',
                    width: 24,
                    height: 24,
                  ),
                ],
              ),
            ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              share(
                title: 'Compartilhar restaurante',
                text: 'Olha que incrível este restaurante que encontrei!\n${dotenv.get('BSB_EATS_FRIENDLY_BASE_URL')}/restaurant/${widget.placeId}/details'
              ).then((res) {
                if(res == ShareResultStatus.success) {
                  final name = _restaurantController.restaurante!.nome!;
                  AnalyticsService.instance.logEvent(
                    name: 'restaurant_shared',
                    parameters: {
                      'created_at': DateTime.now().toIso8601String(),
                      'user_id': _userController.currentUser!.id!,
                      'username': _userController.currentUser!.nome!,
                      'name': name
                    }
                  );
                }
              });
            },
            icon: const Icon(Icons.share),
          )
        ],
      ),
      body: Consumer<RestaurantController>(
        builder: (context, value, _) {
          if (value.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final restaurant = value.restaurante;
          if (restaurant == null) {
            return const Center(child: Text('Restaurante não encontrado'));
          }

          return SelectionArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    ZoomImageWidget(
                      profilePhotoUrl: restaurant.image,
                      child: CircleAvatar(
                        radius: 48,
                        backgroundImage: restaurant.image?.isEmpty ?? true
                          ? null
                          : CachedNetworkImageProvider(restaurant.image!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            restaurant.nome ?? 'sem nome',
                            style: theme().textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            restaurant.categoria?.description ?? 'sem categoria',
                            style: theme().textTheme.labelMedium,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                (restaurant.avaliacao ?? 0.0).toStringAsFixed(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text("• ${restaurant.userRatingCount ?? 0} avaliações",
                                  style: const TextStyle(color: Colors.grey)
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFollowing ? Colors.grey : theme().primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => toggleFavorite(value.restaurante!),
                        icon: _isFollowing ? const Icon(Icons.favorite) : const Icon(Icons.favorite_border),
                        label: Text(_isFollowing ? "Seguindo" : "Seguir", style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => _restaurantController.openMaps(
                          lat: restaurant.location?.lat,
                          long: restaurant.location?.long,
                          restaurantId: restaurant.id,
                        ),
                        icon: const Icon(Icons.near_me),
                        label: const Text("Ir agora!", style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  spacing: 4,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, size: 20, color: Colors.grey),
                    Expanded(child: Text(restaurant.endereco ?? 'sem endereço')),
                  ],
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ExpandablePanel(
                      header: Row(
                        spacing: 6,
                        children: [
                          const Icon(Icons.access_time, size: 18, color: Colors.grey),
                          Expanded(child: Text('Horários de funcionamento')),
                        ],
                      ),
                      collapsed: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 4,
                        children: [
                          Text(
                            'Hoje - ${restaurant.currentOpeningHours?.getTodayDate()}',
                            style: theme().textTheme.titleMedium,
                          ),
                          if(difference)
                            const Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              spacing: 4,
                              children: [
                                Text('Fecha em breve'),
                                Icon(
                                    Icons.warning_rounded,
                                    color: Colors.amber
                                )
                              ],
                            )
                        ],
                      ),
                      expanded: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: restaurant.currentOpeningHours?.weekdayDescriptions?.length ?? 0,
                        itemBuilder: (context, index) {
                          final dado = restaurant.currentOpeningHours?.parseHorario().nonNulls.toList()[index];
                          final day = dado!["dia"];
                          final horario = dado["horarios"];
                          final isToday = DateTime.now().weekday == index + 1;
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                            child: ListTile(
                              tileColor: isToday ? theme().primaryColor.withValues(alpha: 0.5) : null,
                              titleTextStyle: isToday ? theme().textTheme.labelSmall?.copyWith(fontSize: 18) : null,
                              subtitleTextStyle: isToday ? theme().textTheme.labelSmall?.copyWith(fontSize: 14) : null,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              title: Text(day, style: TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ...horario.map((e) => Text(e)).toList(),
                                ]
                              ),
                            ),
                          );
                        },
                      )
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 18, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(restaurant.phone ?? 'sem telefone')
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if(restaurant.websiteUri?.isNotEmpty ?? false)
                  Row(
                    children: [
                      const Icon(Icons.public, size: 18, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: InkWell(
                          onTap: () => _launchUrl(restaurant.websiteUri!),
                          child: Text(
                            restaurant.websiteUri!,
                            style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                if(foodTypes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Column(
                      spacing: 4,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Serve:', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),),
                        Wrap(
                          spacing: 6,
                          children: foodTypes.where((c) => c.name != 'Restaurant').map((c) => CategoryChip(
                            label: c.description,
                            selected: true,
                            onSelected: (v) {},
                          )).toList(),
                        )
                      ],
                    ),
                  ),
                Container(
                  alignment: Alignment.centerLeft,
                  margin: const EdgeInsets.only(top: 16, bottom: 32),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: restaurant.abertoAgora ?? false
                          ? Colors.green
                          : Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      restaurant.abertoAgora ?? false ? "Aberto agora" : "Fechado",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                if([...restaurant.appReviews ?? [], ...restaurant.reviews ?? []].isNotEmpty)
                  Column(
                    spacing: 16,
                    children: [
                      InkWell(
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          showDragHandle: true,
                          useRootNavigator: true,
                          enableDrag: false,
                          builder: (context) => CommentSection(
                            comments: [...restaurant.appReviews ?? [], ...restaurant.reviews ?? []],
                            restaurantId: restaurant.id,
                          )
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Avaliações dos clientes",
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded)
                          ],
                        ),
                      ),
                      CarouselSlider(
                        options: CarouselOptions(
                          autoPlay: true,
                          padEnds: false,
                          enableInfiniteScroll: false,
                          viewportFraction: 1,
                          height: 100
                        ),
                        items: [...restaurant.appReviews ?? [], ...restaurant.reviews ?? []].map((comment) {
                          return _commentItem(comment);
                        }).toList(),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  "Fotos do Google",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if(restaurant.listImages?.isEmpty ?? true)
                  Container(
                    height: 200,
                    alignment: Alignment.center,
                    child: const Text("Nenhuma foto encontrada...")
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 1,
                      mainAxisSpacing: 1,
                      childAspectRatio: 12/14,
                    ),
                    itemCount: restaurant.listImages!.length,
                    itemBuilder: (context, index) {
                      final image = restaurant.listImages?[index];
                      return ZoomImagesListWidget(
                        images: restaurant.listImages?.nonNulls.toList(),
                        imageIndex: index,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
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
                          ),
                        ),
                      );
                    }
                  ),
                // PagedGridView(
                //   pagingController: _pagingController,
                //   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                //     crossAxisCount: 3,
                //     crossAxisSpacing: 8,
                //     mainAxisSpacing: 8,
                //   ),
                //   shrinkWrap: true,
                //   physics: const NeverScrollableScrollPhysics(),
                //   builderDelegate: PagedChildBuilderDelegate<String?>(
                //     itemBuilder: (context, item, index) {
                //       return ZoomImagesListWidget(
                //         images: restaurant.listImages?.nonNulls.map((e) => e.name ?? '').toList() ?? [],
                //         imageIndex: index,
                //         child: ClipRRect(
                //           borderRadius: BorderRadius.circular(8),
                //           child: Image.network(
                //             item ?? '',
                //             fit: BoxFit.cover,
                //           ),
                //         ),
                //       );
                //     },
                //   ),
                // ),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }
}
