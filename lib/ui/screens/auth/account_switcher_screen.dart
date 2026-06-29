import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/utils/helpers.dart';
import '../../../features/auth/data/models/saved_account_model.dart';

class AccountSwitcherScreen extends StatefulWidget {
  const AccountSwitcherScreen({super.key});

  @override
  State<AccountSwitcherScreen> createState() => _AccountSwitcherScreenState();
}

class _AccountSwitcherScreenState extends State<AccountSwitcherScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isSwitching = false;

  Future<bool> _authenticate() async {
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) return true; // Proceed if not supported

      return await auth.authenticate(
        localizedReason: 'Authenticate to switch account',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (e) {
      debugPrint('Biometric error: $e');
      return false;
    }
  }

  Future<void> _loginInstantly(SavedAccountModel account) async {
    if (_isSwitching) return;
    
    // 1. Authenticate user before switching
    final didAuth = await _authenticate();
    if (!didAuth) return;

    setState(() => _isSwitching = true);
    final authProvider = context.read<AuthProvider>();

    try {
      // 2. Try switching using saved tokens (handles refresh automatically)
      await authProvider.switchAccount(account.userId);
      
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
        // If it requires re-auth, navigate to login with email pre-filled if possible
        context.push('/login', extra: {'email': account.email});
      }
    } finally {
      if (mounted) setState(() => _isSwitching = false);
    }
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
              if (_isSwitching) ...[
                SizedBox(height: 16.h),
                const LinearProgressIndicator(),
              ],
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
                        final email = account.email;
                        final name = account.name;
                        final isActive = account.isCurrentAccount;
                        final needsReauth = account.needsReauth;

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20.r),
                            border: isActive ? Border.all(color: const Color(0xFF007176), width: 2) : null,
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
                                    backgroundImage: account.profileImage != null ? NetworkImage(account.profileImage!) : null,
                                    child: account.profileImage == null ? Text(
                                      Helpers.getInitial(name),
                                      style: TextStyle(
                                        color: const Color(0xFF007176),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18.sp,
                                      ),
                                    ) : null,
                                  ),
                                  SizedBox(width: 16.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color(0xFF151515),
                                                ),
                                              ),
                                            ),
                                            if (isActive) ...[
                                              SizedBox(width: 8.w),
                                              _buildBadge('Active', const Color(0xFF007176)),
                                            ],
                                            if (needsReauth) ...[
                                              SizedBox(width: 8.w),
                                              _buildBadge('Expired', Colors.orange),
                                            ],
                                          ],
                                        ),
                                        Text(
                                          email,
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: const Color(0xFF667085),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _showRemoveDialog(context, provider, account),
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
                  onPressed: () => context.push('/login', extra: {'isAddingAccount': true}),
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

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.sp,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showRemoveDialog(BuildContext context, AuthProvider provider, SavedAccountModel account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Account?'),
        content: Text('Are you sure you want to remove ${account.name} from this device?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              provider.removeSavedAccount(account.userId);
              Navigator.pop(context);
            },
            child: const Text('REMOVE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
