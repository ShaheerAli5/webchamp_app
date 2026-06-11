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

  // Initialize auth status before running app
  await authProvider.checkAuthStatus();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: contactProvider),
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
