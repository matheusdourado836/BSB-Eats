import 'dart:io';
import 'package:bsb_eats/controller/social_media_controller.dart';
import 'package:bsb_eats/controller/user_controller.dart';
import 'package:bsb_eats/shared/model/avaliacao.dart';
import 'package:bsb_eats/shared/model/post.dart';
import 'package:bsb_eats/shared/model/restaurante.dart';
import 'package:bsb_eats/shared/model/user.dart';
import 'package:bsb_eats/shared/util/extensions.dart';
import 'package:bsb_eats/shared/widgets/image_cropper.dart';
import 'package:bsb_eats/shared/widgets/image_picker.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:uuid/uuid.dart';
import '../../shared/widgets/chip_text_field.dart';

class UploadScreen extends StatefulWidget {
  final List<String?> images;
  final EventBus? eventBus;
  const UploadScreen({super.key, required this.images, this.eventBus});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  late final _socialMediaController = Provider.of<SocialMediaController>(context, listen: false);
  late final _userController = Provider.of<UserController>(context, listen: false);
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _pessoasController = TextEditingController();
  final TextEditingController _restaurantController = TextEditingController();
  final TextEditingController _avaliacaoController = TextEditingController();
  Set<MyUser>? _selectedPeople;
  Set<Restaurante>? _selectedRestaurant;
  List<String?> images = [];
  final List<bool> _preco = [true, false, false, false, false];
  final List<bool> _atmosphere = [true, false, false, false, false];
  final List<bool> _food = [true, false, false, false, false];
  final List<bool> _service = [true, false, false, false, false];
  bool _loading = false;
  bool _postReview = true;

