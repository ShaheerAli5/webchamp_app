import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../providers/auth_provider.dart';
import '../../../routes/app_routes.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final List<TextEditingController> _controllers =
  List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes =
  List.generate(6, (index) => FocusNode());

  String get _otpCode =>
      _controllers.map((c) => c.text).join();

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _verifyCode() async {
    final code = _otpCode;

    if (code.length < 6) {
      Fluttertoast.showToast(
        msg: 'Please enter the complete 6-digit code',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.verifyTwoFactor(code: code);

    if (success) {
      Fluttertoast.showToast(
        msg: 'Code verified successfully',
        backgroundColor: const Color(0xFF007676),
        textColor: Colors.white,
      );
      if (mounted) context.push(AppRoutes.resetPassword);
    } else {
      Fluttertoast.showToast(
        msg: auth.errorMessage ?? 'Invalid or expired code',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

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
                  child: Icon(Icons.arrow_back,
                      color: const Color(0xFF004D4F), size: 24.sp),
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
          padding:
          EdgeInsets.only(top: 48.h, left: 20.w, right: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verify Email',
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
                "We've sent a 6-digit code to your email. Please enter it below to proceed.",
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF667085),
                  fontFamily: 'Plus Jakarta Sans',
                  height: 1.5,
                ),
              ),
              SizedBox(height: 32.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:
                List.generate(6, (index) => _buildOtpBox(index)),
              ),
              SizedBox(height: 32.h),
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _verifyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007676),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    elevation: 0,
                  ),
                  child: auth.isLoading
                      ? const CircularProgressIndicator(
                      color: Colors.white)
                      : Text(
                    'Verify',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Center(
                child: GestureDetector(
                  onTap: auth.isLoading ? null : () {
                    Fluttertoast.showToast(
                      msg: 'Code resent to your email',
                      backgroundColor: const Color(0xFF007676),
                      textColor: Colors.white,
                    );
                  },
                  child: Text(
                    'RESEND CODE',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF007676),
                      fontFamily: 'Plus Jakarta Sans',
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return Container(
      width: 50.w,
      height: 56.h,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF191C1E),
          fontFamily: 'Plus Jakarta Sans',
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          counterText: "",
          border: InputBorder.none,
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            if (index < 5) {
              _focusNodes[index + 1].requestFocus();
            } else {
              _focusNodes[index].unfocus();
            }
          } else if (value.isEmpty) {
            if (index > 0) {
              _focusNodes[index - 1].requestFocus();
            }
          }
        },
      ),
    );
  }
}