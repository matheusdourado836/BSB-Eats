import 'package:bsb_eats/shared/model/enums.dart';
import 'package:bsb_eats/shared/model/restaurante.dart';
import 'package:bsb_eats/shared/util/extensions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../controller/restaurant_controller.dart';
import '../../../shared/widgets/schedule_editor_widget.dart';
import '../../../shared/widgets/category_chip.dart';

class EditRestaurantScreen extends StatefulWidget {
  final Restaurante restaurant;
  const EditRestaurantScreen({
    super.key,
    required this.restaurant,
  });

  @override
  State<EditRestaurantScreen> createState() => _EditRestaurantScreenState();
}

class _EditRestaurantScreenState extends State<EditRestaurantScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _siteController;
  late TextEditingController _ratingController;
  late TextEditingController _reviewsCountController;

  List<String> _photos = [];
  final List<String> _photosToRemove = [];
  String? _thumb;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.restaurant.nome ?? '');
    _addressController = TextEditingController(text: widget.restaurant.endereco ?? '');
    _phoneController = TextEditingController(text: widget.restaurant.phone ?? '');
    _siteController = TextEditingController(text: widget.restaurant.websiteUri ?? '');
    _ratingController = TextEditingController(text: widget.restaurant.avaliacao?.toString());
    _reviewsCountController = TextEditingController(text: widget.restaurant.userRatingCount?.toString());

    _photos = List.from(widget.restaurant.listImages ?? []);
    _thumb = widget.restaurant.image;
    if(widget.restaurant.currentOpeningHours?.weekdayDescriptions?.isEmpty ?? true) {
      widget.restaurant.currentOpeningHours = CurrentOpeningHours.init();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _siteController.dispose();
    _ratingController.dispose();
    _reviewsCountController.dispose();
    super.dispose();
  }

  void _removePhoto(String url) {
    setState(() {
      _photos.remove(url);
      _photosToRemove.add(url);
      if (_thumb == url) {
        _thumb = _photos.last;
      }
    });
  }

  void _setThumb(String url) {
    setState(() {
      _thumb = url;
    });
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if(_thumb == null) {
      showCustomSnackBar(child: const Text("Selecione uma foto principal para o restaurante"));
      return;
    }

    widget.restaurant.image = _thumb;

    if(widget.restaurant.currentOpeningHours?.weekdayDescriptions?.isEmpty ?? true) {
      showCustomSnackBar(child: const Text('Preencha os horários de funcionamento do restaurante'));
      return;
    }

    final restaurantController = Provider.of<RestaurantController>(context, listen: false);
    await restaurantController.updateRestaurantData(widget.restaurant.id!, widget.restaurant.toJson());
    if(_photosToRemove.isNotEmpty) {
      await restaurantController.removeImages(widget.restaurant.id!, _photosToRemove);
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Restaurante"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveChanges,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 24,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Nome"),
                onChanged: (v) => widget.restaurant.nome = v,
                validator: (v) => v!.isEmpty ? "Digite o nome" : null,
              ),
              Row(
                spacing: 8,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _addressController,
                      onChanged: (v) => widget.restaurant.endereco = v,
                      decoration: const InputDecoration(labelText: "Endereço"),
                    ),
                  ),
                  SizedBox(
                    height: 40,
                    width: 130,
                    child: DropdownButtonFormField<String>(
                      value: widget.restaurant.regiao,
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
                      onChanged: (value) => widget.restaurant.regiao = value,
                    ),
                  )
                ],
              ),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                onChanged: (v) => widget.restaurant.phone = v,
                decoration: const InputDecoration(labelText: "Telefone"),
              ),
              TextFormField(
                controller: _siteController,
                onChanged: (v) => widget.restaurant.websiteUri = v,
                decoration: const InputDecoration(labelText: "Site"),
              ),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                runSpacing: 24,
                children: [
                  SizedBox(
                    width: 90,
                    height: 40,
                    child: TextFormField(
                      controller: _ratingController,
                      onChanged: (v) => widget.restaurant.avaliacao = double.tryParse(v),
                      decoration: const InputDecoration(labelText: "Avaliação"),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(
                    width: 118,
                    height: 40,
                    child: TextFormField(
                      controller: _reviewsCountController,
                      onChanged: (v) => widget.restaurant.userRatingCount = int.tryParse(v),
                      decoration: const InputDecoration(labelText: "Qtd Avaliações"),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(
                    height: 40,
                    width: 165,
                    child: DropdownButtonFormField<String>(
                      value: widget.restaurant.categoria?.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface,
                        overflow: TextOverflow.ellipsis
                      ),
                      hint: const Text("Categoria"),
                      items: CategoriaTipo.values.where((c) => c.name != 'all').map((c) => DropdownMenuItem(value: c.name, child: Text(c.description))).toList(),
                      onChanged: (value) => widget.restaurant.categoria = CategoriaTipo.valueOf(value),
                    ),
                  )
                ],
              ),
              const Text("Categoria Principal*", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                children: CategoriaTipo.values.map((c) => CategoryChip(
                  label: c.description,
                  selected: c.name == widget.restaurant.categoria?.name,
                  onSelected: (value) {
                    setState(() => widget.restaurant.categoria = c);
                  }
                )).toList(),
              ),
              const Text("Categorias Secundárias", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                children: CategoriaTipo.values.where((c) => c != widget.restaurant.categoria && c != CategoriaTipo.todos).map((c) => CategoryChip(
                  label: c.description,
                  selected: widget.restaurant.categorias?.contains(c) ?? false,
                  onSelected: (value) {
                    if(value) {
                      setState(() {
                        widget.restaurant.categorias ??= [];
                        widget.restaurant.categorias!.add(c);
                      });
                    }else {
                      setState(() {
                        widget.restaurant.categorias ??= [];
                        widget.restaurant.categorias!.remove(c);
                      });
                    }
                  }
                )).toList(),
              ),
              const Text("Horário de funcionamento*", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ScheduleEditor(weekdayDescriptions: widget.restaurant.currentOpeningHours!.weekdayDescriptions!),
              const Text("Foto Principal", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                width: double.infinity,
                height: 250,
                color: theme().primaryColor,
                alignment: Alignment.center,
                child: Container(
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(
                        _thumb ?? '',
                        errorListener: (e) => SizedBox()
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const Text("Fotos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _photos.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemBuilder: (_, i) {
                  final url = _photos[i];
                  return Stack(
                    children: [
                      GestureDetector(
                        onTap: () => _setThumb(url),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _thumb == url ? Colors.green : Colors.transparent,
                              width: 5,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: CachedNetworkImageProvider(url),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Transform.scale(
                          scale: .7,
                          child: IconButton.filled(
                            icon: const Icon(Icons.delete),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.red,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: const EdgeInsets.all(8),
                              iconSize: 22,
                            ),
                            onPressed: () => _removePhoto(url),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}