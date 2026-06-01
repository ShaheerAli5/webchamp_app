import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class CreateCampaignScreen extends StatelessWidget {
  const CreateCampaignScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                SizedBox(height: 16.h),
                _buildWarningBanner(),
                SizedBox(height: 16.h),
                _buildSyncButton(),
                SizedBox(height: 16.h),
                _buildStepOneCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: 40.h,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Icon(
              Icons.arrow_back,
              size: 24.sp,
              color: const Color(0xFF151515),
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            'Create New Campaign',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF151515),
              fontFamily: 'Inter',
              letterSpacing: 0.06.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      width: 358.w,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEECD),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFD8953D).withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28.w,
                height: 28.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8953D).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.info_outline, color: const Color(0xFF633600), size: 14.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set Test Contact',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                        color: const Color(0xFF633600),
                        fontFamily: 'Geist',
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Test Contact missing, You need to set the Test Contact first, do it under the WhatsApp Settings',
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        color: const Color(0xFF633600),
                        fontFamily: 'Geist',
                        height: 1.3,
                        letterSpacing: -0.08.sp,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Icon(Icons.close, size: 16.sp, color: const Color(0xFF633600)),
            ],
          ),
          SizedBox(height: 13.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 7.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(color: const Color(0xFFDFDEDA)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Go to WhatsApp settings',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(Icons.arrow_outward, size: 12.sp, color: Colors.black),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncButton() {
    return Container(
      width: 358.w,
      height: 48.h,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sync, size: 24.sp, color: const Color(0xFF151515)),
          SizedBox(width: 12.w),
          Text(
            'Sync WhatsApp Templates',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF151515),
              fontFamily: 'Inter',
              letterSpacing: -0.08.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepOneCard() {
    return Container(
      width: 358.w,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFFE8E8EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 1',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF151515),
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            'SELECT TEMPLATE',
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF98A2B3),
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            width: double.infinity,
            height: 48.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xFFE8E8EC)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select & Configure Template',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: const Color(0xFF667085),
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, color: const Color(0xFF667085), size: 20.sp),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
