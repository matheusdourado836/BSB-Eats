import 'package:bsb_eats/controller/auth_controller.dart';
import 'package:bsb_eats/shared/util/extensions.dart';
import 'package:bsb_eats/shared/widgets/social_login_container.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final GlobalKey<FormState> _key = GlobalKey();
  late final authController = Provider.of<AuthController>(context, listen: false);
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _loading = false;
  bool _hidePass = true;
  String _errorMsg = '';
  bool _verified = false;
  bool _isPassProvider = false;

  Future<void> deleteAccount({bool isAlreadyAuthenticated = false}) async {
    try {
      setState(() => _loading = true);
      if(!isAlreadyAuthenticated) {
        await authController.reauthenticateUser(_emailController.text, _passController.text);
      }
      await authController.deleteAccount();
      setState(() => _loading = false);
      showCustomSnackBar(child: const Text('Conta deletada com sucesso!'));
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }on FirebaseAuthException catch(e) {
      setState(() {
        _loading = false;
        _errorMsg = e.translated();
      });
    }
  }

  Widget _formFieldByType() {
    if(authController.currentUser?.providers?.contains('password') ?? false) {
      return Column(
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'Digite seu email'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passController,
            obscureText: _hidePass,
            decoration: InputDecoration(
              hintText: 'Digite sua senha',
              suffixIcon: IconButton(
                onPressed: () => setState(() => _hidePass = !_hidePass),
                icon: _hidePass
                  ? const Icon(CupertinoIcons.eye)
                  : const Icon(CupertinoIcons.eye_slash)
              )
            ),
          ),
        ],
      );
    } else if(authController.currentUser?.providers?.contains('google.com') ?? false) {
      return SocialLoginContainer(
        path: 'assets/icons/google.svg',
        provider: 'Google',
        backgroundColor: Colors.white,
        onTap: () => doGoogleLogin()
      );
    } else if(authController.currentUser?.providers?.contains('apple.com') ?? false) {
      return SocialLoginContainer(
        path: 'assets/icons/apple.svg',
        provider: 'Apple',
        backgroundColor: Colors.black,
        onTap: () => doAppleLogin()
      );
    }

    return const SizedBox();
  }

  Future<void> doGoogleLogin() async {
    try {
      await authController.getGoogleCredential();
      if(authController.gCredential != null) {
        await authController.reauthenticateWithCredential(authController.gCredential!);
        setState(() {
          _verified = true;
          _errorMsg = '';
        });
      }
    }on FirebaseAuthException catch(e) {
      setState(() {
        _errorMsg = e.translated();
        _verified = false;
      });
    }
  }

  Future<void> doAppleLogin() async {
    try {
      await authController.getAppleCredential();
      if(authController.appleCredential != null) {
        await authController.reauthenticateWithCredential(authController.appleCredential!);
        setState(() {
          _verified = true;
          _errorMsg = '';
        });
      }
    }on FirebaseAuthException catch(e) {
      setState(() {
        _errorMsg = e.translated();
        _verified = false;
      });
    }
  }

  @override
  void initState() {
    _isPassProvider = authController.currentUser?.providers?.contains('password') ?? false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Column(
        children: [
          Text('Confirme sua decisão'),
          Text(
            'Entre novamente com sua conta para prosseguir com a exclusão',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          )
        ],
      ),
      content: Form(
        key: _key,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _formFieldByType(),
            if(_verified)
              const Text('Verificação bem sucedida!', style: TextStyle(color: Colors.green)),
            if(_errorMsg.isNotEmpty)
              Text(_errorMsg, style: const TextStyle(color: Colors.red))
          ],
        ),
      ),
      actions: [
        if(_loading)
          const CircularProgressIndicator(strokeWidth: 1.5)
        else
          TextButton(
            onPressed: () {
              if(_key.currentState!.validate()) {
                deleteAccount(isAlreadyAuthenticated: !_isPassProvider && _verified);
              }
            },
            child: const Text('Deletar', style: TextStyle(color: Colors.red))
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
      ],
    );
  }
}