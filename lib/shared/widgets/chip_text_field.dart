import 'package:bsb_eats/shared/model/paged_result.dart';
import 'package:bsb_eats/shared/model/user.dart';
import 'package:bsb_eats/shared/util/extensions.dart';
import 'package:bsb_eats/shared/widgets/user_avatar_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controller/auth_controller.dart';
import '../../controller/restaurant_controller.dart';
import '../model/restaurante.dart';

class ChipTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool? required;
  final bool? applyPadding;
  final bool? enbled;
  final Function(String?)? onSaved;
  final Future<dynamic> Function(String)? fetchSuggestions;
  final Set<dynamic>? selectedItems;
  final Function(dynamic)? onItemAdded;
  final Function(dynamic)? onItemRemoved;

  const ChipTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.required,
    this.applyPadding,
    this.enbled,
    this.onSaved,
    this.fetchSuggestions,
    this.selectedItems,
    this.onItemAdded,
    this.onItemRemoved,
  });

  @override
  State<ChipTextField> createState() => _ChipTextFieldState();
}

class _ChipTextFieldState extends State<ChipTextField> {
  List<dynamic> _suggestions = [];

  void _updateSuggestions(String value) async {
    if(value.isEmpty) {
      setState(() => _suggestions.clear());
    }
    if (widget.fetchSuggestions != null && value.trim().length >= 3) {
      final suggestions = await widget.fetchSuggestions!(value);
      if(suggestions is PagedResult) {
        setState(() => _suggestions = suggestions.places ?? []);
      }else {
        setState(() => _suggestions = suggestions);
      }
    }
  }

  void showSuggestionBottomSheet() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController locationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sugerir restaurante'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Nome do restaurante",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationController,
                decoration: InputDecoration(
                  labelText: "Local (Asa sul, Águas Claras, Guará...)",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final location = locationController.text.trim();

                if (name.isEmpty || location.isEmpty) {
                  showCustomSnackBar(child: Text("Preencha todos os campos"));
                  return;
                }

                await _sendSuggestion(name, location);

                showCustomSnackBar(child: Text("Sugestão enviada com sucesso!"));
              },
              child: Text("Enviar"),
            )
          ],
        );
      },
    );
  }

  Future<void> _sendSuggestion(String name, String location) async {
    if (name.isEmpty || location.isEmpty) return;

    final restaurantController = Provider.of<RestaurantController>(context, listen: false);
    final authController = Provider.of<AuthController>(context, listen: false);
    final res = await restaurantController.sendSuggestion(name: name, location: location);
    if(res) {
      final placeholder = Restaurante(
        id: '404-${authController.currentUser!.id}-$name',
        nome: name,
      );
      setState(() {
        widget.onItemAdded?.call(placeholder);
        _suggestions.clear();
        widget.controller.clear();
      });
      Navigator.pop(context, '201');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: widget.applyPadding ?? true ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8) : EdgeInsets.zero,
          child: TextFormField(
            controller: widget.controller,
            autocorrect: true,
            keyboardType: TextInputType.text,
            enabled: widget.enbled ?? true,
            validator: widget.required == true ? (value) => (widget.selectedItems?.isEmpty ?? true) ? 'Campo obrigatório!' : null : null,
            onSaved: widget.onSaved,
            onChanged: (value) => _updateSuggestions(value),
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
            ),
          ),
        ),

        if (widget.selectedItems?.isNotEmpty ?? false)
          Padding(
            padding: widget.applyPadding ?? true ? const EdgeInsets.only(left: 16.0) : EdgeInsets.zero,
            child: Wrap(
              spacing: 4,
              children: widget.selectedItems!.map((item) => Chip(
                label: Text(item.nome ?? 'sem nome'),
                deleteIconColor: Theme.of(context).primaryColor,
                onDeleted: () => setState(() => widget.onItemRemoved?.call(item)),
              )).toList(),
            ),
          ),

        if (_suggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Material(
              color: theme().colorScheme.surfaceContainerLow,
              elevation: 4.0,
              borderRadius: BorderRadius.circular(4.0),
              child: SizedBox(
                height: 150.0,
                child: ListView.builder(
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final option = _suggestions[index];
                    if(option is MyUser) {
                      return ListTile(
                        horizontalTitleGap: 8,
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundImage: CachedNetworkImageProvider(option.profilePhotoUrl ?? ''),
                          onBackgroundImageError: (_, _) => const NoBgUser()
                        ),
                        title: Row(
                          spacing: 4,
                          children: [
                            Text(option.username ?? 'sem username'),
                            if(option.verified ?? false)
                              const Icon(Icons.verified, size: 14, color: Colors.blue,)
                          ],
                        ),
                        subtitle: Text(option.nome ?? 'sem nome'),
                        onTap: () {
                          setState(() {
                            widget.onItemAdded?.call(option);
                            _suggestions.clear();
                            widget.controller.clear();
                          });
                        },
                      );
                    }else if(option is Restaurante) {
                      if(option.id == '404') {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.amber,
                            child: Icon(Icons.question_mark, color: Colors.white,),
                          ),
                          title: Text('Não encontrou o restaurante que estava procurando?', style: TextStyle(fontSize: 12),),
                          subtitle: TextButton(
                            onPressed: showSuggestionBottomSheet,
                            style: TextButton.styleFrom(
                              alignment: Alignment.centerLeft,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero
                            ),
                            child: const Text(
                              'Envie-nos a sugestão para adicinarmos ao app',
                              style: TextStyle(fontSize: 12, decoration: TextDecoration.underline),
                            )
                          ),
                        );
                      }
                      final bgImage = option.image;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: CachedNetworkImageProvider(bgImage ?? ''),
                        ),
                        title: Text(option.nome ?? 'sem nome'),
                        onTap: () {
                          setState(() {
                            widget.onItemAdded?.call(option);
                            _suggestions.clear();
                            widget.controller.clear();
                          });
                        },
                      );
                    }
                    return ListTile(
                      title: Text(option),
                      onTap: () {
                        setState(() {
                          widget.onItemAdded?.call(option);
                          _suggestions.clear();
                          widget.controller.clear();
                        });
                      },
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}