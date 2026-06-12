import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          child: Column(
            children: [
              SizedBox(height: 20.h),
              _buildLogo(),
              SizedBox(height: 8.h),
              Text(
                'WabChamp',
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  fontFamily: 'Inter',
                ),
              ),
              Text(
                'AdminPortal',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Secure access for administrators',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
              SizedBox(height: 32.h),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(24.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),
                      
                      _SearchStyleInputField(
                        hint: 'First Name', 
                        controller: _firstNameController, 
                        prefixIcon: Iconsax.user,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'First name is required';
                          if (value.trim().length < 2) return 'First name must be at least 2 characters';
                          return null;
                        },
                      ),
                      _SearchStyleInputField(
                        hint: 'Last Name', 
                        controller: _lastNameController, 
                        prefixIcon: Iconsax.user,
                        validator: (value) => (value == null || value.isEmpty) ? 'Last name is required' : null,
                      ),
                      _SearchStyleInputField(
                        hint: 'Username', 
                        controller: _usernameController, 
                        prefixIcon: Iconsax.personalcard,
                        validator: (value) => (value == null || value.isEmpty) ? 'Username is required' : null,
                      ),
                      _SearchStyleInputField(
                        hint: 'Email', 
                        controller: _emailController, 
                        prefixIcon: Iconsax.sms,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Email is required';
                          if (!value.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      _SearchStyleInputField(
                        hint: '923001234567', 
                        controller: _mobileController, 
                        prefixIcon: Iconsax.mobile,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(15),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Mobile number is required';
                          if (value.length < 10) return 'Enter a valid mobile number with country code';
                          return null;
                        },
                      ),
                      _SearchStyleInputField(
                        hint: 'BUSINESS NAME', 
                        controller: _vendorTitleController, 
                        prefixIcon: Iconsax.user,
                        validator: (value) => (value == null || value.isEmpty) ? 'Business name is required' : null,
                      ),
                      _SearchStyleInputField(
                        hint: 'Password', 
                        controller: _passwordController, 
                        isPassword: true,
                        obscureText: _obscurePassword,
                        onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                        prefixIcon: Iconsax.key,
                        validator: (value) => (value == null || value.isEmpty) ? 'Password is required' : null,
                      ),
                      _SearchStyleInputField(
                        hint: 'Confirm Password', 
                        controller: _confirmPasswordController, 
                        isPassword: true,
                        obscureText: _obscureConfirmPassword,
                        onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        prefixIcon: Iconsax.key_square,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Confirm password is required';
                          if (value != _passwordController.text) return 'Passwords do not match';
                          return null;
                        },
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
                            activeColor: AppColors.primary,
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
                                color: AppColors.textBody,
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
                              if (!_formKey.currentState!.validate()) {
                                return;
                              }

                              if (!_acceptTerms) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please accept the Terms and Conditions')),
                                );
                                return;
                              }

                              final response = await auth.register(
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
                                final isSuccessful = response != null && (
                                  response['reaction'] == 1 || 
                                  response['reaction'] == '1' ||
                                  response['status'] == 'success' ||
                                  response['result'] == 'success' ||
                                  response['success'] == true
                                );

                                if (isSuccessful) {
                                  final data = response!['data'];
                                  final activationRequired = data != null && (
                                    data['activation_required'] == true ||
                                    data['activation_required'] == 1 ||
                                    data['activation_required'] == '1'
                                  );
                                  
                                  final message = response['message'] ?? 'Registration successful! Please check your email to activate your account.';
                                  
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                                      title: Text(
                                        activationRequired ? 'Activation Required' : 'Account Created',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                      content: Text(
                                        message,
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context); // Close dialog
                                            context.go('/login'); // Navigate to login
                                          },
                                          child: Text(
                                            'OK',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                              fontFamily: 'Inter',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(auth.errorMessage ?? response?['message'] ?? 'Registration failed'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26.r),
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
                            color: AppColors.textPrimary,
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
                              color: AppColors.primary,
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
                          color: AppColors.textSecondary,
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
                                  color: AppColors.primary,
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
                                  color: AppColors.primary,
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
}

class _SearchStyleInputField extends StatefulWidget {
  final String hint;
  final TextEditingController controller;
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? onToggleVisibility;
  final IconData? prefixIcon;
  final double? bottomPadding;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _SearchStyleInputField({
    required this.hint,
    required this.controller,
    this.isPassword = false,
    this.obscureText = false,
    this.onToggleVisibility,
    this.prefixIcon,
    this.bottomPadding,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  @override
  State<_SearchStyleInputField> createState() => _SearchStyleInputFieldState();
}

class _SearchStyleInputFieldState extends State<_SearchStyleInputField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          constraints: BoxConstraints(minHeight: 52.h),
          decoration: BoxDecoration(
            color: _isFocused ? const Color(0xFFF0F9FA) : Colors.white,
            borderRadius: BorderRadius.circular(_isFocused ? 30.r : 16.r),
            border: Border.all(
              color: _isFocused ? AppColors.primary : const Color(0xFFEAECF0),
              width: _isFocused ? 1.5 : 1,
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              if (widget.prefixIcon != null) ...[
                Icon(
                  widget.prefixIcon,
                  color: _isFocused ? AppColors.primary : const Color(0xFF98A2B3),
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
              ],
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  obscureText: widget.obscureText,
                  keyboardType: widget.keyboardType,
                  inputFormatters: widget.inputFormatters,
                  validator: widget.validator,
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: TextStyle(
                      color: const Color(0xFF98A2B3),
                      fontSize: 14.sp,
                      fontFamily: 'Inter',
                    ),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14.sp,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              if (widget.isPassword)
                GestureDetector(
                  onTap: widget.onToggleVisibility,
                  child: Icon(
                    widget.obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: const Color(0xFF667085),
                    size: 20.sp,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: widget.bottomPadding ?? 16.h),
      ],
    );
  }
}
