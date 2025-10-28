import 'dart:async';
import 'dart:io';
import 'package:bsb_eats/screens/auth/login/reset_email_sent_dialog.dart';
import 'package:bsb_eats/screens/auth/login/reset_pass_modal.dart';
import 'package:bsb_eats/shared/util/extensions.dart';
import 'package:bsb_eats/shared/widgets/app_logo_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../controller/auth_controller.dart';
import '../../../service/food_api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final authController = Provider.of<AuthController>(context, listen: false);
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  Timer? _timer;
  ImageProvider imageBackground = AssetImage('assets/images/placeholder.jpg');
  bool _loading = false;
  bool _hidePass = true;

  Future<void> sendEmailVerification() async {
    try{
      await authController.sendEmailVerification();
      authController.logout();
      showCustomSnackBar(child: Text('Email de verificação reenviado com sucesso!'));
    }on FirebaseAuthException catch(e) {
      showCustomSnackBar(child: Text(e.translated()));
    }
  }

  Future<void> doLogin() async {
    try{
      setState(() => _loading = true);
      await authController.login(_emailController.text, _passwordController.text);
      if(authController.currentUser?.emailVerified ?? false) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }else {
        throw FirebaseAuthException(code: 'invalid-email-verified');
      }
    }on FirebaseAuthException catch(e) {
      if(e.code == 'invalid-email-verified') {
        showCustomSnackBar(child: Column(
          children: [
            Text(e.translated()),
            TextButton(
              onPressed: () => sendEmailVerification(),
              child: const Text('Reenviar email de verificação')
            )
          ],
        ));
        return;
      }
      showCustomSnackBar(child: Text(e.translated()));
    }finally {
      setState(() => _loading = false);
    }
  }

  Future<void> doGoogleLogin() async {
    try{
      setState(() => _loading = true);
      await authController.getGoogleCredential();
      if(authController.gCredential != null) {
        final credential = await authController.googleSignIn();
        if(credential != null) {
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        }
      }
    }on GoogleSignInException catch(e) {
      showCustomSnackBar(child: Text(e.description ?? 'Erro ao realizar login.'));
    }finally {
      setState(() => _loading = false);
    }
  }

  Future<void> doAppleLogin() async {
    try{
      setState(() => _loading = true);
      await authController.getAppleCredential();
      if(authController.appleCredential != null) {
        final credential = await authController.appleSignIn();
        if(credential != null) {
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        }
      }
    }on SignInWithAppleException catch(_) {
      showCustomSnackBar(child: Text('Não foi possível realizar o login.'));
    }finally {
      setState(() => _loading = false);
    }
  }

  Widget _loginSection() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Entrar', style: theme().textTheme.labelLarge?.copyWith(fontSize: 20),),
              Text('Entre com sua conta para continuar', style: theme().textTheme.labelMedium,),
              const SizedBox(height: 24.0),
              Text(
                'Email',
                style: theme().textTheme.bodyLarge,
              ),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
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
              const SizedBox(height: 16.0),
              Text(
                'Senha',
                style: theme().textTheme.bodyLarge,
              ),
              TextFormField(
                controller: _passwordController,
                obscureText: _hidePass,
                decoration: InputDecoration(
                  hintText: 'Digite sua senha...',
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _hidePass = !_hidePass),
                    icon: !_hidePass ? const Icon(Icons.visibility_off) : const Icon(Icons.visibility),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'A senha é obrigatória';
                  }
                  // Add more password validation if needed
                  return null;
                },
              ),
              Container(
                alignment: Alignment.centerRight,
                margin: const EdgeInsets.only(bottom: 16.0, top: 4),
                child: TextButton(
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    useSafeArea: true,
                    showDragHandle: true,
                    builder: (contet) => const ResetPassModal()
                ).then((res) {
                  if(res is String) {
                    showDialog(
                        context: context,
                        builder: (context) => ResetEmailSentDialog(email: res)
                    );
                  }
                }),
                  style: TextButton.styleFrom(
                    textStyle: TextStyle(
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                      decorationColor: theme().primaryColor,
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Esqueci minha senha')
                ),
              ),
              if(_loading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      doLogin();
                    }
                  },
                  child: const Text('Entrar'),
                ),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Não tem uma conta? '),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/register').then((res) {
                      if(res is String) _emailController.text = res;
                    }),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: const Text('Cadastre-se'),
                  ),
                ],
              ),
              Column(
                children: [
                  SocialLoginContainer(
                    path: 'assets/icons/google.svg',
                    provider: 'Google',
                    backgroundColor: Colors.white,
                    onTap: () => doGoogleLogin()
                  ),
                  if(Platform.isIOS)
                    SocialLoginContainer(
                      path: 'assets/icons/apple.svg',
                      provider: 'Apple',
                      backgroundColor: Colors.black,
                      onTap: () => doAppleLogin()
                    ),
                  TextButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/guest', (route) => false),
                    child: const Text(
                      'Pular login',
                      style: TextStyle(decoration: TextDecoration.underline),
                    )
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _restauranteOwnerSection() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.restaurant, color: theme().primaryColor, size: 18),
                const SizedBox(width: 8.0),
                Text(
                  'É dono de restaurante?',
                  style: theme().textTheme.labelLarge,
                ),
              ],
            ),
            Text('Cadastre seu restaurante e comece a divulgar suas promoções', style: theme().textTheme.labelMedium,),
            const SizedBox(height: 24.0),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to restaurant owner login
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme().colorScheme.surfaceContainerLow,
                foregroundColor: theme().colorScheme.onSurface,
              ),
              label: const Text('Cadastrar meu restaurante'),
              icon: const Icon(Icons.restaurant),
            ),
          ],
        ),
      ),
    );
  }

  void _getImagePeriodic() {
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      FoodApiService().getFoodImage().then((value) {
        if(value != null) {
          setState(() => imageBackground = NetworkImage(value));
        }
      });
    });
  }

  @override
  void initState() {
    authController.changeApiUrl('https://foodish-api.com/');
    _getImagePeriodic();
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: Container(
        height: mediaQuery().size.height,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: imageBackground,
            colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.3), BlendMode.darken),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 32,
              children: [
                const AppLogoWidget(),
                _loginSection(),
                //_restauranteOwnerSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SocialLoginContainer extends StatelessWidget {
  final String path;
  final String provider;
  final Color backgroundColor;
  final Function() onTap;
  const SocialLoginContainer({super.key, required this.path,required this.onTap, required this.backgroundColor, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            color: backgroundColor,
            border: Border.all()
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(path, width: 25, height: 25,),
              const SizedBox(width: 12),
              Text('Entrar com $provider', style: TextStyle(color: (backgroundColor == Colors.black) ? Colors.white : Colors.black),)
            ],
          ),
        ),
      ),
    );
  }
}