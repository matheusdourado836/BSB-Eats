import 'package:app_links/app_links.dart';
import 'package:bsb_eats/shared/model/user.dart';
import 'package:bsb_eats/shared/util/extensions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controller/auth_controller.dart';
import '../../controller/user_controller.dart';

class InitialSplashScreen extends StatefulWidget {
  final RemoteMessage? initialMessage;
  final String? placeId;
  final String? postId;
  final String? userId;
  const InitialSplashScreen({super.key, this.initialMessage, this.placeId, this.postId, this.userId});

  @override
  State<InitialSplashScreen> createState() => _InitialSplashScreenState();
}

class _InitialSplashScreenState extends State<InitialSplashScreen> {
  late final AuthController authController;
  final AppLinks _appLinks = AppLinks();
  String? _pendingRestaurantId;
  MyUser? user;

  @override
  void initState() {
    super.initState();
    authController = Provider.of<AuthController>(context, listen: false);
    _handleDeepLinks();
    _executeInitialization();
  }

  Future<void> _handleDeepLinks() async {
    // 🔹 Captura o link inicial
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) _parseUri(initialUri);

    // 🔹 Escuta links enquanto o app estiver aberto
    _appLinks.uriLinkStream.listen((uri) {
      _parseUri(uri);
    });
  }

  void _parseUri(Uri uri) {
    if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'restaurant') {
      final placeId = uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;
      if (placeId != null) {
        _pendingRestaurantId = placeId;
      }
    }
  }

  Future<void> _executeInitialization() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool? isNewUser = prefs.getBool('isNewUser');

      if (isNewUser == null) {
        _navigateToOnboarding();
        return;
      }

      await authController.getLoggedUser();

      if (authController.currentUser == null || authController.currentUser!.emailVerified != true) {
        authController.logout();
        //_navigateToLogin();
        _navigateToGuest();
      } else {
        if(widget.initialMessage != null) {
          if(widget.initialMessage!.data["route"]?.isNotEmpty ?? false) {
            Navigator.pushReplacementNamed(context, '/home');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushNamed(context, widget.initialMessage!.data["route"], arguments: widget.initialMessage!.data["arguments"]);
            });
          }
        }
        if(widget.placeId != null) {
          _navigateToDetails();
        }else if(widget.postId != null) {
          _navigateToPostDetails();
        }else {
          _navigateToHome();
        }
      }
    } catch (e) {
      debugPrint('Erro ao iniciar a aplicação: $e');
      authController.currentUser == null
          ? _navigateToGuest()
          : _navigateToHome();
    }
  }

  void _navigateToOnboarding() {
    Navigator.pushReplacementNamed(context, '/onboarding');
  }

  void _navigateToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _navigateToGuest() {
    Navigator.pushReplacementNamed(context, '/guest');
  }

  Future<void> _navigateToHome() async {
    if(widget.userId?.isNotEmpty ?? false) {
      final userController = Provider.of<UserController>(context, listen: false);
      user = await userController.getUserById(widget.userId!);
    }
    Navigator.pushReplacementNamed(context, '/home');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pendingRestaurantId != null) {
        Navigator.pushNamed(
          context,
          '/restaurant_details',
          arguments: _pendingRestaurantId,
        );
        _pendingRestaurantId = null;
      }
      if(widget.userId?.isNotEmpty ?? false) {
        Navigator.pushNamed(context, '/profile', arguments: widget.userId);
      }
    });
  }

  void _navigateToDetails() {
    Navigator.pushReplacementNamed(context, '/home');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushNamed(
        '/restaurant_details',
        arguments: widget.placeId,
      );
    });
  }

  void _navigateToPostDetails() {
    Navigator.pushReplacementNamed(context, '/home');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushNamed(
        '/post_details',
        arguments: widget.postId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme().primaryColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: Image.asset('assets/images/logo_alt.png'),
            ),
          ),
          const SizedBox(height: 24),
          CircularProgressIndicator(color: theme().colorScheme.secondary),
        ],
      ),
    );
  }
}