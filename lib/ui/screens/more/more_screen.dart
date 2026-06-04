import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../routes/app_routes.dart';
import 'qr_code_screen.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  bool _isBotRepliesExpanded = false;
  bool _isSettingsExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: "More"
            Container(
              width: double.infinity,
              height: 55.h,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFDCE2F3), width: 1),
                ),
              ),
              alignment: Alignment.centerLeft,
              child: Text(
                'More',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ),
            
            Expanded(
              child: Stack(
                children: [
                  // Subtle WhatsApp-style doodle background pattern
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.03,
                      child: Image.network(
                        'https://w0.peakpx.com/wallpaper/580/551/HD-wallpaper-whatsapp-doodle-patterns-thumbnail.jpg',
                        repeat: ImageRepeat.repeat,
                        fit: BoxFit.none,
                        errorBuilder: (context, error, stackTrace) => const SizedBox(),
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
                      child: Container(
                        width: 358.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildProfileSection(),
                            _buildMenuItem(
                              icon: Iconsax.scan_barcode,
                              title: 'QR Code',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const QrCodeScreen()),
                                );
                              },
                            ),
                            _buildMenuItem(
                              assetPath: 'assets/images/templates.png',
                              title: 'Templates',
                              onTap: () => context.push('/templates'),
                            ),
                            _buildExpandableMenuItem(
                              assetPath: 'assets/images/bot replies.png',
                              title: 'Bot Replies',
                              isExpanded: _isBotRepliesExpanded,
                              onTap: () {
                                setState(() {
                                  _isBotRepliesExpanded = !_isBotRepliesExpanded;
                                });
                              },
                              children: [
                                _buildSubMenuItem(
                                  assetPath: 'assets/images/list.png',
                                  title: 'List',
                                  onTap: () => context.push('/bot-list'),
                                ),
                                _buildSubMenuItem(
                                  icon: Icons.account_tree_outlined,
                                  title: 'Flows',
                                  onTap: () => context.push('/bot-flows'),
                                ),
                              ],
                            ),
                            _buildMenuItem(
                              assetPath: 'assets/images/team member.png',
                              title: 'Team Members',
                              onTap: () => context.push('/team-members'),
                            ),
                            _buildMenuItem(
                              assetPath: 'assets/images/subscription.png',
                              title: 'My Subscription',
                              onTap: () => context.push('/subscription'),
                            ),
                            _buildMenuItem(
                              assetPath: 'assets/images/message log.png',
                              title: 'Message Log',
                              onTap: () => context.push('/message-log'),
                            ),
                            _buildExpandableMenuItem(
                              assetPath: 'assets/images/settings.png',
                              title: 'Settings',
                              isExpanded: _isSettingsExpanded,
                              onTap: () {
                                setState(() {
                                  _isSettingsExpanded = !_isSettingsExpanded;
                                });
                              },
                              children: [
                                _buildSubMenuItem(
                                  icon: Icons.settings_outlined,
                                  title: 'General',
                                  onTap: () => context.push(AppRoutes.generalSettings),
                                ),
                                _buildSubMenuItem(
                                  icon: Icons.phonelink_setup,
                                  title: 'WhatsApp Setup',
                                  onTap: () {},
                                ),
                                _buildSubMenuItem(
                                  icon: Icons.smart_toy_outlined,
                                  title: 'AI Bot & Bot Settings',
                                  onTap: () => context.push(AppRoutes.botSettings),
                                ),
                              ],
                            ),
                            _buildLogoutItem(
                              icon: Icons.logout_rounded,
                              title: 'Logout',
                              onTap: () => _showLogoutDialog(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      height: 77.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFDCE2F3), width: 1),
        ),
      ),
      child: Row(
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
              'AP',
              style: TextStyle(
                color: const Color(0xFF151C27),
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Admin Panel',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF151C27),
                    height: 1.3,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
                Text(
                  'WhatsApp Marketing',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF3C494B),
                    height: 1.4,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: const Color(0xFFCDF150),
              borderRadius: BorderRadius.circular(9999.r),
            ),
            child: Text(
              'Active',
              style: TextStyle(
                color: const Color(0xFF151C27),
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    IconData? icon,
    String? assetPath,
    required String title,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: const BoxDecoration(
                color: Color(0xFFE1F4F4), // Lighter, softer teal background
                shape: BoxShape.circle,
              ),
              child: Center(
                child: assetPath != null
                    ? Image.asset(
                        assetPath,
                        width: 26.w,
                        height: 26.w,
                        color: const Color(0xFF006C70),
                        fit: BoxFit.contain,
                      )
                    : Icon(
                        icon,
                        color: const Color(0xFF006C70),
                        size: 24.sp,
                      ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF151C27),
                  height: 24 / 16,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: const Color(0xFF98A2B3),
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableMenuItem({
    required String assetPath,
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    required List<Widget> children,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE1F4F4),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Image.asset(
                      assetPath,
                      width: 26.w,
                      height: 26.w,
                      color: const Color(0xFF006C70),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF151C27),
                      height: 24 / 16,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                ),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_down : Icons.chevron_right,
                  color: isExpanded ? const Color(0xFF006C70) : const Color(0xFF98A2B3),
                  size: 24.sp,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...children,
      ],
    );
  }

  Widget _buildSubMenuItem({
    IconData? icon,
    String? assetPath,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.only(left: 76.w, right: 16.w, top: 8.h, bottom: 8.h),
        child: Row(
          children: [
            if (assetPath != null)
              Image.asset(
                assetPath,
                width: 20.w,
                height: 20.w,
                color: const Color(0xFF006B70),
                fit: BoxFit.contain,
              )
            else if (icon != null)
              Icon(
                icon,
                color: const Color(0xFF006B70),
                size: 20.sp,
              ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF151C27),
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: const BoxDecoration(
                color: Color(0xFFFCE4EC),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: const Color(0xFFC2185B),
                size: 22.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFC2185B),
                  height: 24 / 16,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: const Color(0xFF98A2B3),
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(
          'Logout',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: const Color(0xFF667085),
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
              context.go(AppRoutes.login);
            },
            child: Text(
              'Logout',
              style: TextStyle(
                color: const Color(0xFFC2185B),
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
