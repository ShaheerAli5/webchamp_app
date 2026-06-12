import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../ui/screens/auth/login_screen.dart';
import '../ui/screens/auth/signup_screen.dart';
import '../ui/screens/auth/forgot_password_screen.dart';
import '../ui/screens/auth/verify_email_screen.dart';
import '../ui/screens/auth/reset_password_screen.dart';
import '../ui/screens/main_screen.dart';
import '../ui/screens/profile/profile_screen.dart';
import '../ui/screens/settings/settings_screen.dart';
import '../ui/screens/campaigns/create_campaign_screen.dart';
import '../ui/screens/contacts/add_contact_screen.dart';
import '../ui/screens/contacts/upload_csv_screen.dart';
import '../ui/screens/chat/individual_chat_screen.dart';
import '../ui/screens/home/home_screen.dart';
import '../ui/screens/campaigns/campaigns_screen.dart';
import '../ui/screens/chat/chat_screen.dart';
import '../ui/screens/contacts/contacts_screen.dart';
import '../ui/screens/more/more_screen.dart';
import '../ui/screens/templates/templates_screen.dart';
import '../ui/screens/templates/add_template_screen.dart';
import '../ui/screens/bot_replies/bot_list_screen.dart';
import '../ui/screens/bot_replies/simple_bot_reply_screen.dart';
import '../ui/screens/bot_replies/advance_interactive_bot_reply_screen.dart';
import '../ui/screens/bot_replies/template_bot_reply_screen.dart';
import '../ui/screens/bot_replies/media_bot_reply_screen.dart';
import '../ui/screens/bot_replies/bot_flows_screen.dart';
import '../ui/screens/bot_replies/add_bot_flow_screen.dart';
import '../ui/screens/team/team_members_screen.dart';
import '../ui/screens/team/add_team_member_screen.dart';
import '../ui/screens/more/subscription_screen.dart';
import '../ui/screens/more/message_log_screen.dart';
import '../ui/screens/more/message_log_detail_screen.dart';
import '../ui/screens/settings/general_settings_screen.dart';
import '../ui/screens/settings/bot_settings_screen.dart';

