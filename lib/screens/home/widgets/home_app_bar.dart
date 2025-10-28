import 'dart:async';
import 'package:bsb_eats/controller/user_controller.dart';
import 'package:bsb_eats/screens/home/widgets/logo_expanded_widget.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import '../../../shared/model/notification.dart';
import '../../../shared/widgets/app_logo_widget.dart';

class HomeAppBar extends StatefulWidget implements PreferredSizeWidget {
  final Function(String? value) onSearch;
  final Function(String? value) onChanged;
  const HomeAppBar({super.key, required this.onSearch, required this.onChanged});

  @override
  State<HomeAppBar> createState() => _HomeAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 150);
}

class _HomeAppBarState extends State<HomeAppBar> {
  final TextEditingController controller = TextEditingController();
  final _controller = StreamController<int>();
  final EventBus eventBus = EventBus();
  late final _userController = Provider.of<UserController>(context, listen: false);
  int _notificationsCount = 0;

  StreamSubscription? _globalSub;
  StreamSubscription? _userSub;

  void _listenToNotifications() {
    int globalCount = 0;
    int userCount = 0;

    // 🔹 Escuta notificações globais
    _globalSub = _userController.getNotificationStream.listen((snapshot) {
      int count = 0;
      for (final doc in snapshot.docs) {
        if (!(_userController.currentUser?.globalNotificationsRead?.contains(doc.id) ?? false)) {
          count++;
          _userController.currentUser?.notifications ??= [];
          _userController.currentUser?.notifications?.add(MyNotification.fromJson(doc.data()));
        }
      }
      globalCount = count;
      _controller.add(globalCount + userCount);
    });

    // 🔹 Escuta notificações específicas do usuário
    _userSub = _userController.getUserNotificationStream.listen((snapshot) {
      userCount = snapshot.docs.length;
      final notifications = snapshot.docs.map((e) => MyNotification.fromJson(e.data())).toList();
      _userController.currentUser?.notifications ??= [];
      _userController.currentUser?.notifications?.addAll(notifications);
      _controller.add(globalCount + userCount);
    });
  }

  Future<void> getNotificationsCount() async {
    final count = await _userController.getNotificationsCount();
    setState(() => _notificationsCount = count);
    _controller.add(count);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => getNotificationsCount());
    _listenToNotifications();
    eventBus.on().listen((event) {
      if(event == 'refresh_notifications') {
        getNotificationsCount();
      }
    });
  }

  @override
  void dispose() {
    _controller.close();
    _globalSub?.cancel();
    _userSub?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
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
                      onSubmitted: widget.onSearch,
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
                      onChanged: widget.onChanged,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => widget.onSearch(controller.text),
                label: Text('Pesquisar'),
                icon: const Icon(Icons.search),
              )
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
            onPressed: () => Navigator.pushNamed(context, '/coupons'),
            icon: const Icon(Icons.discount_outlined, size: 26)
        ),
        IconButton(
          onPressed: () => Navigator.pushNamed(context, '/favorites'),
          icon: const Icon(Icons.favorite_border_rounded, size: 26)
        ),
        StreamBuilder<int>(
          stream: _controller.stream,
          initialData: _notificationsCount,
          builder: (context, asyncSnapshot) {
            final count = asyncSnapshot.data ?? 0;
            return IconButton(
              onPressed: () => Navigator.pushNamed(context, '/notifications', arguments: eventBus),
              icon: Badge.count(
                isLabelVisible: count > 0,
                count: count,
                child: const Icon(Icons.notifications_outlined, size: 26),
              )
            );
          }
        ),
      ],
    );
  }
}