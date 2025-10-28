import 'dart:async';
import 'package:bsb_eats/controller/auth_controller.dart';
import 'package:bsb_eats/shared/model/user.dart';
import 'package:bsb_eats/shared/util/extensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EmailConfirmationScreen extends StatefulWidget {
  final MyUser user;
  final String password;

  const EmailConfirmationScreen({super.key, required this.user, required this.password});

  @override
  State<EmailConfirmationScreen> createState() => _EmailConfirmationScreenState();
}

class _EmailConfirmationScreenState extends State<EmailConfirmationScreen> {
  late final authController = Provider.of<AuthController>(context, listen: false);
  late Timer timer;

  void checkIfEmailIsVerified() {
    timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      authController.reloadUser().then((user) {
        bool isEmailVerified = user?.emailVerified ?? false;

        if (isEmailVerified) {
          final myUser = MyUser(
            id: user!.uid,
            nome: widget.user.nome,
            username: widget.user.username,
            email: widget.user.email,
            profilePhotoUrl: widget.user.profilePhotoUrl,
          );
          authController.saveUserData(myUser);
          showCustomSnackBar(child: Text('Email validado com sucesso!'));
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          timer.cancel();
        }
      }).catchError((error) {
        authController.reauthenticateUser(widget.user.email!, widget.password);
        // if(error.code == 'no-current-user') {
        //   authController.reauthenticateUser(widget.email, widget.password);
        // }
      });

    });
  }

  @override
  void initState() {
    checkIfEmailIsVerified();
    super.initState();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(elevation: 0, backgroundColor: theme().primaryColor,),
      backgroundColor: theme().primaryColor,
      body: Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: Column(
          children: [
            Image.asset('assets/images/email_confirmation.png', width: 250, height: 250),
            Text('Confirme seu email', style: theme().textTheme.titleLarge),
            Text.rich(
              textAlign: TextAlign.center,
              TextSpan(
                text: '\nEnviamos um email de confirmação para:\n',
                style: theme().textTheme.titleSmall!.copyWith(fontSize: 16),
                children: <TextSpan>[
                  TextSpan(
                      text: widget.user.email!.obscured(),
                      style: theme().textTheme.titleLarge!.copyWith(fontSize: 17, height: 3)
                  ),
                  TextSpan(
                      text: '\ncheque seu email e clique no link de confirmação para cocluir seu cadastro.',
                      style: theme().textTheme.titleSmall!.copyWith(fontSize: 16, height: 2)
                  )
                ]
              )
            ),
            const Spacer(),
            TextButton(
              onPressed: () => authController.sendEmailVerification().whenComplete(() => showCustomSnackBar(child: const Text('Novo email enviado com sucesso!'))),
              child: Text(
                'Reenviar email',
                style: theme().textTheme.titleLarge?.copyWith(
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white,
                )
              )
            ),
            const SizedBox(height: 20)
          ],
        ),
      ),
    );
  }
}
