import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/network/api_client.dart';
import 'core/storage/secure_storage_service.dart';
import 'features/auth/data/services/auth_api_service.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'providers/auth_provider.dart';
import 'features/contacts/data/services/contact_api_service.dart';
import 'features/contacts/data/repositories/contact_repository.dart';
import 'features/contacts/presentation/providers/contact_provider.dart';
import 'features/contacts/presentation/providers/contact_group_provider.dart';
import 'routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final secureStorage = SecureStorageService();
  final apiClient = ApiClient(secureStorage);
  final authService = AuthApiService(apiClient);
  final authRepository = AuthRepository(authService, secureStorage);
  final authProvider = AuthProvider(authRepository);

  final contactService = ContactApiService(apiClient);
  final contactRepository = ContactRepository(contactService);
  final contactProvider = ContactProvider(contactRepository);
  final contactGroupProvider = ContactGroupProvider(contactRepository);

  // Link AuthProvider with other services
  authProvider.onLogout = () {
    debugPrint('🚪 [MAIN] User Logout - Cleaning up');
    apiClient.setCurrentUser(null);
    contactProvider.clearAllData();
    contactGroupProvider.clear();
  };

  authProvider.onLogin = (user, token) {
    debugPrint('🔑 [MAIN] User Login - Initializing for User ID: ${user.id}');
    apiClient.setCurrentUser(token, userId: user.id.toString());
    contactProvider.setActiveUser(user.id.toString());
    
    // Load cache first for speed, then fetch fresh in background
    contactProvider.loadCachedData().then((_) {
      // 🛡️ Disable auto-loading all contacts at startup to prevent 429 rate limits
      // This is especially important when the user has 2700+ contacts.
      contactProvider.getContacts(refresh: true, autoLoadAll: false);
      contactGroupProvider.fetchGroups(refresh: true);
    });
  };

  // Initialize auth status before running app
  await authProvider.checkAuthStatus();
  
  // Note: authProvider.onLogin is automatically triggered by checkAuthStatus() 
  // if already logged in, so we don't need manual initialization here anymore.

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: contactProvider),
        ChangeNotifierProvider.value(value: contactGroupProvider),
      ],
      child: MyApp(authProvider: authProvider),
    ),
  );
}

class MyApp extends StatefulWidget {
  final AuthProvider authProvider;
  
  const MyApp({super.key, required this.authProvider});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRoutes.createRouter(widget.authProvider);
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Wab Champ',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          routerConfig: _router,
        );
      },
    );
  }
}
