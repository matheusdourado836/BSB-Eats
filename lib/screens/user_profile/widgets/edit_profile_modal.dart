import 'dart:io';
import 'package:bsb_eats/controller/user_controller.dart';
import 'package:bsb_eats/shared/util/extensions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/image_picker.dart';

class EditProfileModal extends StatefulWidget {
  const EditProfileModal({super.key});

  @override
  State<EditProfileModal> createState() => _EditProfileModalState();
}

class _EditProfileModalState extends State<EditProfileModal> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final userController = Provider.of<UserController>(context, listen: false);
  late final currentUser = userController.currentUser!;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  String oldUserName = '';
  ImageProvider? _profileImage;
  File? bgImage;
  bool _loading = false;
  String _error = '';

  Widget _userBg() {
    if((currentUser.profilePhotoUrl?.isEmpty ?? true) && bgImage == null) {
      final username = currentUser.nome?.initials();
      return CircleAvatar(
        radius: 70,
        backgroundColor: theme().colorScheme.secondary,
        child: Text(
          username ?? 'SN',
          style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
        ),
      );
    }

    return CircleAvatar(
      radius: 70,
      backgroundImage: _profileImage,
    );
  }

  Future<void> save() async {
    try{
      setState(() => _loading = true);
      if(_usernameController.text != oldUserName) {
        if(!await userController.isUsernameAvailable(_usernameController.text)) {
          setState(() => _error = 'Nome de usuário já em uso');
          return;
        }
        await userController.updateUsername(username: _usernameController.text, oldUsername: oldUserName);
      }
      if(bgImage != null) {
        currentUser.profilePhotoUrl = bgImage!.path;
        await userController.updateUserProfilePicture(currentUser);
      }
      await userController.updateUserData(currentUser.toJson());
      userController.notify();
      Navigator.pop(context, true);
      return;
    }catch(e) {
      setState(() => _error = e.toString());
      return;
    }finally{
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    _nameController.text = currentUser.nome ?? 'sem nome';
    _usernameController.text = currentUser.username ?? 'sem username';
    _emailController.text = currentUser.email ?? 'sem email';
    _bioController.text = currentUser.bio ?? '';
    final userJson = userController.currentUser?.toJson();
    oldUserName = userJson?['username'] ?? '';
    if(currentUser.profilePhotoUrl?.isNotEmpty ?? false) {
      _profileImage = CachedNetworkImageProvider(
        currentUser.profilePhotoUrl!,
      );
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: () => showOpcoesBottomSheet(context).then((res) {
                  if(res == true) {
                    setState(() {
                      _profileImage = null;
                      bgImage = null;
                    });
                  }else if(res is File) {
                    setState(() {
                      _profileImage = FileImage(res);
                      bgImage = res;
                    });
                  }
                }),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        _userBg(),
                        Positioned(
                          top: 0,
                          right: 20,
                          child: Container(
                            height: 35,
                            width: 35,
                            decoration: BoxDecoration(
                              color: theme().primaryColor,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(Icons.edit, size: 20,),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Nome',
                style: theme().textTheme.bodyLarge,
              ),
              TextFormField(
                controller: _nameController,
                onChanged: (value) => currentUser.nome = value,
                decoration: const InputDecoration(
                  hintText: 'Digite seu nome aqui...',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'O nome é obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Nome de usuário',
                style: theme().textTheme.bodyLarge,
              ),
              TextFormField(
                controller: _usernameController,
                onChanged: (value) => currentUser.username = value,
                decoration: const InputDecoration(
                  hintText: 'Digite seu nome de usuário aqui...',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'O nome de usuário é obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Email',
                style: TextStyle(color: Colors.grey),
              ),
              TextFormField(
                controller: _emailController,
                onChanged: (value) => currentUser.email = value,
                enabled: false,
                decoration: const InputDecoration(
                  hintText: 'Digite seu email...',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'O email é obrigatório';
                  }
                  // Add more email validation if needed
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Bio',
                style: theme().textTheme.bodyLarge,
              ),
              TextFormField(
                controller: _bioController,
                onChanged: (value) => currentUser.bio = value,
                maxLines: 5,
                maxLength: 150,
                decoration: const InputDecoration(hintText: 'Digite sua bio aqui...'),
              ),
              const SizedBox(height: 16),
              Text(
                _error,
                style: theme().textTheme.titleSmall?.copyWith(color: Colors.red),
              ),
              const SizedBox(height: 16),
              if(_loading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      save();
                    }
                  },
                  child: const Text('Salvar'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
