import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _2faCodeController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _showRecoveryCodes = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      final nameParts = user.name?.split(' ') ?? [];
      _firstNameController.text = user.firstName ?? (nameParts.isNotEmpty ? nameParts.first : '');
      _lastNameController.text = user.lastName ?? (nameParts.length > 1 ? nameParts.last : '');
      _mobileController.text = user.mobileNumber ?? '';
      _emailController.text = user.email;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _2faCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF151C27)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Profile',
          style: TextStyle(
            color: const Color(0xFF151C27),
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
          ),
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('USER INFORMATION'),
              SizedBox(height: 16.h),
              _buildFieldLabel('FIRST NAME'),
              _buildTextField(_firstNameController),
              SizedBox(height: 16.h),
              _buildFieldLabel('LAST NAME'),
              _buildTextField(_lastNameController),
              SizedBox(height: 16.h),
              _buildFieldLabel('MOBILE NUMBER'),
              Text(
                'Number should be with country code without 0 or +',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: AppColors.textSecondary,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
              SizedBox(height: 4.h),
              _buildTextField(_mobileController, hint: '3441234567'),
              SizedBox(height: 16.h),
              _buildFieldLabel('EMAIL'),
              _buildTextField(_emailController, enabled: false),

              SizedBox(height: 32.h),
              _buildSectionTitle('PASSWORD'),
              SizedBox(height: 16.h),
              _buildFieldLabel('CURRENT PASSWORD'),
              _buildPasswordField(_currentPasswordController, _obscureCurrent, () {
                setState(() => _obscureCurrent = !_obscureCurrent);
              }),
              SizedBox(height: 16.h),
              _buildFieldLabel('NEW PASSWORD'),
              _buildPasswordField(_newPasswordController, _obscureNew, () {
                setState(() => _obscureNew = !_obscureNew);
              }),
              SizedBox(height: 16.h),
              _buildFieldLabel('CONFIRM NEW PASSWORD'),
              _buildPasswordField(_confirmPasswordController, _obscureConfirm, () {
                setState(() => _obscureConfirm = !_obscureConfirm);
              }),

              SizedBox(height: 32.h),
              _buildSectionTitle('TWO-FACTOR AUTHENTICATION'),
              SizedBox(height: 16.h),
              _buildStepItem(1, 'Scan QR Code'),
              SizedBox(height: 16.h),
              Padding(
                padding: EdgeInsets.only(left: 8.w),
                child: Text(
                  'Scan this QR code to set up your account using your preferred authenticator app. Popular choices include Google Authenticator, Microsoft Authenticator and Authy.',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textBody,
                    height: 1.5,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Center(
                child: Container(
                  width: 200.w,
                  height: 200.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFEAECF0)),
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(16.w),
                  child: Consumer<AuthProvider>(
                    builder: (context, auth, child) {
                      final secret = auth.user?.twoFactorSecret ?? 'JBSWY3DPEHPK3PXP';
                      final qrData = 'otpauth://totp/WebChamp:${_emailController.text}?secret=$secret&issuer=WebChamp';

                      return Image.network(
                        'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${Uri.encodeComponent(qrData)}',
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: AppColors.primary,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code_2, size: 60.sp, color: AppColors.textSecondary),
                              SizedBox(height: 8.h),
                              Text(
                                'QR Code',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12.sp,
                                  fontFamily: 'Plus Jakarta Sans',
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              _buildStepItem(2, 'Activate'),
              SizedBox(height: 16.h),
              Padding(
                padding: EdgeInsets.only(left: 8.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Once you scan with 2FA app, you need to activate it',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textBody,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Container(
                            height: 48.h,
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F4F7),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: TextField(
                              controller: _2faCodeController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                              decoration: const InputDecoration(
                                hintText: 'Enter 6-digit code',
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppColors.textPrimary,
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          flex: 2,
                          child: Consumer<AuthProvider>(
                            builder: (context, auth, child) {
                              return SizedBox(
                                height: 48.h,
                                child: ElevatedButton(
                                  onPressed: auth.isLoading ? null : () async {
                                    if (_2faCodeController.text.length < 6) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Please enter 6-digit code')),
                                      );
                                      return;
                                    }
                                    final success = await auth.verifyTwoFactor(code: _2faCodeController.text);
                                    if (context.mounted) {
                                      if (success) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('2FA activated successfully'), backgroundColor: Colors.green),
                                        );
                                        _2faCodeController.clear();
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(auth.errorMessage ?? 'Invalid code'), backgroundColor: Colors.red),
                                        );
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                    elevation: 0,
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: auth.isLoading
                                      ? SizedBox(height: 20.h, width: 20.h, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : Text(
                                          'Activate',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Plus Jakarta Sans',
                                          ),
                                        ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32.h),
              _buildSectionTitle('RECOVERY CODES'),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E5),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFFFFE5BF)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline, color: const Color(0xFFD8953D), size: 20.sp),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tip',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF633600),
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Write down the following recovery codes, in case you lose access to device app etc.',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: const Color(0xFF633600),
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              InkWell(
                onTap: () => setState(() => _showRecoveryCodes = !_showRecoveryCodes),
                child: Container(
                  height: 48.h,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F4F7),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Show codes',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                      Icon(
                        _showRecoveryCodes ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: const Color(0xFF667085),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 32.h),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 48.h,
                      child: OutlinedButton(
                        onPressed: () => context.pop(),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFFF2F4F7),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          'Close',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 48.h,
                      child: Consumer<AuthProvider>(
                        builder: (context, auth, child) {
                          return ElevatedButton(
                            onPressed: auth.isLoading ? null : () async {
                              if (_currentPasswordController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Current password is required to save changes')),
                                );
                                return;
                              }

                              if (_newPasswordController.text.isNotEmpty || _confirmPasswordController.text.isNotEmpty) {
                                if (_newPasswordController.text != _confirmPasswordController.text) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('New passwords do not match')),
                                  );
                                  return;
                                }
                                if (_newPasswordController.text.length < 6) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('New password must be at least 6 characters')),
                                  );
                                  return;
                                }
                              }

                              final success = await auth.updatePassword(
                                oldPassword: _currentPasswordController.text,
                                password: _newPasswordController.text.isEmpty
                                    ? _currentPasswordController.text
                                    : _newPasswordController.text,
                                passwordConfirmation: _confirmPasswordController.text.isEmpty
                                    ? _currentPasswordController.text
                                    : _confirmPasswordController.text,
                              );

                              if (context.mounted) {
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Password updated successfully'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  _currentPasswordController.clear();
                                  _newPasswordController.clear();
                                  _confirmPasswordController.clear();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(auth.errorMessage ?? 'Failed to update password'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                              elevation: 0,
                              padding: EdgeInsets.zero,
                            ),
                            child: auth.isLoading
                                ? SizedBox(
                                    height: 20.h,
                                    width: 20.h,
                                    child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(
                                    'Save',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Plus Jakarta Sans',
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        fontFamily: 'Plus Jakarta Sans',
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF475467),
          fontFamily: 'Plus Jakarta Sans',
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, {String? hint, bool enabled = true}) {
    return Container(
      height: 48.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(12.r),
      ),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        style: TextStyle(
          fontSize: 14.sp,
          color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
          fontFamily: 'Plus Jakarta Sans',
        ),
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, bool obscureText, VoidCallback onToggle) {
    return Container(
      height: 48.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(12.r),
      ),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              decoration: const InputDecoration(
                hintText: '********',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textPrimary,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: Icon(
              obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: const Color(0xFF667085),
              size: 20.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(int step, String title) {
    return Row(
      children: [
        Container(
          width: 24.w,
          height: 24.w,
          decoration: const BoxDecoration(
            color: Color(0xFFE8F5E9),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            step.toString(),
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
      ],
    );
  }
}
