import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:webchamp_app/main.dart';
import 'package:webchamp_app/providers/auth_provider.dart';
import 'package:webchamp_app/features/auth/data/repositories/auth_repository.dart';
import 'package:webchamp_app/features/auth/data/services/auth_api_service.dart';
import 'package:webchamp_app/features/auth/data/services/multi_account_service.dart';
import 'package:webchamp_app/core/network/api_client.dart';
import 'package:webchamp_app/core/storage/secure_storage_service.dart';
import 'package:webchamp_app/features/contacts/data/repositories/contact_repository.dart';
import 'package:webchamp_app/features/contacts/data/services/contact_api_service.dart';
import 'package:webchamp_app/features/contacts/presentation/providers/contact_provider.dart';
import 'package:webchamp_app/features/contacts/presentation/providers/contact_group_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Setup dependencies (Mocking would be better in a real scenario)
    final secureStorage = SecureStorageService();
    final multiAccountService = MultiAccountService(secureStorage);
    final apiClient = ApiClient(secureStorage);
    final authService = AuthApiService(apiClient);
    final authRepository = AuthRepository(authService, secureStorage, multiAccountService);
    final authProvider = AuthProvider(authRepository);
    
    final contactService = ContactApiService(apiClient);
    final contactRepository = ContactRepository(contactService);
    final contactProvider = ContactProvider(contactRepository);
    final contactGroupProvider = ContactGroupProvider(contactRepository);

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authProvider),
          ChangeNotifierProvider.value(value: contactProvider),
          ChangeNotifierProvider.value(value: contactGroupProvider),
        ],
        child: MyApp(authProvider: authProvider),
      ),
    );

    // Basic verification that the app starts
    expect(find.byType(MyApp), findsOneWidget);
  });
}
