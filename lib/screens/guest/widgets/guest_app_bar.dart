import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import '../../../shared/widgets/app_logo_widget.dart';
import '../../home/widgets/logo_expanded_widget.dart';

class GuestHomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Function(String? value) onSearch;
  final Function(String? value) onChanged;
  const GuestHomeAppBar({super.key, required this.onSearch, required this.onChanged});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 150);

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    return AppBar(
      elevation: 0,
      flexibleSpace: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            spacing: 16,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppLogoWidget(
                onPressed: () => Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.scale,
                    alignment: Alignment.topLeft,
                    child: const LogoExpandedWidget()
                  )
                ),
                onWhiteBackground: true,
                crossAxisAlignment: CrossAxisAlignment.start,
              ),
              // Campo de busca
              Row(
                spacing: 8,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: controller,
                      onSubmitted: onSearch,
                      autofocus: false,
                      decoration: InputDecoration(
                        hintText: "Buscar restaurantes...",
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          onPressed: () => controller.clear(),
                          icon: const Icon(Icons.clear),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      ),
                    ),
                  ),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface,
                          overflow: TextOverflow.ellipsis
                      ),
                      hint: const Text("Região"),
                      items: const [
                        DropdownMenuItem(value: "tudo", child: Text("Todos")),
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
                      onChanged: onChanged,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => onSearch(controller.text),
                label: Text('Pesquisar'),
                icon: const Icon(Icons.search),
              )
            ],
          ),
        ),
      ),
    );
  }
}