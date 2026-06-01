import 'package:go_router/go_router.dart';
import '../ui/screens/ready_to_build_screen.dart';
import '../ui/screens/auth/login_screen.dart';
import '../ui/screens/auth/signup_screen.dart';
import '../ui/screens/home/home_screen.dart';
import '../ui/screens/profile/profile_screen.dart';
import '../ui/screens/settings/settings_screen.dart';

class AppRoutes {
  static const String ready = '/ready';
  static const String home = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String profile = '/profile';
  static const String settings = '/settings';

  static final GoRouter router = GoRouter(
    initialLocation: ready,
    routes: [
      GoRoute(
        path: ready,
        builder: (context, state) => const ReadyToBuildScreen(),
      ),
      GoRoute(
        path: home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
