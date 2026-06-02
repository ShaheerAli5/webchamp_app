import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:go_router/go_router.dart';

class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key});

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
          padding: EdgeInsets.only(right: 16.w, left: 16.w),
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
                    child: const Icon(Icons.arrow_back, color: Colors.black),
                  ),
                ),
                SizedBox(width: 12.w), // Exact 12px gap from design
                Text(
                  'Templates',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ],
            ),
            centerTitle: false,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 20.h),
              child: Column(
                children: [
                  _buildSearchBar(),
                  SizedBox(height: 16.h),
                  _buildTemplateCard(
                    title: 'Welcome-message',
                    status: 'Approved',
                    statusColor: const Color(0xFFE7F6EC),
                    statusTextColor: const Color(0xFF027A48),
                    language: 'English (US)',
                    category: 'Marketing',
                    updatedOn: '2023-11-20 14:30',
                  ),
                  SizedBox(height: 16.h),
                  _buildTemplateCard(
                    title: 'Welcome-message-2',
                    status: 'Pending',
                    statusColor: const Color(0xFFFFF9E5),
                    statusTextColor: const Color(0xFFB54708),
                    language: 'English (US)',
                    category: 'Marketing',
                    updatedOn: '2023-11-20 14:30',
                  ),
                  SizedBox(height: 24.h),
                  Row(
                    children: [
                      Expanded(child: _buildActionBtn('Manage on Meta')),
                      SizedBox(width: 16.w),
                      Expanded(child: _buildActionBtn('Sync Templates')),
                    ],
                  ),
                  SizedBox(height: 80.h), 
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: GestureDetector(
        onTap: () => context.push('/add-template'),
        child: _buildFAB(),
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
                hintText: 'Search templates',
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

  Widget _buildTemplateCard({
    required String title,
    required String status,
    required Color statusColor,
    required Color statusTextColor,
    required String language,
    required String category,
    required String updatedOn,
  }) {
    return Container(
      width: 358.w,
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
                ),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _buildInfoItem('LANGUAGE', language)),
                  Expanded(child: _buildInfoItem('CATEGORY', category)),
                ],
              ),
              SizedBox(height: 16.h),
              _buildInfoItem('UPDATED ON', updatedOn),
            ],
          ),
          SizedBox(height: 14.h),
          const Divider(color: Color(0xFFE8E8EC), height: 1),
          SizedBox(height: 14.h),
          Row(
            children: [
              _buildCardButton(Icons.visibility_outlined, 'View'),
              SizedBox(width: 8.w),
              _buildCardButton(Icons.edit_outlined, 'Edit'),
              const Spacer(),
              Row(
                children: [
                  Icon(Icons.delete_outline, color: const Color(0xFFD92D20), size: 18.sp),
                  SizedBox(width: 4.w),
                  Text(
                    'Delete',
                    style: TextStyle(
                      color: const Color(0xFFD92D20),
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
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
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF9A9AA5),
            letterSpacing: 0.33,
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF344054),
          ),
        ),
      ],
    );
  }

  Widget _buildCardButton(IconData icon, String label) {
    return Container(
      height: 32.h,
      padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 7.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9.r),
        border: Border.all(color: const Color(0xFFE8E8EC)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.sp, color: const Color(0xFF344054)),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF344054),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(String label) {
    return Container(
      height: 48.h,
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(18.r),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF344054),
        ),
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.description, color: Colors.white, size: 22.sp),
            Icon(Icons.add, color: Colors.white, size: 14.sp),
          ],
        ),
      ),
    );
  }
}
