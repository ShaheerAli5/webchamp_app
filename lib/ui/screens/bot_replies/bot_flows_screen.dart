import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../routes/app_routes.dart';

class BotFlowsScreen extends StatelessWidget {
  const BotFlowsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(57.h),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFEAECF0), width: 1),
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
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
                  child: Container(
                    height: 40.h,
                    alignment: Alignment.center,
                    child: Icon(Icons.arrow_back, color: Colors.black, size: 24.sp),
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Bot Flows',
                  style: TextStyle(
                    color: const Color(0xFF151515),
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter',
                  ),
                ),
                const Spacer(),
                Icon(Icons.help_outline, color: const Color(0xFF006C70), size: 22.sp),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: GestureDetector(
        onTap: () => context.push(AppRoutes.addBotFlow),
        child: _buildFAB(),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                top: 20.h,
                left: 16.w,
                right: 16.w,
                bottom: 20.h,
              ),
              child: Column(
                children: [
                  _buildAnalyticsCard(),
                  SizedBox(height: 16.h), // Gap 16px from Figma
                  _buildSearchBar(),
                  SizedBox(height: 16.h), // Gap 16px from Figma
                  _buildFlowCard(
                    context,
                    title: 'Onboarding Flow',
                    status: 'Active',
                    statusColor: const Color(0xFFE7F6EC),
                    statusTextColor: const Color(0xFF027A48),
                    trigger: 'New Subscriber',
                  ),
                  SizedBox(height: 16.h),
                  _buildFlowCard(
                    context,
                    title: 'Onboarding Flow',
                    status: 'Inactive',
                    statusColor: const Color(0xFFE0E6F3),
                    statusTextColor: const Color(0xFF5369A1),
                    trigger: 'New Subscriber',
                  ),
                  SizedBox(height: 16.h),
                  _buildFlowCard(
                    context,
                    title: 'Onboarding Flow',
                    status: 'Active',
                    statusColor: const Color(0xFFE7F6EC),
                    statusTextColor: const Color(0xFF027A48),
                    trigger: 'New Subscriber',
                  ),
                  SizedBox(height: 80.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFlowActionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.1),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9FF),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            ),
            padding: EdgeInsets.only(
              left: 16.w,
              right: 16.w,
              top: 12.h,
              bottom: MediaQuery.of(context).padding.bottom + 24.h,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48.w,
                    height: 5.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD0D5DD),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  'Bot Flow Actions',
                  style: TextStyle(
                    fontSize: 18.sp,
                    height: 24 / 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF151C27),
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
                SizedBox(height: 24.h),
                _buildActionOption(
                  icon: Iconsax.edit_2_copy,
                  title: 'Edit',
                  onTap: () => context.pop(),
                ),
                _buildDivider(),
                _buildActionOption(
                  icon: Iconsax.trash_copy,
                  title: 'Delete',
                  iconColor: const Color(0xFFD92D20),
                  onTap: () => context.pop(),
                ),
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: TextButton(
                    onPressed: () => context.pop(),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFEFEFEF),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9999.r),
                      ),
                    ),
                    child: Text(
                      'CANCEL',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF344054),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        height: 56.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? const Color(0xFF006C70), size: 20.sp),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  height: 24 / 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF151C27),
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: const Color(0xFFBBC9CB),
              size: 18.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: const Color(0xFFF0F3FF),
    );
  }

  Widget _buildAnalyticsCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'TOTAL ACTIVE FLOWS',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black.withOpacity(0.8),
                  letterSpacing: 0.55,
                  height: 16 / 11,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
              Text(
                '12 Active',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF484848),
                  height: 32 / 24,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 7.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Row(
              children: [
                Text(
                  'View Analytics',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF344054),
                    fontFamily: 'Inter',
                  ),
                ),
                SizedBox(width: 4.w),
                Icon(Icons.north_east, size: 12.sp, color: const Color(0xFF344054)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      width: 358.w,
      height: 55.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Icon(Icons.search, color: const Color(0xFF9A9AA5), size: 24.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: TextField(
              style: TextStyle(fontSize: 16.sp, color: Colors.black),
              decoration: InputDecoration(
                hintText: 'Search flows',
                hintStyle: TextStyle(
                  color: const Color(0xFF9A9AA5),
                  fontSize: 16.sp,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                filled: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowCard(
    BuildContext context, {
    required String title,
    required String status,
    required Color statusColor,
    required Color statusTextColor,
    required String trigger,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF101828),
                  fontFamily: 'Hanken Grotesk',
                  height: 22 / 16,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(999.r),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: statusTextColor,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  GestureDetector(
                    onTap: () => _showFlowActionsSheet(context),
                    behavior: HitTestBehavior.opaque,
                    child: Icon(Icons.more_vert, color: const Color(0xFF98A2B3), size: 20.sp),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 18.h),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TRIGGER',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF9A9AA5),
                  letterSpacing: 0.33,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                trigger,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF344054),
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      width: 60.w,
      height: 60.w,
      decoration: BoxDecoration(
        color: const Color(0xFF21C063),
        borderRadius: BorderRadius.circular(17.86.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_tree_outlined, color: Colors.white, size: 24.sp),
            Icon(Icons.add, color: Colors.white, size: 14.sp),
          ],
        ),
      ),
    );
  }
}
