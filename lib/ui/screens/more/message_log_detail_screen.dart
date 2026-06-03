import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class MessageLogDetailScreen extends StatelessWidget {
  final Map<String, dynamic> logData;

  const MessageLogDetailScreen({super.key, required this.logData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
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
                  'Message Log',
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
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              _buildDetailCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RECIPIENT',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF98A2B3),
                      letterSpacing: 0.5,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    logData['recipient'] ?? '+1(555) 012-3456',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF191C1E),
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.done_all, size: 14.sp, color: const Color(0xFF667085)),
                    SizedBox(width: 4.w),
                    Text(
                      logData['status'] ?? 'Delivered',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF344054),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          const Divider(color: Color(0xFFEAECF0)),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem('FROM', logData['from'] ?? 'Marketing'),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VIA',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF98A2B3),
                        letterSpacing: 0.5,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(Icons.message, size: 14.sp, color: const Color(0xFF191C1E)),
                        SizedBox(width: 6.w),
                        Text(
                          logData['via'] ?? 'WhatsApp Cloud',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF191C1E),
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem('MESSAGED AT', logData['messagedAt'] ?? '2023-11-20 14:30'),
              ),
              Expanded(
                child: _buildInfoItem('TYPE', logData['type'] ?? 'Bulk'),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          const Divider(color: Color(0xFFEAECF0)),
          SizedBox(height: 24.h),
          Text(
            'MESSAGE CONTENT',
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF98A2B3),
              letterSpacing: 0.5,
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            logData['content'] ?? 'Hi Rehman, thank you for your inquiry. Our team will get back to you shortly.',
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF191C1E),
              height: 1.5,
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          SizedBox(height: 60.h),
          const Divider(color: Color(0xFFEAECF0)),
          SizedBox(height: 24.h),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    height: 48.h,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F7),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF344054),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Container(
                  height: 48.h,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF006B70),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.refresh, color: Colors.white, size: 18.sp),
                      SizedBox(width: 8.w),
                      Text(
                        'Resend',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF98A2B3),
            letterSpacing: 0.5,
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF191C1E),
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
      ],
    );
  }
}
