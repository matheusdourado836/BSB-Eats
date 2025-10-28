import 'dart:io';

import 'package:bsb_eats/shared/model/post.dart';
import 'package:bsb_eats/shared/util/extensions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../controller/social_media_controller.dart';
import '../../shared/model/avaliacao.dart';
import '../../shared/model/restaurante.dart';
import '../../shared/model/user.dart';
import '../../shared/widgets/chip_text_field.dart';
import '../../shared/widgets/image_picker.dart';

class EditPostScreen extends StatefulWidget {
  final Post post;
  const EditPostScreen({super.key, required this.post});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  late final _socialMediaController = Provider.of<SocialMediaController>(context, listen: false);
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _pessoasController = TextEditingController();
  final TextEditingController _restauranteController = TextEditingController();
  final TextEditingController _avaliacaoController = TextEditingController();
  Set<MyUser>? _selectedPeople;
  Set<Restaurante>? _selectedRestaurants;
  List<bool> _preco = [true, false, false, false, false];
  List<bool> _atmosphere = [true, false, false, false, false];
  List<bool> _food = [true, false, false, false, false];
  List<bool> _service = [true, false, false, false, false];
  List<String> _imagesToDelete = [];
  List<String> _imagesToAdd = [];
  List<String?> images = [];
  bool _loading = false;

  Future<void> _saveChanges() async {
    try{
      setState(() => _loading = true);
      final atmosphereValue = _atmosphere.indexOf(false);
      final foodValue = _food.indexOf(false);
      final priceValue = _preco.indexOf(false);
      final serviceValue = _service.indexOf(false);
      final avaliacao = Avaliacao(
        id: widget.post.avaliacao?.id,
        createdAt: widget.post.avaliacao?.createdAt,
        userId: widget.post.author?.id,
        username: widget.post.author?.nome,
        text: _avaliacaoController.text,
        atmosphere: atmosphereValue == -1 ? 5 : atmosphereValue,
        food: foodValue == -1 ? 5 : foodValue,
        price: priceValue == -1 ? 5 : priceValue,
        service: serviceValue == -1 ? 5 : serviceValue
      );
      widget.post.avaliacao = avaliacao;
      await _socialMediaController.editPostData(
        widget.post,
        updateReview: true,
        imagesToDelete: _imagesToDelete,
        imagesToAdd: _imagesToAdd,
      );
      showCustomSnackBar(child: Text('Alterações salvas com sucesso!'));
      Navigator.pop(context, true);
    }catch(e) {
      showCustomSnackBar(child: Text('Não foi possível salvar suas alterações'));
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
                  style: IconButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
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
    _captionController.text = widget.post.caption ?? '';
    _selectedPeople = (widget.post.users?.isEmpty ?? true ? {} : widget.post.users!.toSet());
    _selectedRestaurants = widget.post.restaurant == null ? {} : {widget.post.restaurant!};
    _avaliacaoController.text = widget.post.avaliacao?.text ?? '';
    _preco = List.generate(5, (index) => index < (widget.post.avaliacao?.price ?? 1));
    _atmosphere = List.generate(5, (index) => index < (widget.post.avaliacao?.atmosphere ?? 1));
    _food = List.generate(5, (index) => index < (widget.post.avaliacao?.food ?? 1));
    _service = List.generate(5, (index) => index < (widget.post.avaliacao?.service ?? 1));
    images = List.from(widget.post.photosUrls ?? []);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar informações'),
        centerTitle: true,
        actions: [
          if(images.length < 10)
            IconButton(
              onPressed: () => showNewPostOpcoesBottomSheet(context, label: 'Adicionar mais imagens', limit: 10 - images.length).then((res) {
                if(res is List<String?>) {
                  if(res.length > (10 - images.length)) {
                    showCustomTopSnackBar(text: 'Você só pode adicionar mais ${(10 - images.length)} imagens');
                    return;
                  }
                  setState(() {
                    _imagesToAdd.addAll(res.nonNulls.toList());
                    images.addAll(res.nonNulls.toList());
                  });
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
                              if(image?.startsWith('https') ?? false)
                                Image.network(
                                  image ?? '',
                                  fit: BoxFit.cover,
                                )
                              else
                                Image.file(
                                  File(image!),
                                  fit: BoxFit.cover,
                                ),
                              if(images.length > 1)
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: IconButton.filled(
                                    onPressed: () {
                                      setState(() {
                                        _imagesToDelete.add(image!);
                                        _imagesToAdd.remove(image);
                                        images.removeAt(index);
                                      });
                                    },
                                    icon: const Icon(Icons.delete, color: Colors.redAccent)
                                  ),
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
                              onDotClicked: (index){
                              }
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
                    onChanged: (value) => widget.post.caption = value,
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
                      widget.post.taggedPeople = _selectedPeople!.map((e) => e.id!).toList();
                    }),
                    onItemRemoved: (tag) => setState(() {
                      _selectedPeople?.remove(tag);
                      widget.post.taggedPeople = _selectedPeople?.map((e) => e.id!).toList();
                    })
                ),
                ChipTextField(
                    controller: _restauranteController,
                    label: 'Marcar restaurante (obrigatório)',
                    hint: 'digite o nome do restaurante aqui...',
                    required: true,
                    enbled: _selectedRestaurants?.isEmpty ?? true,
                    fetchSuggestions: (value) async => await _socialMediaController.searchRestaurants(value.trim()),
                    selectedItems: _selectedRestaurants,
                    onItemAdded: (tag) => setState(() {
                      _selectedRestaurants ??= {};
                      _selectedRestaurants!.add(tag);
                      widget.post.taggedRestaurant = _selectedRestaurants!.map((e) => e.id!).toList();
                      widget.post.restaurant = tag;
                    }),
                    onItemRemoved: (tag) => setState(() {
                      _selectedRestaurants?.remove(tag);
                      widget.post.taggedRestaurant = _selectedRestaurants?.map((e) => e.id!).toList();
                      widget.post.restaurant = null;
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
                          //expands: true,
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
                const SizedBox(height: 24),
                if(_loading)
                  const Center(child: CircularProgressIndicator())
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ElevatedButton(
                        onPressed: () {
                          if(_formKey.currentState!.validate()) {
                            _saveChanges();
                          }
                        },
                        child: Text('Salvar')
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
