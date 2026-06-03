import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../routes/app_routes.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool _isSetupCompleted = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: _isSetupCompleted ? _buildFAB() : null,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (!_isSetupCompleted) ...[
              SizedBox(height: 10.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: _buildFinishSetupBanner(),
              ),
            ] else ...[
              _buildSearchBar(),
              _buildFilterChips(),
              Expanded(
                child: ListView(
                  children: [
                    _buildChatItem(
                      name: 'Aazam Bashir',
                      subtext: 'Voice call',
                      time: '4:39 pm',
                      icon: Icons.call_made,
                      iconColor: Colors.grey,
                    ),
                    _buildChatItem(
                      name: 'WabChamp',
                      subtext: 'Rehman ullah :  Voice messa....',
                      time: '4:54 pm',
                      isUnread: true,
                      unreadCount: '1',
                      icon: Icons.mic,
                      iconColor: Colors.green,
                      isGroup: true,
                    ),
                    _buildChatItem(
                      name: 'Atta',
                      subtext: 'I will let you know',
                      time: '4:39 pm',
                      icon: Icons.done_all,
                      iconColor: Colors.blue,
                    ),
                    _buildChatItem(
                      name: 'Ibrahim',
                      subtext: 'Okay',
                      time: '4:39 pm',
                      icon: Icons.done,
                      iconColor: Colors.grey,
                    ),
                    _buildChatItem(
                      name: 'Rehmanullah',
                      subtext: 'typing...',
                      time: '4:39 pm',
                      subtextColor: Colors.green,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 60.h,
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'WhatsApp',
            style: TextStyle(
              color: const Color(0xFF151515),
              fontSize: 24.sp,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
              letterSpacing: 0.06,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.camera_alt_outlined, size: 24.sp, color: Colors.black),
              SizedBox(width: 22.w),
              Icon(Icons.more_vert, size: 24.sp, color: Colors.black),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48.h,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(24.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.grey, size: 22.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Ask Meta AI or Search',
                hintStyle: TextStyle(
                  color: Colors.grey,
                  fontSize: 16.sp,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 36.h,
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        children: [
          _buildChip('All', isSelected: true),
          _buildChip('Unread 11'),
          _buildChip('Groups 7'),
          _buildChip('New List', isAction: true, hasAddIcon: true, onTap: () => context.push(AppRoutes.createNewList)),
        ],
      ),
    );
  }

  Widget _buildChip(String label, {bool isSelected = false, bool isAction = false, bool hasAddIcon = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(right: 8.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD8FDD2) : Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: isSelected ? const Color(0xFF25D366) : const Color(0xFFD1D1D1), width: 1.w),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasAddIcon) ...[
              Icon(Icons.add, size: 16.sp, color: const Color(0xFF667085)),
              SizedBox(width: 4.w),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF075E54) : const Color(0xFF667085),
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatItem({
    required String name,
    required String subtext,
    required String time,
    IconData? icon,
    Color? iconColor,
    Color? subtextColor,
    bool isUnread = false,
    String? unreadCount,
    bool isGroup = false,
  }) {
    return ListTile(
      onTap: () => context.push('/chat-detail/$name'),
      leading: CircleAvatar(
        radius: 26.r,
        backgroundColor: const Color(0xFFF0F2F5),
        child: Icon(isGroup ? Icons.group : Icons.person, color: Colors.black54, size: 28.sp),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 12.sp,
              color: isUnread ? const Color(0xFF25D366) : Colors.grey,
            ),
          ),
        ],
      ),
      subtitle: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16.sp, color: iconColor),
                  SizedBox(width: 4.w),
                ],
                Expanded(
                  child: Text(
                    subtext,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: subtextColor ?? Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (isUnread && unreadCount != null)
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: const BoxDecoration(
                color: Color(0xFF25D366),
                shape: BoxShape.circle,
              ),
              child: Text(
                unreadCount,
                style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
    );
  }

  Widget _buildFAB() {
    return Container(
      width: 60.w,
      height: 60.w,
      decoration: BoxDecoration(
        color: const Color(0xFF21C063),
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(Icons.add_comment_rounded, color: Colors.white, size: 28.sp),
      ),
    );
  }

  Widget _buildFinishSetupBanner() {
    return Container(
      height: 95.h,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEECD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8953D).withOpacity(0.25), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28.w,
            height: 28.w,
            decoration: BoxDecoration(
              color: const Color(0xFFD8953D).withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(Iconsax.info_circle, color: const Color(0xFF633600), size: 14.sp),
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
                        color: const Color(0xFF633600),
                        fontFamily: 'Geist',
                        height: 17/13,
                        letterSpacing: -0.08,
                      ),
                    ),
                    Icon(Icons.close, size: 14.sp, color: const Color(0xFF633600)),
                  ],
                ),
                Text(
                  'Connect WhatsApp Cloud API',
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    color: const Color(0xFF633600),
                    fontFamily: 'Geist',
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => setState(() => _isSetupCompleted = true),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFDFDEDA)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Complete setup',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF161B20),
                            fontFamily: 'Geist',
                            height: 1,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Icon(Icons.arrow_outward, size: 11.sp, color: Colors.black),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
