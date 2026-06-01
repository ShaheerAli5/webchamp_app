import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:go_router/go_router.dart';

class CampaignsScreen extends StatelessWidget {
  const CampaignsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: Container(
        width: 60.w,
        height: 60.w,
        decoration: BoxDecoration(
          color: const Color(0xFF21C063),
          borderRadius: BorderRadius.circular(17.86.r),
        ),
        child: FloatingActionButton(
          onPressed: () => context.push('/create-campaign'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.volume_high, color: Colors.white, size: 14.sp),
              Text('+', style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabs(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                children: [
                  SizedBox(height: 16.h),
                  _buildSearchBar(),
                  SizedBox(height: 16.h),
                  _buildCampaignCard(
                    title: 'Festive Greetings 2024',
                    status: 'Active',
                    statusColor: const Color(0xFFE7F6EC),
                    statusTextColor: const Color(0xFF21C063),
                    template: 'festive_wishes_v2',
                    contacts: '4,820',
                    createdAt: '2023-11-20 14:30',
                    scheduledAt: '2023-12-01 09:00',
                  ),
                  SizedBox(height: 18.h),
                  _buildCampaignCard(
                    title: 'Product Launch Beta',
                    status: 'Draft',
                    statusColor: const Color(0xFFF2F4F7),
                    statusTextColor: const Color(0xFF667085),
                    template: 'launch_announcement',
                    contacts: '850',
                    createdAt: '2023-11-22 10:15',
                    scheduledAt: 'Not set',
                    isScheduledNotSet: true,
                  ),
                  SizedBox(height: 80.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
      alignment: Alignment.centerLeft,
      child: Text(
        'Campaigns',
        style: TextStyle(
          fontSize: 24.sp,
          fontWeight: FontWeight.bold,
          color: Colors.black,
          fontFamily: 'Geist',
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      height: 55.h,
      width: 390.w,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE8E8EC), width: 1)),
      ),
      padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildTabItem('Active', isActive: true),
          SizedBox(width: 24.w),
          _buildTabItem('Archive', isActive: false),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, {required bool isActive}) {
    return Container(
      height: 32.h,
      padding: EdgeInsets.only(bottom: 12.h),
      decoration: isActive
          ? const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
            )
          : null,
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.black : const Color(0xFF98A2B3),
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
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
        border: Border.all(color: const Color(0xFFE8E8EC), width: 1),
      ),
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          Icon(Icons.search, color: const Color(0xFF9A9AA5), size: 22.sp),
          SizedBox(width: 14.w),
          Expanded(
            child: TextField(
              style: TextStyle(fontSize: 16.sp, color: Colors.black),
              decoration: InputDecoration(
                hintText: 'Search campaigns',
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignCard({
    required String title,
    required String status,
    required Color statusColor,
    required Color statusTextColor,
    required String template,
    required String contacts,
    required String createdAt,
    required String scheduledAt,
    bool isScheduledNotSet = false,
  }) {
    return Container(
      width: 358.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFE8E8EC), width: 1),
      ),
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 38.w,
                    height: 38.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECECFE),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Iconsax.volume_high,
                      color: const Color(0xFF4F46E5),
                      size: 16.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  SizedBox(
                    width: 201.w,
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
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
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          _buildDetailGrid(template, contacts, createdAt, scheduledAt, isScheduledNotSet),
          SizedBox(height: 18.h),
          Container(
            padding: EdgeInsets.only(top: 14.h),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE8E8EC), width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildActionButton('Edit', Iconsax.edit_2, Colors.black, const Color(0xFFE8E8EC)),
                SizedBox(width: 8.w),
                _buildActionButton('Delete', Iconsax.trash, const Color(0xFFD92D20), Colors.transparent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailGrid(String template, String contacts, String createdAt, String scheduledAt, bool isScheduledNotSet) {
    return SizedBox(
      height: 90.h,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildDetailItem('TEMPLATE', template)),
              SizedBox(width: 8.w),
              Expanded(child: _buildDetailItem('CONTACTS', contacts)),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(child: _buildDetailItem('CREATED AT', createdAt)),
              SizedBox(width: 8.w),
              Expanded(child: _buildDetailItem('SCHEDULED AT', scheduledAt, isItalic: isScheduledNotSet)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color textColor, Color borderColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 7.h),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(9.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: textColor),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {bool isItalic = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF98A2B3),
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
            fontFamily: 'Hanken Grotesk',
            fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
