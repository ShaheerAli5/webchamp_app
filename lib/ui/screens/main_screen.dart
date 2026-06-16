import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../features/contacts/presentation/providers/contact_provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({
    required this.navigationShell,
    Key? key,
  }) : super(key: key ?? const ValueKey<String>('MainScreen'));

  final StatefulNavigationShell navigationShell;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContactProvider>().startGlobalUnreadPolling();
      context.read<ContactProvider>().getGlobalUnreadCount();
    });
  }

  @override
  void dispose() {
    // Note: Provider is global, but we can stop polling if we want.
    // However, it's probably better to keep it running for the badge.
    // context.read<ContactProvider>().stopGlobalUnreadPolling();
    super.dispose();
  }

  void _onTap(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the bottom padding to handle safe area (notches/home bars)
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: Container(
        // The total height will be our desired height + the device's safe area padding
        height: 70.h + bottomPadding,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: const Color(0xFFEAECF0),
              width: 1,
            ),
          ),
        ),
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Consumer<ContactProvider>(
          builder: (context, provider, child) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_outlined, 'Home'),
                _buildNavItem(1, Icons.campaign_outlined, 'Campaigns'),
                _buildNavItem(2, Icons.chat_bubble_outline, 'Chat', badgeCount: provider.globalUnreadCount),
                _buildNavItem(3, Icons.people_outline, 'Contacts'),
                _buildNavItem(4, Icons.more_horiz, 'More'),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, {int badgeCount = 0}) {
    final isSelected = widget.navigationShell.currentIndex == index;
    final Color activeColor = const Color(0xFF006C70);
    final Color inactiveColor = const Color(0xFF667085);

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isSelected ? activeColor : inactiveColor,
                  size: 24.sp,
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -5.h,
                    right: -8.w,
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD92D20),
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(
                        minWidth: 16.w,
                        minHeight: 16.w,
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : badgeCount.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : inactiveColor,
                fontSize: 12.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontFamily: 'Geist',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
