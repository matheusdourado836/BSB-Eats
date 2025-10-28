import 'package:bsb_eats/screens/admin/admin_dashboard_screen.dart';
import 'package:bsb_eats/screens/admin/pages/add_restaurant_screen.dart';
import 'package:bsb_eats/screens/admin/pages/admin_notifications_screen.dart';
import 'package:bsb_eats/screens/admin/pages/create_restaurant_screen.dart';
import 'package:bsb_eats/screens/admin/pages/edit_restaurant_screen.dart';
import 'package:bsb_eats/screens/admin/pages/feedbacks_screen.dart';
import 'package:bsb_eats/screens/admin/pages/manage_users_screen.dart';
import 'package:bsb_eats/screens/auth/login/login_screen.dart';
import 'package:bsb_eats/screens/auth/register/email_confirmation_screen.dart';
import 'package:bsb_eats/screens/auth/register/register_screen.dart';
import 'package:bsb_eats/screens/coupons/coupons_screen.dart';
import 'package:bsb_eats/screens/favorites/favorites_screen.dart';
import 'package:bsb_eats/screens/guest/guest_screen.dart';
import 'package:bsb_eats/screens/home/home_screen.dart';
import 'package:bsb_eats/screens/home/tabs/profile_tab.dart';
import 'package:bsb_eats/screens/notifications/notifications_screen.dart';
import 'package:bsb_eats/screens/onboarding/onboarding_screen.dart';
import 'package:bsb_eats/screens/posts/edit_post_screen.dart';
import 'package:bsb_eats/screens/posts/post_detail_screen.dart';
import 'package:bsb_eats/screens/posts/upload_screen.dart';
import 'package:bsb_eats/screens/splash/initial_splash_screen.dart';
import 'package:bsb_eats/screens/user_profile/user_feed/user_feed_screen.dart';
import 'package:bsb_eats/shared/model/restaurante.dart';
import 'package:bsb_eats/shared/model/user.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import '../screens/admin/pages/manage_restaurants_screen.dart';
import '../screens/details/restaurant_details_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/user_profile/user_profile_config/user_profile_config_screen.dart';

class AppRoutes {
  static const Duration duration500 = Duration(milliseconds: 500);
  static const Duration duration300 = Duration(milliseconds: 300);
  static const String home = '/home';
  static const String onboarding = '/onboarding';
  static const String guest = '/guest';
  static const String login = '/login';
  static const String register = '/register';
  static const String emailConfirmation = '/email_confirmation';
  static const String coupons = '/coupons';
  static const String userProfile = '/user_profile';
  static const String userProfileConfig = '/user_profile_config';
  static const String profile = '/profile';
  static const String admin = '/admin';
  static const String manageRestaurants = '/admin/manage_restaurants';
  static const String addRestaurant = '/admin/manage_restaurants/add_restaurant';
  static const String createRestaurant = '/admin/manage_restaurants/create_restaurant';
  static const String editRestaurant = '/admin/manage_restaurants/edit_restaurant';
  static const String manageUsers = '/admin/manage_users';
  static const String feedbacks = '/admin/feedbacks';
  static const String adminNotifications = '/admin/notifications';
  static const String userFeed = '/user_feed';
  static const String settings = '/settings';
  static const String about = '/about';
  static const String restaurantDetails = '/restaurant_details';
  static const String favorites = '/favorites';
  static const String notifications = '/notifications';
  static const String upload = '/upload';
  static const String editPost = '/edit_post';
  static const String postDetails = '/post_details';

