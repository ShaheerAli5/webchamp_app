import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/network/api_client.dart';
import 'core/storage/secure_storage_service.dart';
import 'features/auth/data/services/auth_api_service.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'providers/auth_provider.dart';
import 'routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final secureStorage = SecureStorageService();
  final apiClient = ApiClient(secureStorage);
  final authService = AuthApiService(apiClient);
  final authRepository = AuthRepository(authService, secureStorage);
  final authProvider = AuthProvider(authRepository);

  // Initialize auth status before running app
  await authProvider.checkAuthStatus();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
      ],
      child: MyApp(authProvider: authProvider),
    ),
  );
}

class MyApp extends StatelessWidget {
  final AuthProvider authProvider;
  
  const MyApp({super.key, required this.authProvider});

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
          routerConfig: AppRoutes.createRouter(authProvider),
        );
      },
    );
  }
}
