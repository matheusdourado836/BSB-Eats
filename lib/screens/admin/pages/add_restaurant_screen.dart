import 'package:bsb_eats/controller/user_controller.dart';
import 'package:bsb_eats/shared/model/user.dart';
import 'package:bsb_eats/shared/util/extensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controller/restaurant_controller.dart';
import '../../../shared/model/restaurante.dart';

class AddRestaurantScreen extends StatefulWidget {
  final MyUser user;
  const AddRestaurantScreen({super.key, required this.user});

  @override
  State<AddRestaurantScreen> createState() => _AddRestaurantScreenState();
}

class _AddRestaurantScreenState extends State<AddRestaurantScreen> {
  late final _restaurantController = Provider.of<RestaurantController>(context, listen: false);
  late final _userController = Provider.of<UserController>(context, listen: false);
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();
  final ValueNotifier<bool> _loading = ValueNotifier(false);

  Future<List<Restaurante>> _searchPlaceByText() async {
    if(_controller.text.isEmpty) return [];
    final restaurants = await _restaurantController.searchPlaceByText(query: _controller.text);
    _controller.clear();
    _focusNode.unfocus();
    return restaurants ?? [];
  }

  Future<void> setRestaurantThumb(Restaurante restaurant) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SelectThumbnailDialog(imageUrls: restaurant.listImages ?? []),
    );

    if (selected != null) {
      await _restaurantController.setRestaurantThumb(restaurantId: restaurant.id!, image: selected);
    }
  }

  Future<void> _addRestaurant(Restaurante? restaurante) async {
    if(await _restaurantController.checkIfRestaurantExists(restaurante?.id)) {
      showCustomSnackBar(child: Text('Este restaurante já está cadastrado!'));
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adicionar restaurante'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Selecione a região:'),
            DropdownButtonFormField<String>(
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface,
                overflow: TextOverflow.ellipsis
              ),
              hint: const Text("Região"),
              items: const [
                DropdownMenuItem(value: "aguas claras", child: Text("Águas Claras")),
                DropdownMenuItem(value: "arniqueira", child: Text("Arniqueira")),
                DropdownMenuItem(value: "guara", child: Text("Guará")),
                DropdownMenuItem(value: "taguatinga", child: Text("Taguatinga")),
                DropdownMenuItem(value: "areal", child: Text("Areal")),
                DropdownMenuItem(value: "lago norte", child: Text("Lago Norte")),
                DropdownMenuItem(value: "lago sul", child: Text("Lago Sul")),
                DropdownMenuItem(value: "asa sul", child: Text("Asa Sul")),
                DropdownMenuItem(value: "asa norte", child: Text("Asa Norte")),
                DropdownMenuItem(value: "sudoeste", child: Text("Sudoeste")),
                DropdownMenuItem(value: "ceilandia", child: Text("Ceilândia")),
                DropdownMenuItem(value: "planaltina", child: Text("Planaltina")),
                DropdownMenuItem(value: "sobradinho", child: Text("Sobradinho")),
                DropdownMenuItem(value: "samambaia", child: Text("Samambaia")),
                DropdownMenuItem(value: "riacho fundo", child: Text("Riacho Fundo")),
                DropdownMenuItem(value: "vicente pires", child: Text("Vicente Píres")),
              ],
              onChanged: (value) => restaurante?.regiao = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')
          ),
          ValueListenableBuilder(
            valueListenable: _loading,
            builder: (context, value, _) {
              if(value) {
                return const CircularProgressIndicator(strokeWidth: 1.5,);
              } else {
                return TextButton(
                  onPressed: () async {
                    if(restaurante != null) {
                      _loading.value = true;
                      await _restaurantController.addRestaurant(restaurante);
                      await setRestaurantThumb(restaurante);
                      _loading.value = false;
                      showCustomTopSnackBar(text: 'Restaurante adicionado com sucesso!');
                      setState(() {});
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Salvar')
                );
              }
            }
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
        ),
        actions: [
          IconButton(
            onPressed: () {
              if(_controller.text.length >= 3) {
                if(widget.user.adminSupremo != true && widget.user.qtdRestaurantsAdded == 5) {
                  showCustomSnackBar(child: Text('Limite de pesquisa atingido'));
                  Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                  return;
                }
                if(widget.user.adminSupremo != true) {
                  _userController.updateUserData({"qtdRestaurantsAdded": FieldValue.increment(1)});
                  widget.user.qtdRestaurantsAdded = (widget.user.qtdRestaurantsAdded ?? 0) + 1;
                }
                setState(() {});
              }
            },
            icon: const Icon(Icons.search)
          )
        ],
      ),
      body: FutureBuilder(
        future: _searchPlaceByText(),
        builder: (context, snapshot) {
          if(snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }else if(snapshot.hasError) {
            return Center(
              child: Text('Erro ao buscar restaurantes ${snapshot.error} ${snapshot.stackTrace}'),
            );
          }else if(snapshot.data?.isEmpty ?? true) {
            return const Center(
              child: Text('Nenhum restaurante encontrado'),
            );
          }else {
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: snapshot.data?.length ?? 0,
                    itemBuilder: (context, index) {
                      final restaurante = snapshot.data?[index];
                      return ListTile(
                        title: Text(restaurante?.nome ?? ''),
                        subtitle: Text(restaurante?.endereco ?? ''),
                        trailing: IconButton(
                          onPressed: () => _addRestaurant(restaurante),
                          icon: const Icon(Icons.add)
                        )
                      );
                    }
                  ),
                ),
                const SizedBox(height: 80)
              ],
            );
            }
          }
      ),
      floatingActionButton: widget.user.adminSupremo == true ? null : FloatingActionButton(
        onPressed: () {},
        tooltip: 'Pesquisas restantes',
        child: Text((5 - (widget.user.qtdRestaurantsAdded ?? 0)).toString()),
      )
    );
  }
}

class SelectThumbnailDialog extends StatefulWidget {
  final List<String> imageUrls;

  const SelectThumbnailDialog({super.key, required this.imageUrls});

  @override
  State<SelectThumbnailDialog> createState() => _SelectThumbnailDialogState();
}

class _SelectThumbnailDialogState extends State<SelectThumbnailDialog> {
  String? selectedImage;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Selecione a imagem principal'),
      content: SizedBox(
        width: double.maxFinite,
        child: GridView.builder(
          shrinkWrap: true,
          itemCount: widget.imageUrls.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,  // 3 colunas
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            final imageUrl = widget.imageUrls[index];
            final isSelected = selectedImage == imageUrl;

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedImage = imageUrl;
                });
              },
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey,
                        width: isSelected ? 3 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Positioned(
                      top: 4,
                      right: 4,
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.blue,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null), // cancelar
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: selectedImage != null
              ? () => Navigator.of(context).pop(selectedImage) // retorna a imagem selecionada
              : null,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}