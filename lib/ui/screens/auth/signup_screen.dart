import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _vendorTitleController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _mobileController.dispose();
    _vendorTitleController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          child: Column(
            children: [
              SizedBox(height: 20.h),
              // Logo and Header
              _buildLogo(),
              SizedBox(height: 8.h),
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

              // Create Account Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF151515),
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    
                    _buildInputField('FIRST NAME', 'Enter your first name', _firstNameController),
                    _buildInputField('LAST NAME', 'Enter your last name', _lastNameController),
                    _buildInputField('WORK EMAIL', 'email@company.com', _emailController),
                    _buildInputField('USERNAME', 'johndoe123', _usernameController),
                    _buildInputField('MOBILE NUMBER', 'e.g. 03001234567', _mobileController),
                    _buildInputField('VENDOR TITLE', 'e.g. My Business Name', _vendorTitleController),
                    _buildInputField(
                      'PASSWORD', 
                      '••••••••', 
                      _passwordController, 
                      isPassword: true,
                      obscureText: _obscurePassword,
                      onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    _buildInputField(
                      'CONFIRM PASSWORD', 
                      '••••••••', 
                      _confirmPasswordController, 
                      isPassword: true,
                      obscureText: _obscureConfirmPassword,
                      onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),

                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        SizedBox(
                          height: 24.w,
                          width: 24.w,
                          child: Checkbox(
                            value: _acceptTerms,
                            onChanged: (value) => setState(() => _acceptTerms = value ?? false),
                            activeColor: const Color(0xFF007176),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.r)),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                            child: Text(
                              'I accept the Terms and Conditions',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: const Color(0xFF475467),
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 24.h),
                    Consumer<AuthProvider>(
                      builder: (context, auth, child) {
                        return SizedBox(
                          width: double.infinity,
                          height: 52.h,
                          child: ElevatedButton(
                            onPressed: auth.isLoading ? null : () async {
                              if (_firstNameController.text.isEmpty || 
                                  _lastNameController.text.isEmpty || 
                                  _emailController.text.isEmpty || 
                                  _usernameController.text.isEmpty ||
                                  _mobileController.text.isEmpty ||
                                  _vendorTitleController.text.isEmpty ||
                                  _passwordController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please fill all fields')),
                                );
                                return;
                              }
                              
                              if (_passwordController.text != _confirmPasswordController.text) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Passwords do not match')),
                                );
                                return;
                              }

                              if (!_acceptTerms) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please accept the Terms and Conditions')),
                                );
                                return;
                              }

                              final success = await auth.register(
                                firstName: _firstNameController.text.trim(),
                                lastName: _lastNameController.text.trim(),
                                email: _emailController.text.trim(),
                                username: _usernameController.text.trim(),
                                mobileNumber: _mobileController.text.trim(),
                                vendorTitle: _vendorTitleController.text.trim(),
                                password: _passwordController.text,
                                passwordConfirmation: _confirmPasswordController.text,
                                termsAndConditions: _acceptTerms,
                              );
                              
                              if (context.mounted) {
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Registration successful! Please login.')),
                                  );
                                  context.go('/login');
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(auth.errorMessage ?? 'Registration failed')),
                                  );
                                }
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
                                    'Sign Up',
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
                    
                    SizedBox(height: 16.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: const Color(0xFF151515),
                            fontFamily: 'Inter',
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF151515),
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 24.h),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFF667085),
                          fontFamily: 'Inter',
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(text: 'By creating an account, you agree to our '),
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: () {},
                              child: Text(
                                'Terms of Service',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: const Color(0xFF007176),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                          const TextSpan(text: ' and '),
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: () {},
                              child: Text(
                                'Privacy Policy',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: const Color(0xFF007176),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