  static Map<String, WidgetBuilder> routes = {
    
  };

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '');
    if(uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'restaurant') {
      final placeId = uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;
      return PageTransition(
        type: PageTransitionType.rightToLeftWithFade,
        child: InitialSplashScreen(placeId: placeId),
      );
    }
    if(uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'post') {
      final postId = uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;
      return PageTransition(
        type: PageTransitionType.rightToLeftWithFade,
        child: InitialSplashScreen(postId: postId),
      );
    }
    if(uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'splash') {
      final userId = uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;
      return PageTransition(
        type: PageTransitionType.rightToLeftWithFade,
        child: InitialSplashScreen(userId: userId),
      );
    }
    switch (settings.name) {
      case home:
        return PageTransition(
          type: PageTransitionType.fade, 
          child: const HomeScreen()
        );
      case onboarding:
        return PageTransition(
          type: PageTransitionType.fade,
          child: const OnboardingScreen()
        );
      case guest:
        return PageTransition(
          type: PageTransitionType.fade,
          child: const GuestScreen(),
        );
      case login:
        return PageTransition(
          type: PageTransitionType.fade,
          child: const LoginScreen(),
        );
      case restaurantDetails:
        final placeId = settings.arguments as String?;
        return PageTransition(
          type: PageTransitionType.rightToLeftWithFade,
          child: RestaurantDetailsScreen(placeId: placeId),
        );
      case register:
        return PageTransition(
          type: PageTransitionType.bottomToTop,
          child: const RegisterScreen(),
        );
      case emailConfirmation:
        Map<String, dynamic>? map = settings.arguments as Map<String, dynamic>?;
        return PageTransition(
          type: PageTransitionType.fade,
          child: EmailConfirmationScreen(user: map?["user"], password: map?["password"]),
        );
      case coupons:
        return PageTransition(
          type: PageTransitionType.rightToLeftWithFade,
          child: const CouponsScreen(),
        );
      case userFeed:
        Map<String, dynamic>? map = settings.arguments as Map<String, dynamic>?;
        final posts = map?["posts"];
        final index = map?["index"];
        final eventBus = map?["eventBus"];
        return PageTransition(
          type: PageTransitionType.rightToLeftWithFade,
          child: UserFeedScreen(posts: posts, index: index, eventBus: eventBus),
        );
      case userProfileConfig:
        return PageTransition(
          type: PageTransitionType.rightToLeftWithFade,
          child: const ProfileConfigScreen(),
        );
      case userProfile:
        return PageTransition(
          type: PageTransitionType.rightToLeftWithFade,
          child: const ProfileTab(),
        );
      case profile:
        final userId = settings.arguments as String;
        return PageTransition(
          type: PageTransitionType.fade,
          child: ProfileScreen(userId: userId),
        );
      case admin:
        return PageTransition(
          type: PageTransitionType.fade,
          child: AdminDashboardScreen(),
        );
      case manageUsers:
        return PageTransition(
          type: PageTransitionType.rightToLeftWithFade,
          child: ManageUsersScreen(),
        );
      case feedbacks:
        return PageTransition(
          type: PageTransitionType.rightToLeftWithFade,
          child: FeedbacksScreen(),
        );
      case adminNotifications:
        return PageTransition(
          type: PageTransitionType.rightToLeftWithFade,
          child: AdminNotificationsScreen(),
        );
      case manageRestaurants:
        return PageTransition(
          type: PageTransitionType.rightToLeftWithFade,
          child: ManageRestaurantsScreen(),
        );
      case createRestaurant:
        return PageTransition(
          type: PageTransitionType.rightToLeftWithFade,
          child: CreateRestaurantScreen(),
        );
      case addRestaurant:
        final user = settings.arguments as MyUser;
        return PageTransition(
          type: PageTransitionType.rightToLeftWithFade,
          child: AddRestaurantScreen(user: user),
        );
      case editRestaurant:
        final restaurant = settings.arguments as Restaurante;
        return PageTransition(
          type: PageTransitionType.rightToLeftWithFade,
          child: EditRestaurantScreen(restaurant: restaurant),
        );
      case favorites:
        return PageTransition(
          type: PageTransitionType.rightToLeftWithFade,
          child: const FavoritesScreen(),
        );
      case notifications:
        final eventBus = settings.arguments;
        return PageTransition(
          type: PageTransitionType.rightToLeftWithFade,
          child: NotificationsScreen(eventBus: eventBus as EventBus?),
        );
      case upload:
        final map = settings.arguments as Map<String, dynamic>?;
        return PageTransition(
          type: PageTransitionType.rightToLeftWithFade,
          duration: duration300,
          child: UploadScreen(images: map?["files"], eventBus: map?["eventBus"]),
        );
      case editPost:
        final map = settings.arguments as Map<String, dynamic>?;
        return PageTransition(
          type: PageTransitionType.fade,
          child: EditPostScreen(post: map?["post"]),
        );
      case postDetails:
        final postId = settings.arguments as String;
        return PageTransition(
          type: PageTransitionType.fade,
          child: PostDetailScreen(postId: postId),
        );
      case about:
        return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('About Page'))));
      default:
        debugPrint('Rota não encontrada: ${settings.name}');
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Não foi possível encontrar essa rota ${settings.name}'),
            ),
          ),
        );
    }
  }
}