  Future<void> _doUpload() async {
    try{
      setState(() => _loading = true);
      final atmosphereValue = _atmosphere.indexOf(false);
      final foodValue = _food.indexOf(false);
      final priceValue = _preco.indexOf(false);
      final serviceValue = _service.indexOf(false);
      final avaliacao = Avaliacao(
        id: const Uuid().v4(),
        createdAt: DateTime.now(),
        userId: _userController.currentUser?.id,
        username: _userController.currentUser?.nome,
        text: _avaliacaoController.text,
        atmosphere: atmosphereValue == -1 ? 5 : atmosphereValue,
        food: foodValue == -1 ? 5 : foodValue,
        price: priceValue == -1 ? 5 : priceValue,
        service: serviceValue == -1 ? 5 : serviceValue
      );
      final post = Post(
        authorID: _userController.currentUser!.id,
        author: _userController.currentUser,
        caption: _captionController.text,
        avaliacao: avaliacao,
        photosUrls: images.nonNulls.toList(),
        taggedPeople: _selectedPeople?.map((e) => e.id!).toList(),
        taggedRestaurant: [_selectedRestaurant!.first.id!],
        restaurant: _selectedRestaurant!.first,
        qtdCurtidas: 0,
        qtdViews: 0,
        createdAt: DateTime.now(),
        isPinned: 0
      );
      await _socialMediaController.uploadPost(post, _postReview);
      widget.eventBus?.fire('Refresh');
      Navigator.pop(context);
      return;
    }catch(e) {
      showCustomSnackBar(child: Text('Erro ao fazer upload $e'));
    }finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildStars(List<bool> list, String label) {
    void setStars(int index) => setState(() {
      for (int i = 0; i < list.length; i++) {
        list[i] = i <= index;
      }
    });

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme().textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w500)),
          Row(
            children: [
              for(int i = 0; i < 5; i++)
                IconButton(
                  onPressed: () => setStars(i),
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    list[i] ? Icons.star : Icons.star_border,
                    color: Colors.yellow
                  )
                )
            ],
          )
        ],
      ),
    );
  }

  @override
  void initState() {
    images = List.from(widget.images);
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo post'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => showNewPostOpcoesBottomSheet(context, label: 'Adicionar mais imagens').then((res) {
              if(res is List<String?>) {
                setState(() => images.addAll(res.nonNulls.toList()));
              }
            }),
            icon: const Icon(Icons.add)
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 400,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          final image = images[index];
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                File(image!),
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.high,
                                alignment: Alignment.center,
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Row(
                                  spacing: 6,
                                  children: [
                                    IconButton.filled(
                                      onPressed: () => cropPostImage(context, image).then((res) {
                                        if(res != null) {
                                          setState(() {
                                            images[index] = res.path;
                                          });
                                        }
                                      }),
                                      icon: const Icon(Icons.crop_free_rounded)
                                    ),
                                    if(images.length > 1)
                                      IconButton.filled(
                                          onPressed: () => setState(() => images.removeAt(index)),
                                          icon: const Icon(Icons.delete, color: Colors.redAccent,)
                                      ),
                                  ],
                                )
                              ),
                            ],
                          );
                        },
                      ),
                      if(images.length > 1)
                        Positioned(
                          bottom: 10,
                          width: MediaQuery.of(context).size.width,
                          child: Center(
                            child: SmoothPageIndicator(
                              controller: _pageController,  // PageController
                              count: images.length,
                              effect:  WormEffect(
                                dotWidth: 10,
                                dotHeight: 10,
                                activeDotColor: theme().primaryColor
                              ),
                              onDotClicked: (index) {}
                            ),
                          ),
                        )
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _captionController,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    maxLength: 280,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Adicione uma legenda para o post...'
                    ),
                  ),
                ),
                const Divider(),
                const SizedBox(height: 16),
                ChipTextField(
                  controller: _pessoasController,
                  label: 'Marcar pessoas (opcional)',
                  hint: 'digite o nome das pessoas aqui...',
                  fetchSuggestions: (value) async => await _socialMediaController.fetchUsers(value.trim()),
                  selectedItems: _selectedPeople,
                  onItemAdded: (tag) => setState(() {
                    _selectedPeople ??= {};
                    _selectedPeople!.add(tag);
                  }),
                  onItemRemoved: (tag) => setState(() {
                    _selectedPeople?.remove(tag);
                  })
                ),
                ChipTextField(
                    controller: _restaurantController,
                    label: 'Marcar restaurante (obrigatório)',
                    hint: 'digite o nome do restaurante aqui...',
                    required: true,
                    enbled: _selectedRestaurant?.isEmpty ?? true,
                    fetchSuggestions: (value) async => await _socialMediaController.searchRestaurants(value.trim()),
                    selectedItems: _selectedRestaurant,
                    onItemAdded: (tag) => setState(() {
                      _selectedRestaurant ??= {};
                      _selectedRestaurant!.add(tag);
                    }),
                    onItemRemoved: (tag) => setState(() {
                      _selectedRestaurant?.remove(tag);
                    })
                ),
                Container(
                 padding: const EdgeInsets.all(8),
                 margin: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   borderRadius: BorderRadius.circular(8),
                   color: theme().primaryColor.withValues(alpha: .75)
                 ),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.stretch,
                   children: [
                     Text('Avaliação', style: theme().textTheme.titleLarge, textAlign: TextAlign.center),
                     const SizedBox(height: 16),
                     _buildStars(_preco, 'Preço'),
                     _buildStars(_atmosphere, 'Ambiente'),
                     _buildStars(_food, 'Comida'),
                     _buildStars(_service, 'Atendimento'),
                     const SizedBox(height: 32),
                     TextFormField(
                       controller: _avaliacaoController,
                       maxLines: null,
                       keyboardType: TextInputType.multiline,
                       maxLength: 280,
                       decoration: const InputDecoration(
                         hintText: 'Adicione uma avaliação para o restaurante...',
                         constraints: BoxConstraints(
                           maxHeight: 200,
                           minHeight: 50,
                         )
                       )
                     )
                   ],
                 ),
               ),
              Padding(
               padding: const EdgeInsets.only(left: 10.0),
               child: Row(
                 children: [
                   Transform.scale(
                     scale: .9,
                     child: Switch.adaptive(
                       value: _postReview,
                       onChanged: (newValue) => setState(() => _postReview = !_postReview)
                     ),
                   ),
                   Text('Publicar avaliação no restaurante')
                 ],
               ),
              ),
               const SizedBox(height: 24),
                if(_loading)
                  const Center(child: CircularProgressIndicator())
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ElevatedButton(
                      onPressed: () {
                        if(_formKey.currentState!.validate()) {
                          _doUpload();
                        }
                      },
                      child: Text('Publicar')
                    ),
                  ),
                const SizedBox(height: 12)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