import '../ui/screens/chat/create_new_list_screen.dart';
import '../ui/screens/chat/select_contacts_screen.dart';
import '../ui/screens/chat/call_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String campaigns = '/campaigns';
  static const String chat = '/chat';
  static const String contacts = '/contacts';
  static const String more = '/more';
  
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String verifyEmail = '/verify-email';
  static const String resetPassword = '/reset-password';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String createCampaign = '/create-campaign';
  static const String addContact = '/add-contact';
  static const String editContact = '/edit-contact';
  static const String uploadCsv = '/upload-csv';
  static const String individualChat = '/chat-detail/:uid/:name';
  static const String call = '/call/:channelName/:isVideo';
  static const String createNewList = '/create-new-list';
  static const String selectContacts = '/select-contacts';
  static const String templates = '/templates';
  static const String addTemplate = '/add-template';
  static const String botList = '/bot-list';
  static const String simpleBotReply = '/simple-bot-reply';
  static const String advanceInteractiveBotReply = '/advance-interactive-bot-reply';
  static const String templateBotReply = '/template-bot-reply';
  static const String mediaBotReply = '/media-bot-reply';
  static const String botFlows = '/bot-flows';
  static const String addBotFlow = '/add-bot-flow';
  static const String teamMembers = '/team-members';
  static const String addTeamMember = '/add-team-member';
  static const String subscription = '/subscription';
  static const String messageLog = '/message-log';
  static const String messageLogDetail = '/message-log-detail';
  static const String generalSettings = '/general-settings';
  static const String botSettings = '/bot-settings';

  static final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: home,
      navigatorKey: _rootNavigatorKey,
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isLoggedIn = authProvider.isLoggedIn;
        final isAuthRoute = state.matchedLocation == login || state.matchedLocation == signup || state.matchedLocation == forgotPassword;

        print('--- ROUTER REDIRECT ---');
        print('Location: ${state.matchedLocation}');
        print('isLoggedIn: $isLoggedIn');
        print('isAuthRoute: $isAuthRoute');

        if (!isLoggedIn && !isAuthRoute) {
          print('Redirecting to LOGIN');
          return login;
        }
        if (isLoggedIn && isAuthRoute) {
          print('Redirecting to HOME');
          return home;
        }
        print('No redirection needed');
        return null;
      },
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainScreen(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: home,
                  builder: (context, state) => const HomeScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: campaigns,
                  builder: (context, state) => const CampaignsScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: chat,
                  builder: (context, state) => const ChatScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: contacts,
                  builder: (context, state) => const ContactsScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: more,
                  builder: (context, state) => const MoreScreen(),
                ),
              ],
            ),
          ],
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
          path: forgotPassword,
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: verifyEmail,
          builder: (context, state) => const VerifyEmailScreen(),
        ),
        GoRoute(
          path: resetPassword,
          builder: (context, state) => const ResetPasswordScreen(),
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
          path: editContact,
          builder: (context, state) {
            final contactData = state.extra as Map<String, dynamic>?;
            return AddContactScreen(contactData: contactData);
          },
        ),
        GoRoute(
          path: uploadCsv,
          builder: (context, state) => const UploadCsvScreen(),
        ),
        GoRoute(
          path: createNewList,
          builder: (context, state) => const CreateNewListScreen(),
        ),
        GoRoute(
          path: selectContacts,
          builder: (context, state) => const SelectContactsScreen(),
        ),
        GoRoute(
          path: templates,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return TemplatesScreen(extra: extra);
          },
        ),
        GoRoute(
          path: addTemplate,
          builder: (context, state) => const AddTemplateScreen(),
        ),
        GoRoute(
          path: botList,
          builder: (context, state) => const BotListScreen(),
        ),
        GoRoute(
          path: simpleBotReply,
          builder: (context, state) {
            final botData = state.extra as Map<String, dynamic>?;
            return SimpleBotReplyScreen(botData: botData);
          },
        ),
        GoRoute(
          path: advanceInteractiveBotReply,
          builder: (context, state) {
            final botData = state.extra as Map<String, dynamic>?;
            return AdvanceInteractiveBotReplyScreen(botData: botData);
          },
        ),
        GoRoute(
          path: templateBotReply,
          builder: (context, state) {
            final botData = state.extra as Map<String, dynamic>?;
            return TemplateBotReplyScreen(botData: botData);
          },
        ),
        GoRoute(
          path: mediaBotReply,
          builder: (context, state) {
            final botData = state.extra as Map<String, dynamic>?;
            return MediaBotReplyScreen(botData: botData);
          },
        ),
        GoRoute(
          path: botFlows,
          builder: (context, state) => const BotFlowsScreen(),
        ),
        GoRoute(
          path: addBotFlow,
          builder: (context, state) => const AddBotFlowScreen(),
        ),
        GoRoute(
          path: teamMembers,
          builder: (context, state) => const TeamMembersScreen(),
        ),
        GoRoute(
          path: addTeamMember,
          builder: (context, state) {
            final userData = state.extra as Map<String, dynamic>?;
            return AddTeamMemberScreen(userData: userData);
          },
        ),
        GoRoute(
          path: subscription,
          builder: (context, state) => const SubscriptionScreen(),
        ),
        GoRoute(
          path: messageLog,
          builder: (context, state) => const MessageLogScreen(),
        ),
        GoRoute(
          path: messageLogDetail,
          builder: (context, state) {
            final logData = state.extra as Map<String, dynamic>;
            return MessageLogDetailScreen(logData: logData);
          },
        ),
        GoRoute(
          path: generalSettings,
          builder: (context, state) => const GeneralSettingsScreen(),
        ),
        GoRoute(
          path: botSettings,
          builder: (context, state) => const BotSettingsScreen(),
        ),
        GoRoute(
          path: individualChat,
          builder: (context, state) {
            final uid = state.pathParameters['uid'] ?? '';
            final name = state.pathParameters['name'] ?? 'Chat';
            return IndividualChatScreen(uid: uid, name: name);
          },
        ),
        GoRoute(
          path: call,
          builder: (context, state) {
            final channelName = state.pathParameters['channelName'] ?? '';
            final isVideo = state.pathParameters['isVideo'] == 'true';
            return CallScreen(channelName: channelName, isVideo: isVideo);
          },
        ),
      ],
    );
  }
}
