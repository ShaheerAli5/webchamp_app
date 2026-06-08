import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  children: [
                    _buildFinishSetupBanner(),
                    SizedBox(height: 16.h),
                    _buildMetricGrid(),
                    SizedBox(height: 16.h),
                    _buildQuickStartSection(),
                    SizedBox(height: 30.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 110.h,
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          final user = auth.user;
          final displayName = user?.displayName ?? 'Admin Panel';
          final initials = displayName.trim().split(' ').where((e) => e.isNotEmpty).take(2).map((e) => e[0].toUpperCase()).join();
          final firstName = user?.firstName ?? (displayName.split(' ').first);

          return Row(
            children: [
              // Profile Section - Using Expanded to prevent overflow
              Expanded(
                child: SizedBox(
                  height: 34.h,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 17.h,
                        backgroundColor: Colors.black,
                        child: Text(
                          initials.isEmpty ? 'AP' : initials,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Champ Retail Co.',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11.sp,
                                height: 1.1,
                                fontFamily: 'Geist',
                              ),
                            ),
                            Text(
                              'Hi $firstName',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                                fontFamily: 'Geist',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Action Buttons
              SizedBox(
                width: 128.w,
                height: 36.h,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildHeaderButton(Iconsax.scan_barcode),
                    _buildHeaderButton(Iconsax.setting_2),
                    _buildHeaderButton(Iconsax.notification, hasNotification: true),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderButton(IconData icon, {bool hasNotification = false}) {
    return Container(
      width: 36.w,
      height: 36.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFF2F4F7), width: 1),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, size: 16.sp, color: AppColors.textPrimary),
          if (hasNotification)
            Positioned(
              top: 6.h,
              right: 6.w,
              child: Container(
                width: 7.w,
                height: 7.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFD92D20),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFinishSetupBanner() {
    return Container(
      height: 95.h,
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.bannerBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.bannerBorder.withOpacity(0.25), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28.w,
            height: 28.w,
            decoration: BoxDecoration(
              color: AppColors.bannerBorder.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Iconsax.info_circle, color: AppColors.bannerText, size: 16),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Finish setup',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.sp,
                        color: AppColors.bannerText,
                        fontFamily: 'Geist',
                      ),
                    ),
                    Icon(Icons.close, size: 14, color: AppColors.bannerText),
                  ],
                ),
                Text(
                  'Connect WhatsApp Cloud API',
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    color: AppColors.bannerText,
                    fontFamily: 'Geist',
                  ),
                ),
                const Spacer(),
                Container(
                  width: 121.w,
                  height: 26.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.buttonBorder),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Complete setup',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(Icons.arrow_outward, size: 12, color: AppColors.textPrimary),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 8.w,
      mainAxisSpacing: 8.h,
      childAspectRatio: 175 / 130,
      children: [
        _buildMetricCard('TOTAL\nCONTACTS', '0', Iconsax.user, AppColors.navActive),
        _buildMetricCard('TOTAL\nGROUPS', '0', Iconsax.people, const Color(0xFF6D8C00)),
        _buildMetricCard('TOTAL\nCAMPAIGNS', '0', Iconsax.volume_high, const Color(0xFF8B002D)),
        _buildMetricCard('TOTAL\nTEMPLATES', '0', Iconsax.layer, const Color(0xFF6D8C00)),
        _buildMetricCard('TOTAL\nBOT REPLIES', '0', Iconsax.box_1, const Color(0xFF6B8E23)),
        _buildMetricCard('ACTIVE\nTEAM MEMBERS', '0', Iconsax.user_edit, Colors.red.shade900),
        _buildMetricCard('MESSAGES\nIN QUEUE', '0', Iconsax.add_square, const Color(0xFF6B8E23)),
        _buildMetricCard('MESSAGES\nPROCESSED', '0', Iconsax.tick_square, const Color(0xFF6B8E23)),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color iconColor) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
              ),
              Icon(icon, color: iconColor, size: 20),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'MANAGE',
              style: TextStyle(
                fontSize: 8.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStartSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Start Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Start',
                  style: TextStyle(
                    fontSize: 12.67.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Geist',
                  ),
                ),
                Text(
                  '3 live now',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.textSecondary,
                    fontFamily: 'Geist',
                  ),
                ),
              ],
            ),
          ),
          // Steps
          _buildStepItem(1, 'Login to your Facebook Account', height: 48.h),
          _buildStepItem(2, 'Complete Setup as Shown in WhatsApp Cloud API Setup', linkText: 'WhatsApp Cloud API Setup', height: 64.h),
          _buildStepItem(3, 'Manage and Sync WhatsApp templates at Manage WhatsApp Templates', linkText: 'Manage WhatsApp Templates', height: 64.h),
          _buildStepItem(4, 'Create your contact groups using Manage Groups', linkText: 'Manage Groups', height: 48.h),
          _buildStepItem(5, 'Create your Contacts or Upload excel file with predefined exportable template at Manage Contacts', linkText: 'Manage Contacts', height: 64.h),
          _buildStepItem(6, 'Create & Schedule your Campaigns at Manage Campaigns', linkText: 'Manage Campaigns', height: 64.h),
        ],
      ),
    );
  }

  Widget _buildStepItem(int number, String text, {String? linkText, required double height}) {
    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 24.w,
            height: 24.w,
            decoration: BoxDecoration(
              color: const Color(0xFFDBF7E3),
              borderRadius: BorderRadius.circular(8.r),
            ),
            alignment: Alignment.center,
            child: Text(
              number.toString(),
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textBody,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textBody,
                  height: 1.4,
                  fontFamily: 'Plus Jakarta Sans',
                ),
                children: _getStepTextSpans(text, linkText),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<TextSpan> _getStepTextSpans(String text, String? linkText) {
    if (linkText == null) {
      return [TextSpan(text: text)];
    }
    final parts = text.split(linkText);
    return [
      TextSpan(text: parts[0]),
      TextSpan(
        text: linkText,
        style: const TextStyle(color: Color(0xFFC4D52C), fontWeight: FontWeight.w700),
      ),
      if (parts.length > 1) TextSpan(text: parts[1]),
    ];
  }
}
