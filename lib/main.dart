import 'package:bsb_eats/controller/auth_controller.dart';
import 'package:bsb_eats/controller/social_media_controller.dart';
import 'package:bsb_eats/controller/user_controller.dart';
import 'package:bsb_eats/core/routes.dart';
import 'package:bsb_eats/screens/splash/initial_splash_screen.dart';
import 'package:bsb_eats/service/firebase_messaging_service.dart';
import 'package:bsb_eats/themes/main_theme.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:sentry_logging/sentry_logging.dart';
import 'controller/restaurant_controller.dart';
import 'firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage? message) async {}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  FirebaseMessagingService firebaseMessagingService = FirebaseMessagingService();
  await firebaseMessagingService.initialize();
  await FirebaseAppCheck.instance.activate(
    providerAndroid: AndroidDebugProvider(debugToken: 'aad9518d-7247-42d2-a4ef-23e66ff9787d')
  );
  final GoogleSignIn googleSignIn = GoogleSignIn.instance;
  await googleSignIn.initialize();
  await dotenv.load(fileName: ".env");
  await SentryFlutter.init(
        (options) {
      options.dsn = dotenv.get('SENTRY_DSN');
      options.enableBreadcrumbTrackingForCurrentPlatform();
      options.addIntegration(LoggingIntegration());
      options.compressPayload = true;
      options.attachViewHierarchy = true;
      options.attachStacktrace = true;
      options.attachThreads = true;
      options.enableAppHangTracking = true;
      options.enableNativeCrashHandling = true;
      options.enableAutoPerformanceTracing = true;
      options.enableDeduplication = true;
      options.enableLogs = true;
      options.enableAutoSessionTracking = true;
      options.enableMemoryPressureBreadcrumbs = true;
      options.anrEnabled = true;
      options.enableWatchdogTerminationTracking = true;
      options.screenshotQuality = SentryScreenshotQuality.low;
    },
    appRunner: () => runApp(
      SentryScreenshotWidget(
        child: MultiProvider(
          providers:  [
            ChangeNotifierProvider(create: (_) => AuthController()),
            ChangeNotifierProxyProvider<AuthController, UserController>(
              create: (_) => UserController(),
              update: (_, authController, userController) {
                userController ??= UserController();
                userController.updateCurrentUser(authController.currentUser);
                return userController;
              },
            ),
            ChangeNotifierProvider(create: (_) => RestaurantController()),
            ChangeNotifierProvider(create: (_) => SocialMediaController()),
          ],
          child: const MyApp(),
        ),
      )
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    return OverlaySupport.global(
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'BSB Eats',
        theme: appTheme,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [
          Locale('pt', 'BR'),
          Locale('pt')
        ],
        debugShowCheckedModeBanner: false,
        home: StreamBuilder(
          stream: authController.authStateChanges,
          builder: (context, asyncSnapshot) => const InitialSplashScreen()
        ),
        routes: AppRoutes.routes,
        onGenerateRoute: (settings) => AppRoutes.generateRoute(settings),
      ),
    );
  }
}