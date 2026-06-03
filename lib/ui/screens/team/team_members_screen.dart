import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../routes/app_routes.dart';

class TeamMembersScreen extends StatefulWidget {
  const TeamMembersScreen({super.key});

  @override
  State<TeamMembersScreen> createState() => _TeamMembersScreenState();
}

class _TeamMembersScreenState extends State<TeamMembersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Map<String, dynamic>> teamMembers = [
    {
      'name': 'Jane Doe',
      'username': '@janedoe',
      'email': 'jane.doe@example.com',
      'phone': '+1 234 567 890',
      'createdOn': '2023-11-20 14:30',
      'status': 'Active',
      'initials': 'JD',
    },
    {
      'name': 'John Smith',
      'username': '@johnsmith',
      'email': 'john.smith@example.com',
      'phone': '+1 987 654 321',
      'createdOn': '2023-11-21 09:15',
      'status': 'Active',
      'initials': 'JS',
    },
    {
      'name': 'Alice Johnson',
      'username': '@alicej',
      'email': 'alice.j@example.com',
      'phone': '+1 555 123 456',
      'createdOn': '2023-11-22 16:45',
      'status': 'Inactive',
      'initials': 'AJ',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

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
                  child: SizedBox(
                    width: 24.w,
                    height: 24.h,
                    child: Icon(Icons.arrow_back, color: Colors.black, size: 24.sp),
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Team Members',
                  style: TextStyle(
                    color: const Color(0xFF151515),
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter',
                    letterSpacing: 0.06,
                  ),
                ),
                const Spacer(),
                Icon(Icons.help_outline, color: const Color(0xFF007176), size: 22.sp),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildSearchBar(),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 100.h),
                  itemCount: teamMembers.length,
                  itemBuilder: (context, index) {
                    final member = teamMembers[index];
                    return _buildTeamMemberCard(member, index);
                  },
                ),
              ),
            ],
          ),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24.h,
            right: 16.w,
            child: GestureDetector(
              onTap: () => context.push(AppRoutes.addTeamMember),
              child: Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  color: const Color(0xFF21C063),
                  borderRadius: BorderRadius.circular(17.86.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF21C063).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(Icons.person_add_alt_1, color: Colors.white, size: 24.sp),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: GestureDetector(
        onTap: () => _searchFocusNode.requestFocus(),
        child: Container(
          height: 55.h,
          width: 358.w,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(color: const Color(0xFFEAECF0)),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              Icon(Icons.search, color: const Color(0xFF98A2B3), size: 20.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Search members',
                    hintStyle: TextStyle(
                      color: const Color(0xFF98A2B3),
                      fontSize: 14.sp,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  style: TextStyle(
                    color: const Color(0xFF151C27),
                    fontSize: 14.sp,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamMemberCard(Map<String, dynamic> member, int index) {
    return Container(
      width: 358.w,
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFEAECF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: const BoxDecoration(
                  color: Color(0xFFE4E4E4),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  member['initials'],
                  style: TextStyle(
                    color: const Color(0xFF475467),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member['name'],
                      style: TextStyle(
                        color: const Color(0xFF151C27),
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Plus Jakarta Sans',
                        height: 1.5,
                      ),
                    ),
                    Text(
                      member['username'],
                      style: TextStyle(
                        color: const Color(0xFF667085),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: member['status'] == 'Active' ? const Color(0xFFECFDF3) : const Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.circular(99.r),
                ),
                child: Text(
                  member['status'],
                  style: TextStyle(
                    color: member['status'] == 'Active' ? const Color(0xFF039855) : const Color(0xFF475467),
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              GestureDetector(
                onTap: () => _showUserActions(context, member, index),
                child: Icon(Icons.more_vert, color: const Color(0xFF667085), size: 24.sp),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          _buildInfoRow('EMAIL', member['email']),
          SizedBox(height: 16.h),
          _buildInfoRow('PHONE', member['phone']),
          SizedBox(height: 16.h),
          _buildInfoRow('CREATED ON', member['createdOn']),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF98A2B3),
            letterSpacing: 0.33,
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF151C27),
            fontFamily: 'Plus Jakarta Sans',
            height: 1.28,
          ),
        ),
      ],
    );
  }

  void _showUserActions(BuildContext context, Map<String, dynamic> member, int index) {
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
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
            ),
            padding: EdgeInsets.only(
              left: 20.w,
              right: 20.w,
              top: 12.h,
              bottom: MediaQuery.of(context).padding.bottom + 20.h,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAECF0),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  'User Actions',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF151515),
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
                SizedBox(height: 16.h),
                _buildActionItem(
                  icon: Iconsax.edit_2_copy,
                  title: 'Edit User & Permissions',
                  iconColor: const Color(0xFF007176),
                  onTap: () {
                    context.pop();
                    context.push(AppRoutes.addTeamMember, extra: member);
                  },
                ),
                const Divider(color: Color(0xFFF2F4F7), height: 1),
                _buildActionItem(
                  icon: Iconsax.login_1_copy,
                  title: 'Login as',
                  iconColor: const Color(0xFF12B76A),
                  onTap: () {
                    context.pop();
                    _showLoginAsPopup(context, member['name']);
                  },
                ),
                const Divider(color: Color(0xFFF2F4F7), height: 1),
                _buildActionItem(
                  icon: Iconsax.trash_copy,
                  title: 'Delete',
                  iconColor: const Color(0xFFD92D20),
                  onTap: () {
                    context.pop();
                    _showDeleteConfirmation(context, index, member['name']);
                  },
                ),
                SizedBox(height: 24.h),
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: double.infinity,
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F7),
                      borderRadius: BorderRadius.circular(99.r),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'CANCEL',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF475467),
                        letterSpacing: 0.5,
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

  void _showDeleteConfirmation(BuildContext context, int index, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                teamMembers.removeAt(index);
              });
              Navigator.pop(context);
              _showSuccessPopup(context, 'Successfully Deleted');
            },
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSuccessPopup(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 40.w),
          padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 24.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56.w,
                height: 56.w,
                decoration: const BoxDecoration(
                  color: Color(0xFFE7F6EC),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: const Color(0xFF039855),
                  size: 32.sp,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF101828),
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                height: 44.h,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006C70),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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

  void _showLoginAsPopup(BuildContext context, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login as'),
        content: Text('Are you sure you want to login as $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Logged in as $name'),
                  backgroundColor: const Color(0xFF006C70),
                ),
              );
              // In a real app, you would handle session switching and navigation here
              context.go(AppRoutes.home);
            },
            child: const Text('Yes', style: TextStyle(color: Color(0xFF006C70))),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22.sp),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF151C27),
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: const Color(0xFFD0D5DD), size: 20.sp),
          ],
        ),
      ),
    );
  }
}
