import 'package:go_router/go_router.dart';
import '../ui/screens/auth/login_screen.dart';
import '../ui/screens/auth/signup_screen.dart';
import '../ui/screens/main_screen.dart';
import '../ui/screens/profile/profile_screen.dart';
import '../ui/screens/settings/settings_screen.dart';
import '../ui/screens/campaigns/create_campaign_screen.dart';
import '../ui/screens/contacts/add_contact_screen.dart';
import '../ui/screens/contacts/upload_csv_screen.dart';
import '../ui/screens/chat/individual_chat_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String createCampaign = '/create-campaign';
  static const String addContact = '/add-contact';
  static const String uploadCsv = '/upload-csv';
  static const String individualChat = '/chat/:name';

  static final GoRouter router = GoRouter(
    initialLocation: home,
    routes: [
      GoRoute(
        path: home,
        builder: (context, state) => const MainScreen(),
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
      GoRoute(
        path: createCampaign,
        builder: (context, state) => const CreateCampaignScreen(),
      ),
      GoRoute(
        path: addContact,
        builder: (context, state) => const AddContactScreen(),
      ),
      GoRoute(
        path: uploadCsv,
        builder: (context, state) => const UploadCsvScreen(),
      ),
      GoRoute(
        path: individualChat,
        builder: (context, state) {
          final name = state.pathParameters['name'] ?? 'Chat';
          return IndividualChatScreen(name: name);
        },
      ),
    ],
  );
}
