import 'dart:io';
import 'package:bsb_eats/shared/widgets/category_chip.dart';
import 'package:bsb_eats/shared/model/enums.dart';
import 'package:bsb_eats/shared/model/restaurante.dart';
import 'package:bsb_eats/shared/model/weekday.dart';
import 'package:bsb_eats/shared/util/extensions.dart';
import 'package:bsb_eats/shared/widgets/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../controller/restaurant_controller.dart';
import '../../../shared/util/consts.dart';
import '../../../shared/widgets/schedule_editor_widget.dart';

class CreateRestaurantScreen extends StatefulWidget {
  const CreateRestaurantScreen({super.key});

  @override
  State<CreateRestaurantScreen> createState() => _CreateRestaurantScreenState();
}

class _CreateRestaurantScreenState extends State<CreateRestaurantScreen> {
  final _formKey = GlobalKey<FormState>();
  Restaurante restaurant = Restaurante();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _siteController = TextEditingController();
  final TextEditingController _ratingController = TextEditingController();
  final TextEditingController _reviewsCountController = TextEditingController();

  final List<File> _photos = [];
  String? _thumb;
  Image bgImageProvider = Image.asset(
      'assets/images/no_image.png',
      frameBuilder: (ctx, w, r, s) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: w,
      )
  );
  bool _loading = false;

  Widget buildDayEditor(DaySchedule schedule) {
    return ExpansionTile(
      title: Text(dayInPortuguese(schedule.day)),
      children: [
        CheckboxListTile(
          title: const Text("Fechado"),
          value: schedule.isClosed,
          onChanged: (v) {
            setState(() {
              schedule.isClosed = v ?? false;
              if (schedule.isClosed) {
                schedule.isOpen24h = false;
                schedule.intervals.clear();
              }
            });
          },
        ),
        CheckboxListTile(
          title: const Text("Aberto 24h"),
          value: schedule.isOpen24h,
          onChanged: (v) {
            setState(() {
              schedule.isOpen24h = v ?? false;
              if (schedule.isOpen24h) {
                schedule.isClosed = false;
                schedule.intervals.clear();
              }
            });
          },
        ),
        if (!schedule.isClosed && !schedule.isOpen24h)
          Column(
            children: [
              for (var i = 0; i < schedule.intervals.length; i++)
                ListTile(
                  title: Text(
                    "${schedule.intervals[i].start.format(context)} - ${schedule.intervals[i].end.format(context)}",
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() => schedule.intervals.removeAt(i));
                    },
                  ),
                ),
              TextButton.icon(
                onPressed: () async {
                  final start = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 9, minute: 0),
                  );
                  if (start != null) {
                    final end = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 18, minute: 0),
                    );
                    if (end != null) {
                      setState(() {
                        schedule.intervals.add(TimeGap(start, end));
                      });
                    }
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text("Adicionar horário"),
              ),
            ],
          )
      ],
    );
  }

  @override
  void initState() {
    restaurant.currentOpeningHours = CurrentOpeningHours.init();
    super.initState();
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

  void _removePhoto(File file) {
    setState(() {
      _photos.remove(file);
      if (_thumb == file.path) {
        _thumb = _photos.last.path;
      }
    });
  }

  void _setThumb(String url) {
    setState(() {
      _thumb = url;
      bgImageProvider = Image.file(File(url));
    });
  }

  Future<void> _saveChanges() async {
    try{
      if (!_formKey.currentState!.validate()) return;
      if(_thumb == null) {
        showCustomTopSnackBar(text: "Selecione uma foto principal para o restaurante");
        return;
      }

      setState(() => _loading = true);

      final images = _photos.map((e) => e.path).toList();

      final restaurantController = Provider.of<RestaurantController>(context, listen: false);
      await restaurantController.createRestaurant(restaurant, _thumb!, images: images);
      Navigator.pop(context, true);
    }catch(e) {
      showCustomTopSnackBar(text: 'Não foi possível adicionar o restaurante $e');
    }finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Adicionar Restaurante"),
        centerTitle: true,
        actions: [
          if(_loading)
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: CircularProgressIndicator(strokeWidth: 1.5,),
            )
          else
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
                decoration: const InputDecoration(labelText: "Nome*"),
                onChanged: (v) => restaurant.nome = v,
                validator: (v) => v!.isEmpty ? "Digite o nome" : null,
              ),
              Row(
                spacing: 8,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _addressController,
                      onChanged: (v) => restaurant.endereco = v,
                      validator: (v) => v!.isEmpty ? "Digite o endereço" : null,
                      decoration: const InputDecoration(labelText: "Endereço*"),
                    ),
                  ),
                  SizedBox(
                    height: 40,
                    width: 130,
                    child: DropdownButtonFormField<String>(
                      value: restaurant.regiao,
                      validator: (v) => v?.isEmpty ?? true ? "Selecione a região" : null,
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface,
                          overflow: TextOverflow.ellipsis
                      ),
                      hint: const Text("Região*"),
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
                      onChanged: (value) => restaurant.regiao = value,
                    ),
                  )
                ],
              ),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                onChanged: (v) => restaurant.phone = v,
                decoration: const InputDecoration(labelText: "Telefone"),
              ),
              TextFormField(
                controller: _siteController,
                onChanged: (v) => restaurant.websiteUri = v,
                decoration: const InputDecoration(labelText: "Site"),
              ),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                runSpacing: 24,
                children: [
                  SizedBox(
                    width: 130,
                    height: 40,
                    child: TextFormField(
                      controller: _ratingController,
                      onChanged: (v) => restaurant.avaliacao = double.tryParse(v),
                      decoration: const InputDecoration(labelText: "Avaliação"),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    height: 40,
                    child: TextFormField(
                      controller: _reviewsCountController,
                      onChanged: (v) => restaurant.userRatingCount = int.tryParse(v),
                      decoration: const InputDecoration(labelText: "Qtd. Avaliações"),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const Text("Categoria Principal*", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                children: CategoriaTipo.values.map((c) => CategoryChip(
                  label: c.description,
                  selected: c.name == restaurant.categoria?.name,
                  onSelected: (value) {
                    setState(() => restaurant.categoria = c);
                  }
                )).toList(),
              ),
              const Text("Categorias Secundárias", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                children: CategoriaTipo.values.where((c) => c != restaurant.categoria && c != CategoriaTipo.todos).map((c) => CategoryChip(
                  label: c.description,
                  selected: restaurant.categorias?.contains(c) ?? false,
                  onSelected: (value) {
                    if(value) {
                      setState(() {
                        restaurant.categorias ??= [];
                        restaurant.categorias!.add(c);
                      });
                    }else {
                      setState(() {
                        restaurant.categorias ??= [];
                        restaurant.categorias!.remove(c);
                      });
                    }
                  }
                )).toList(),
              ),
              const Text("Horário de funcionamento*", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ScheduleEditor(weekdayDescriptions: restaurant.currentOpeningHours!.weekdayDescriptions!),
              const Text("Foto Principal*", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              InkWell(
                child: ClipRRect(
                  borderRadius: BorderRadiusDirectional.circular(12),
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: kElevationToShadow[1],
                        border: Border.all()
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      fit: StackFit.expand,
                      children: [
                        Opacity(opacity: .5, child: bgImageProvider),
                        Container(
                          height: 35,
                          alignment: Alignment.center,
                          child: ElevatedButton(
                            onPressed: () {
                              pickSingleFile(context, crop: false).then((res) {
                                if(res is File) {
                                  setState(() {
                                    _thumb = res.path;
                                    bgImageProvider = Image.file(res);
                                  });
                                }
                              });
                            },
                            child: (_thumb?.isEmpty ?? true)
                                ? Text('Adicionar imagem')
                                : Text('Editar')
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  const Text("Fotos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton.filled(
                    onPressed: () {
                      showPostOpcoesBottomSheet(context).then((res) {
                        if(res is List && res.isNotEmpty) {
                          final files = res as List<XFile>;
                          setState(() => _photos.addAll(files.map((e) => File(e.path)).toList()));
                        }
                      });
                    },
                    icon: const Icon(Icons.add)
                  )
                ],
              ),
              if(_photos.isEmpty)
                SizedBox(
                  height: 150,
                  child: Center(
                    child: Text('Nenhuma foto adicionada ainda...'),
                  )
                )
              else
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
                    final file = _photos[i];
                    return Stack(
                      children: [
                        GestureDetector(
                          onTap: () => _setThumb(file.path),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _thumb == file.path ? Colors.green : Colors.transparent,
                                width: 5,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: FileImage(file),
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
                              onPressed: () => _removePhoto(file),
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