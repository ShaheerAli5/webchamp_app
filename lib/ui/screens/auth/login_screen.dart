import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../routes/app_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo and Header
                _buildLogo(),
                SizedBox(height: 12.h),
                Text(
                  'WabChamp',
                  style: TextStyle(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF007176),
                    fontFamily: 'Inter',
                  ),
                ),
                Text(
                  'AdminPortal',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF151515),
                    fontFamily: 'Inter',
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'Secure access for administrators',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: const Color(0xFF667085),
                    fontFamily: 'Inter',
                  ),
                ),
                SizedBox(height: 32.h),

                // Login Card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF151515),
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),
                      
                      _buildInputField('EMAIL ADDRESS', 'admin@company.com', _emailController),
                      _buildInputField(
                        'PASSWORD', 
                        '••••••••', 
                        _passwordController, 
                        isPassword: true,
                        obscureText: _obscurePassword,
                        onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () => context.push(AppRoutes.forgotPassword),
                          child: Text(
                            'Forgot password?',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: const Color(0xFF007176),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 32.h),
                      Consumer<AuthProvider>(
                        builder: (context, auth, child) {
                          return SizedBox(
                            width: double.infinity,
                            height: 52.h,
                            child: ElevatedButton(
                              onPressed: auth.isLoading ? null : () async {
                                await auth.login(
                                  _emailController.text,
                                  _passwordController.text,
                                );
                                if (context.mounted) {
                                  context.go('/');
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF007176),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18.r),
                                ),
                                elevation: 0,
                              ),
                              child: auth.isLoading 
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                            ),
                          );
                        },
                      ),
                      
                      SizedBox(height: 20.h),
                      Center(
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: const Color(0xFF151515),
                              fontFamily: 'Inter',
                            ),
                            children: [
                              const TextSpan(text: 'If you don\'t have an Account yet? '),
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () => context.go('/signup'),
                                  child: Text(
                                    'Create One! Its Free',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/images/logo.png',
      width: 128.w,
      height: 54.h,
      fit: BoxFit.contain,
    );
  }

  Widget _buildInputField(
    String label, 
    String hint, 
    TextEditingController controller, {
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF475467),
            fontFamily: 'Inter',
            letterSpacing: 0.5.sp,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          height: 48.h,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F4F4),
            borderRadius: BorderRadius.circular(12.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscureText,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: const Color(0xFF98A2B3),
                      fontSize: 14.sp,
                      fontFamily: 'Inter',
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: TextStyle(
                    color: const Color(0xFF151C27),
                    fontSize: 14.sp,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              if (isPassword)
                GestureDetector(
                  onTap: onToggleVisibility,
                  child: Icon(
                    obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: const Color(0xFF667085),
                    size: 20.sp,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
      ],
    );
  }
}
