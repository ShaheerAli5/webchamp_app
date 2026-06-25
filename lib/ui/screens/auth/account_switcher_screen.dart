import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/utils/helpers.dart';

class AccountSwitcherScreen extends StatefulWidget {
  const AccountSwitcherScreen({super.key});

  @override
  State<AccountSwitcherScreen> createState() => _AccountSwitcherScreenState();
}

class _AccountSwitcherScreenState extends State<AccountSwitcherScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isSwitching = false;
  Map<String, String> _revealedPasswords = {};

  Future<void> _handlePasswordReveal(String email) async {
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric authentication not supported on this device')),
        );
        return;
      }

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Authenticate to view your saved password',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (didAuthenticate) {
        final password = await context.read<AuthProvider>().getSavedPassword(email);
        if (password != null) {
          setState(() {
            _revealedPasswords[email] = password;
          });
        }
      }
    } catch (e) {
      debugPrint('Biometric error: $e');
    }
  }

  Future<void> _loginInstantly(Map<String, dynamic> account) async {
    if (_isSwitching) return;
    
    setState(() => _isSwitching = true);
    final email = account['email'];
    final authProvider = context.read<AuthProvider>();
    final password = await authProvider.getSavedPassword(email);

    if (password != null) {
      final success = await authProvider.login(email, password, saveAccount: false);
      if (success && mounted) {
        context.go('/');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login failed. Please enter password manually.')),
        );
        context.push('/login');
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved password not found. Please log in again.')),
      );
      context.push('/login');
    }
    
    if (mounted) setState(() => _isSwitching = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 40.h),
              Text(
                'Switch Account',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF151515),
                ),
              ),
              Text(
                'Choose an account to log in instantly',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF667085),
                ),
              ),
              SizedBox(height: 32.h),
              Expanded(
                child: Consumer<AuthProvider>(
                  builder: (context, provider, child) {
                    final accounts = provider.savedAccounts;
                    
                    if (accounts.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.account_circle_outlined, size: 64.sp, color: Colors.grey),
                            SizedBox(height: 16.h),
                            const Text('No saved accounts found'),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: accounts.length,
                      separatorBuilder: (_, __) => SizedBox(height: 16.h),
                      itemBuilder: (context, index) {
                        final account = accounts[index];
                        final email = account['email'] ?? '';
                        final name = account['name'] ?? account['username'] ?? 'User';
                        final isRevealed = _revealedPasswords.containsKey(email);

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: InkWell(
                            onTap: () => _loginInstantly(account),
                            borderRadius: BorderRadius.circular(20.r),
                            child: Padding(
                              padding: EdgeInsets.all(16.w),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24.r,
                                    backgroundColor: const Color(0xFF007176).withOpacity(0.1),
                                    child: Text(
                                      Helpers.getInitial(name),
                                      style: TextStyle(
                                        color: const Color(0xFF007176),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18.sp,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 16.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF151515),
                                          ),
                                        ),
                                        Text(
                                          email,
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: const Color(0xFF667085),
                                          ),
                                        ),
                                        SizedBox(height: 4.h),
                                        Row(
                                          children: [
                                            Text(
                                              isRevealed ? _revealedPasswords[email]! : '••••••••',
                                              style: TextStyle(
                                                fontSize: 14.sp,
                                                color: Colors.black,
                                                letterSpacing: isRevealed ? 0 : 2,
                                              ),
                                            ),
                                            SizedBox(width: 8.w),
                                            GestureDetector(
                                              onTap: () => _handlePasswordReveal(email),
                                              child: Icon(
                                                isRevealed ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                                size: 16.sp,
                                                color: const Color(0xFF007176),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Remove Account?'),
                                          content: Text('Are you sure you want to remove $name from this device?'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
                                            TextButton(
                                              onPressed: () {
                                                provider.removeSavedAccount(account['id'].toString());
                                                Navigator.pop(context);
                                              },
                                              child: const Text('REMOVE', style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/login'),
                  icon: const Icon(Icons.add),
                  label: Text(
                    'Add Another Account',
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF007176),
                    side: const BorderSide(color: Color(0xFF007176)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
                  ),
                ),
              ),
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }
}
