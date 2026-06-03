import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../routes/app_routes.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool _has8Chars = false;
  bool _hasSpecialChar = false;
  bool _hasNumber = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePassword);
  }

  void _validatePassword() {
    final password = _passwordController.text;
    setState(() {
      _has8Chars = password.length >= 8;
      _hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
    });
  }

  @override
  void dispose() {
    _passwordController.removeListener(_validatePassword);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(56.h),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFEAECF0), width: 1),
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            titleSpacing: 0,
            title: Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  behavior: HitTestBehavior.opaque,
                  child: Icon(Icons.arrow_back, color: const Color(0xFF004D4F), size: 24.sp),
                ),
                SizedBox(width: 16.w),
                Text(
                  'AdminPortal',
                  style: TextStyle(
                    color: const Color(0xFF004D4F),
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(top: 48.h, left: 20.w, right: 20.w, bottom: 40.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reset Password',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF191C1E),
                  fontFamily: 'Plus Jakarta Sans',
                  height: 1.4,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Create a new, strong password for your account.',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF667085),
                  fontFamily: 'Plus Jakarta Sans',
                  height: 1.5,
                ),
              ),
              SizedBox(height: 32.h),
              _buildPasswordField(
                'NEW PASSWORD',
                'Enter new password',
                _passwordController,
                _obscurePassword,
                () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              SizedBox(height: 24.h),
              _buildPasswordField(
                'CONFIRM NEW PASSWORD',
                'Repeat new password',
                _confirmPasswordController,
                _obscureConfirmPassword,
                () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
              SizedBox(height: 24.h),
              _buildRequirementsBox(),
              SizedBox(height: 40.h),
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: () {
                    if (!_has8Chars || !_hasSpecialChar || !_hasNumber) {
                      Fluttertoast.showToast(
                        msg: "Please meet all password requirements",
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                      );
                      return;
                    }
                    if (_passwordController.text != _confirmPasswordController.text) {
                      Fluttertoast.showToast(
                        msg: "Passwords do not match",
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                      );
                      return;
                    }
                    
                    // Handle password update
                    Fluttertoast.showToast(
                      msg: "Password updated successfully",
                      backgroundColor: const Color(0xFF007676),
                      textColor: Colors.white,
                    );
                    context.go(AppRoutes.login);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007676),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28.r),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Update Password',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.cached, color: Colors.white, size: 24.sp),
                          Icon(Icons.lock, color: Colors.white, size: 10.sp),
                        ],
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

  Widget _buildPasswordField(
    String label,
    String hint,
    TextEditingController controller,
    bool obscure,
    VoidCallback onToggle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF475467),
            fontFamily: 'Plus Jakarta Sans',
            letterSpacing: 0.5.sp,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          height: 56.h,
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
                  obscureText: obscure,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: const Color(0xFF98A2B3),
                      fontSize: 14.sp,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: TextStyle(
                    color: const Color(0xFF151C27),
                    fontSize: 14.sp,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ),
              GestureDetector(
                onTap: onToggle,
                child: Icon(
                  obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: const Color(0xFF667085),
                  size: 20.sp,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRequirementsBox() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password Requirements:',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF191C1E),
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          SizedBox(height: 16.h),
          _buildRequirementRow('At least 8 characters', _has8Chars),
          SizedBox(height: 12.h),
          _buildRequirementRow('Include one special character', _hasSpecialChar),
          SizedBox(height: 12.h),
          _buildRequirementRow('Include one number', _hasNumber),
        ],
      ),
    );
  }

  Widget _buildRequirementRow(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isMet ? const Color(0xFF007676) : const Color(0xFFD0D5DD),
          size: 20.sp,
        ),
        SizedBox(width: 12.w),
        Text(
          text,
          style: TextStyle(
            fontSize: 13.sp,
            color: isMet ? const Color(0xFF191C1E) : const Color(0xFF475467),
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
