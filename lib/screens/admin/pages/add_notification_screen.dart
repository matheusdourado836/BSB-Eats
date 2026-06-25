import 'dart:io';
import 'package:bsb_eats/screens/admin/widgets/show_image_source_widget.dart';
import 'package:bsb_eats/shared/util/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../controller/social_media_controller.dart';
import '../../../controller/user_controller.dart';
import '../../../shared/model/restaurante.dart';
import '../../../shared/model/user.dart';
import '../../../shared/widgets/chip_text_field.dart';
import '../../../shared/widgets/notification_image.dart';

class AddNotificationScreen extends StatefulWidget {
  const AddNotificationScreen({super.key});

  @override
  State<AddNotificationScreen> createState() => _AddNotificationScreenState();
}

class _AddNotificationScreenState extends State<AddNotificationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final UserController _userController = Provider.of<UserController>(context, listen: false);
  late final _socialMediaController = Provider.of<SocialMediaController>(context, listen: false);
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _restaurantController = TextEditingController();
  final TextEditingController _pessoasController = TextEditingController();
  final ValueNotifier<String> _title = ValueNotifier('');
  final ValueNotifier<String> _desc = ValueNotifier('');
  Set<Restaurante>? _selectedRestaurant;
  Set<MyUser>? _selectedPeople;
  static final List<String> _routes = ['/coupons', '/restaurant', '/reward', 'Nenhuma'];
  String _selectedOption = '/coupons';
  String _route = '/coupons';
  String? _notificationImage;
  Widget? imageProvider;
  bool _loading = false;
  bool _success = false;
  String suffix = '';
  dynamic arguments = '';

  Future<void> _sendNotification() async {
    if(!(_formKey.currentState?.validate() ?? false)) return;
    try{
      setState(() => _loading = true);
      final imageRef = (_notificationImage?.startsWith('https://') ?? false) ? _notificationImage! : await _socialMediaController.uploadNotificationImage(_notificationImage);
      final data = {
        'type': _selectedPeople?.isEmpty ?? true ? 'global' : 'group',
        'title': _titleController.text,
        'body': _descController.text,
        'image': imageRef,
        'route': _route,
        'userIds': _selectedPeople?.map((u) => u.id).toList(),
        'arguments': arguments
      };
      _success = await _userController.setNotification(data);
      if(_success) {
        showCustomSnackBar(child: const Text('Notificação enviada com sucesso!'));
        Navigator.pop(context);
      }else {
        showCustomSnackBar(child: const Text('Erro ao enviar notificação'));
      }
    }catch(e) {
      showCustomSnackBar(child: Text('Erro ao enviar notificação $e'));
    }finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enviar notificação'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              spacing: 8,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  onChanged: (v) => _title.value = v,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                  ),
                  validator: (value) {
                    if(value?.isEmpty ?? true) {
                      return 'Título é obrigatório';
                    }
                    return null;
                  }
                ),
                TextFormField(
                  controller: _descController,
                  onChanged: (v) => _desc.value = v,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                  ),
                  validator: (value) {
                    if(value?.isEmpty ?? true) {
                      return 'Descrição é obrigatório';
                    }
                    return null;
                  }
                ),
                const SizedBox(height: 8),
                Row(
                  spacing: 16,
                  children: [
                    const Text('Imagem da notificação:'),
                    InkWell(
                      onTap: () => showImageSourceBottomSheet(context).then((res) {
                        if(res is File) {
                          setState(() {
                            _notificationImage = res.path;
                            imageProvider = Image.file(res, fit: BoxFit.cover);
                          });
                        }else if(res is String && res.startsWith('https')) {
                          setState(() {
                            _notificationImage = res;
                            imageProvider = Image.network(res, fit: BoxFit.cover);
                          });
                        }
                      }),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        child: Container(
                          height: 45,
                          width: 45,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadiusDirectional.circular(12),
                            border: Border.all()
                          ),
                          child: _notificationImage == null && imageProvider == null
                            ? const Icon(Icons.upload)
                            : imageProvider!,
                        ),
                      ),
                    ),
                    if(imageProvider != null)
                      IconButton.filled(
                        onPressed: () => setState(() {
                          _notificationImage = null;
                          imageProvider = null;
                        }),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)
                          )
                        ),
                        icon: const Icon(Icons.delete)
                      )
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  spacing: 6,
                  children: [
                    const Text('Enviar para a rota após clique:'),
                    DropdownButton<String>(
                      value: _selectedOption,
                      onChanged: (String? newValue) {
                        if(newValue != 'restaurant') {
                          _restaurantController.clear();
                          _selectedRestaurant = null;
                        }
                        _route = newValue ?? '';
                        if(newValue == 'Nenhuma') {
                          _route = '';
                        }
                        setState(() => _selectedOption = newValue!);
                      },
                      items: _routes.map((r) => DropdownMenuItem(
                        value: r, child: Text(r)
                      )).toList()
                    )
                  ],
                ),
                if(_selectedOption == '/restaurant')
                  Column(
                    spacing: 4,
                    children: [
                      ChipTextField(
                        controller: _restaurantController,
                        applyPadding: false,
                        label: 'Selecionar o restaurante (obrigatório)',
                        hint: 'digite o nome do restaurante aqui...',
                        required: true,
                        enbled: _selectedRestaurant?.isEmpty ?? true,
                        fetchSuggestions: (value) async => await _socialMediaController.searchRestaurants(value.trim()),
                        selectedItems: _selectedRestaurant,
                        onItemAdded: (tag) => setState(() {
                          _selectedRestaurant ??= {};
                          _selectedRestaurant!.add(tag);
                          suffix = tag.id;
                          _route = '/restaurant/$suffix';
                        }),
                        onItemRemoved: (tag) => setState(() {
                          _selectedRestaurant?.remove(tag);
                          suffix = '';
                          _route = '/restaurant';
                        })
                      ),
                      if(_selectedRestaurant?.isNotEmpty ?? false)
                        Text(
                          'Ao clicar na notificação, o usuário será redirecionado para este restaurante',
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                        )
                    ],
                  ),
                if(_selectedOption == '/reward')
                  Column(
                    children: [
                      TextFormField(
                        keyboardType: TextInputType.number,
                        onChanged: (v) => arguments = v,
                        maxLength: 4,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          if(value?.isEmpty ?? true) {
                            return 'Quantidade de moedas é obrigatório';
                          }else if((int.tryParse(value ?? '') ?? 0) == 0) {
                            return 'Quantidade de moedas deve ser maior que 0';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          labelText: 'Quantidade de moedas',
                        ),
                      ),
                      const SizedBox(height: 8),
                      ChipTextField(
                          controller: _pessoasController,
                          applyPadding: false,
                          label: 'Enviar para usuários (opcional)',
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
                      const SizedBox(height: 4),
                      if(_selectedPeople?.isEmpty ?? true)
                        Text(
                          'Se nenhum usuário for selecionado, a recompensa será enviada para todos os usuários',
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                        )
                    ],
                  ),
                const SizedBox(height: 56),
                Text(
                  'Preview',
                  style: TextStyle(color: Colors.grey),
                ),
                Card(
                  child: ListTile(
                    minVerticalPadding: 16,
                    leading: NotificationImage(src: _notificationImage, isFile: !(_notificationImage?.startsWith('https') ?? false)),
                    title: ValueListenableBuilder(
                      valueListenable: _title,
                      builder: (context, value, child) {
                        return Text(value, style: TextStyle(fontSize: 14));
                      }
                    ),
                    subtitle: ValueListenableBuilder(
                      valueListenable: _desc,
                      builder: (context, value, child) {
                        return Text(value, style: TextStyle(fontSize: 12));
                      }
                    ),
                    trailing: Text(
                      DateTime.now().toCommentDate(),
                      style: const TextStyle(fontSize: 10, color: Color.fromRGBO(167, 167, 167, 1))
                    )
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar:(_loading)
        ? const Center(child: CircularProgressIndicator())
        : Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
          child: ElevatedButton(
              onPressed: _sendNotification,
              child: const Text('Enviar notificação')
            ),
        ),
    );
  }
}
