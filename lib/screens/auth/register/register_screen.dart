import 'dart:io';
import 'package:bsb_eats/controller/auth_controller.dart';
import 'package:bsb_eats/shared/model/user.dart';
import 'package:bsb_eats/shared/util/extensions.dart';
import 'package:bsb_eats/shared/widgets/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/app_logo_widget.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  File? _profileImage;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Widget _formField(String label, Widget form) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme().textTheme.bodyLarge),
        form
      ],
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);
      final authController = Provider.of<AuthController>(context, listen: false);
      if(!await authController.isUsernameAvailable(_usernameController.text)) {
        showCustomSnackBar(child: Text('Nome de usuário já em uso'));
        return;
      }
      final MyUser user = MyUser(
        nome: _nameController.text,
        username: _usernameController.text,
        email: _emailController.text,
        profilePhotoUrl: _profileImage?.path
      );

      await authController.registerUser(user: user, pass: _passwordController.text);
      Navigator.pushNamed(context, '/email_confirmation', arguments: {"user": user, "password": _passwordController.text});
    } on FirebaseAuthException catch (e) {
      showCustomSnackBar(child: Text(e.translated()));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/placeholder.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const AppLogoWidget(),
                  const SizedBox(height: 16),
                  Card(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Foto de perfil
                          GestureDetector(
                            onTap: () => showOpcoesBottomSheet(context).then((res) {
                              if(res == true) {
                                setState(() => _profileImage = null);
                              }else if(res is File) {
                                setState(() => _profileImage = res);
                              }
                            }),
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.grey[300],
                              backgroundImage: _profileImage != null
                                  ? FileImage(_profileImage!)
                                  : null,
                              child: _profileImage == null
                                  ? Icon(Icons.camera_alt, color: Colors.grey[700], size: 32)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _formField(
                            'Nome *',
                            TextFormField(
                              controller: _nameController,
                              keyboardType: TextInputType.name,
                              decoration: const InputDecoration(
                                hintText: "Digite seu nome aqui...",
                              ),
                              validator: (value) =>
                              value!.isEmpty ? "Informe seu nome" : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _formField(
                            'Nome de usuário *',
                            TextFormField(
                              controller: _usernameController,
                              decoration: const InputDecoration(
                                hintText: "Digite seu nome de usuário aqui...",
                              ),
                              validator: (value) =>
                              value!.isEmpty ? "Informe seu nome de usuário" : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _formField(
                            'Email *',
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                hintText: "E-mail",
                              ),
                              validator: (value) {
                                if (value!.isEmpty) return "Informe seu e-mail";
                                if (!value.contains("@")) return "E-mail inválido";
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          _formField(
                            'Senha *',
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                hintText: "Digite sua senha aqui...",
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() => _obscurePassword = !_obscurePassword);
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value!.isEmpty) return "Informe sua senha";
                                if (value.length < 6) return "Mínimo 6 caracteres";
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          _formField(
                            'Confirmar senha *',
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              decoration: InputDecoration(
                                hintText: "Confirmar senha",
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value!.isEmpty) return "Confirme sua senha";
                                if (value != _passwordController.text) {
                                  return "Senhas não conferem";
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _register,
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text("Cadastrar"),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Já tem conta? Faça login"),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}