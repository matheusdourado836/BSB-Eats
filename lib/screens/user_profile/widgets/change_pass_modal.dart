import 'package:bsb_eats/shared/util/extensions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controller/auth_controller.dart';
import '../../../shared/util/validations_mixin.dart';

class ChangePassModal extends StatefulWidget {
  const ChangePassModal({super.key});

  @override
  State<ChangePassModal> createState() => _ChangePassModalState();
}

class _ChangePassModalState extends State<ChangePassModal> with ValidationsMixin {
  final GlobalKey<FormState> _form = GlobalKey();
  final TextEditingController _oldPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _repeatNewPassController = TextEditingController();
  bool _tooManyRequests = false;
  bool _loading = false;
  bool _hideCurrentPass = false;
  bool _hideNewPass = false;
  bool _hideRepeatNewPass = false;
  String _error = '';

  Future<bool> validateUserOldPassword() async {
    try {
      final authController = Provider.of<AuthController>(context, listen: false,);
      setState(() => _loading = true);
      await authController.reauthenticateUser(authController.currentUser!.email!, _oldPassController.text);
      await authController.updatePassword(_newPassController.text);

      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') {
        setState(() => _tooManyRequests = true);
        return false;
      }
      setState(() => _error = e.translated());
      return false;
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _formField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme().textTheme.bodyLarge),
        child,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _formField(
              label: 'Digite sua senha atual',
              child: TextFormField(
                controller: _oldPassController,
                obscureText: _hideCurrentPass,
                decoration: InputDecoration(
                  hintText: '*******',
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _hideCurrentPass = !_hideCurrentPass),
                    icon: (_hideCurrentPass)
                        ? const Icon(Icons.visibility)
                        : const Icon(Icons.visibility_off),
                  ),
                ),
                validator: isEmpty,
              ),
            ),
            const SizedBox(height: 16),
            _formField(
              label: 'Digite sua nova senha',
              child: TextFormField(
                controller: _newPassController,
                obscureText: _hideNewPass,
                decoration: InputDecoration(
                  hintText: '*******',
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _hideNewPass = !_hideNewPass),
                    icon: (_hideNewPass)
                        ? const Icon(Icons.visibility)
                        : const Icon(Icons.visibility_off),
                  ),
                ),
                validator: (value) => combine([
                      () => isEmpty(value),
                      () => value!.length < 6
                      ? 'a senha deve ter pelo menos 7 caracteres'
                      : null,
                      () => newPassEqualsToOldPass(_oldPassController.text, value),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            _formField(
              label: 'Digite novamente sua nova senha',
              child: TextFormField(
                controller: _repeatNewPassController,
                obscureText: _hideRepeatNewPass,
                decoration: InputDecoration(
                  hintText: '*******',
                  suffixIcon: IconButton(
                    onPressed: () => setState(
                          () => _hideRepeatNewPass = !_hideRepeatNewPass,
                    ),
                    icon: (_hideRepeatNewPass)
                        ? const Icon(Icons.visibility)
                        : const Icon(Icons.visibility_off),
                  ),
                ),
                validator: (value) => combine([
                      () => isEmpty(value),
                      () => value!.length < 6
                      ? 'a senha deve ter pelo menos 7 caracteres'
                      : null,
                      () => passwordsDoNotMatch(_newPassController.text, value),
                ]),
              ),
            ),
            const Spacer(),
            Text(
              _error,
              style: theme().textTheme.titleSmall?.copyWith(color: Colors.red),
            ),
            const SizedBox(height: 16),
            (_tooManyRequests)
                ? Text(
              'Você já fez muitas tentativas, tente novamente mais tarde',
              style: theme().textTheme.titleSmall,
            )
                : ElevatedButton(
              onPressed: (() {
                if (_form.currentState!.validate()) {
                  validateUserOldPassword().then((res) {
                    if(res == true) {
                      Navigator.pop(context, true);
                    }
                  });
                }
              }),
              child: (_loading)
                  ? SizedBox(
                height: 25,
                width: 25,
                child: CircularProgressIndicator(strokeWidth: 3, color: theme().colorScheme.surface),
              )
                  : const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
