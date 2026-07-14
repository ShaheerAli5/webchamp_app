import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/utils/helpers.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String name;
  final String uid;
  final String? imageUrl;
  final VoidCallback onInfoTap;

  const ChatAppBar({
    super.key,
    required this.name,
    required this.uid,
    this.imageUrl,
    required this.onInfoTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: InkWell(
        onTap: onInfoTap,
        child: Row(
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back, color: Color(0xFF008069)),
            ),
            CircleAvatar(
              radius: 20.r,
              backgroundColor: const Color(0xFFF0F2F5),
              backgroundImage: imageUrl != null ? CachedNetworkImageProvider(imageUrl!) : null,
              child: imageUrl == null
                  ? Icon(Icons.person, color: Colors.grey, size: 28.sp)
                  : null,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: const Color(0xFF111B21),
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'tap for info',
                    style: TextStyle(color: const Color(0xFF667781), fontSize: 11.sp),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          onPressed: onInfoTap,
          icon: const Icon(Icons.more_vert, color: Color(0xFF667781)),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(60.h);
}
