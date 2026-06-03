import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../routes/app_routes.dart';

class BotListScreen extends StatefulWidget {
  const BotListScreen({super.key});

  @override
  State<BotListScreen> createState() => _BotListScreenState();
}

class _BotListScreenState extends State<BotListScreen> {
  // Sample data to manage state
  List<Map<String, dynamic>> bots = [
    {
      'title': 'Welcome Greeter',
      'status': 'Active',
      'type': 'Auto Reply',
      'trigger': '"Hello", "Hi"',
      'createdOn': '2023-11-20 14:30',
      'botType': 'simple', // To determine which edit screen to show
    },
    {
      'title': 'Welcome Greeter',
      'status': 'Inactive',
      'type': 'Auto Reply',
      'trigger': '"Hello", "Hi"',
      'createdOn': '2023-11-20 14:30',
      'botType': 'media',
    },
    {
      'title': 'Welcome Greeter',
      'status': 'Active',
      'type': 'Auto Reply',
      'trigger': '"Hello", "Hi"',
      'createdOn': '2023-11-20 14:30',
      'botType': 'advance',
    },
  ];

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
                    child: Icon(Icons.arrow_back, color: Colors.black, size: 24.sp),
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Bot Manager',
                  style: TextStyle(
                    color: const Color(0xFF151515),
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter',
                    letterSpacing: 0.06,
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
        onTap: () => _showAddBotSheet(context),
        child: _buildFAB(),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
              itemCount: bots.length + 2, // Search bar + List + Load more
              separatorBuilder: (context, index) => SizedBox(height: 16.h),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildSearchBar();
                }
                if (index == bots.length + 1) {
                  return Column(
                    children: [
                      SizedBox(height: 8.h),
                      _buildLoadMoreButton(),
                      SizedBox(height: 80.h),
                    ],
                  );
                }
                final bot = bots[index - 1];
                return _buildBotCard(
                  context,
                  index: index - 1,
                  title: bot['title'],
                  status: bot['status'],
                  statusColor: bot['status'] == 'Active' ? const Color(0xFFE7F6EC) : const Color(0xFFE0E6F3),
                  statusTextColor: bot['status'] == 'Active' ? const Color(0xFF027A48) : const Color(0xFF5369A1),
                  type: bot['type'],
                  trigger: bot['trigger'],
                  createdOn: bot['createdOn'],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddBotSheet(BuildContext context) {
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
              top: 24.h,
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
                  'Add Bot',
                  style: TextStyle(
                    fontSize: 18.sp,
                    height: 24 / 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF151C27),
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
                SizedBox(height: 24.h),
                _buildOptionItem(
                  icon: Iconsax.messages_3_copy,
                  title: 'Simple Bot Reply',
                  onTap: () {
                    context.pop();
                    context.push(AppRoutes.simpleBotReply);
                  },
                ),
                _buildDivider(),
                _buildOptionItem(
                  icon: Iconsax.gallery_copy,
                  title: 'Media Bot Reply',
                  onTap: () {
                    context.pop();
                    context.push(AppRoutes.mediaBotReply);
                  },
                ),
                _buildDivider(),
                _buildOptionItem(
                  icon: Iconsax.flash_1_copy,
                  title: 'Advance Interactive Bot Reply',
                  onTap: () {
                    context.pop();
                    context.push(AppRoutes.advanceInteractiveBotReply);
                  },
                ),
                _buildDivider(),
                _buildOptionItem(
                  icon: Iconsax.element_plus_copy,
                  title: 'Template Bot Reply',
                  onTap: () {
                    context.pop();
                    context.push(AppRoutes.templateBotReply);
                  },
                ),
                SizedBox(height: 24.h),
                _buildCancelButton(context),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showBotActionsSheet(BuildContext context, int index) {
    final bot = bots[index];
    bool isActive = bot['status'] == 'Active';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.1),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                  top: 24.h,
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
                      'Bot Actions',
                      style: TextStyle(
                        fontSize: 18.sp,
                        height: 24 / 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF151C27),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    SizedBox(height: 24.h),
                    _buildOptionItem(
                      icon: Iconsax.edit_2_copy,
                      title: 'Edit',
                      onTap: () {
                        context.pop();
                        _navigateToEdit(bot);
                      },
                    ),
                    _buildDivider(),
                    _buildOptionItem(
                      icon: Iconsax.copy_copy,
                      title: 'Clone',
                      onTap: () {
                        setState(() {
                          final newBot = Map<String, dynamic>.from(bot);
                          newBot['title'] = '${bot['title']} (Copy)';
                          // Insert the clone right after the original bot
                          bots.insert(index + 1, newBot);
                        });
                        context.pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('"${bot['title']}" cloned successfully'),
                            backgroundColor: const Color(0xFF006C70),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildOptionItem(
                      icon: Iconsax.toggle_on_copy,
                      title: 'Status',
                      onTap: () {
                        bool newValue = !isActive;
                        setModalState(() {
                          isActive = newValue;
                        });
                        setState(() {
                          bots[index]['status'] = newValue ? 'Active' : 'Inactive';
                        });
                      },
                      trailing: Switch.adaptive(
                        value: isActive,
                        activeColor: const Color(0xFF006C70),
                        onChanged: (value) {
                          setModalState(() {
                            isActive = value;
                          });
                          setState(() {
                            bots[index]['status'] = value ? 'Active' : 'Inactive';
                          });
                        },
                      ),
                    ),
                    _buildDivider(),
                    _buildOptionItem(
                      icon: Iconsax.trash_copy,
                      title: 'Delete',
                      iconColor: const Color(0xFFD92D20),
                      onTap: () {
                        context.pop();
                        _showDeleteConfirmation(context, index);
                      },
                    ),
                    SizedBox(height: 24.h),
                    _buildCancelButton(context),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _navigateToEdit(Map<String, dynamic> bot) {
    final botType = bot['botType'];
    switch (botType) {
      case 'simple':
        context.push(AppRoutes.simpleBotReply, extra: bot);
        break;
      case 'media':
        context.push(AppRoutes.mediaBotReply, extra: bot);
        break;
      case 'advance':
        context.push(AppRoutes.advanceInteractiveBotReply, extra: bot);
        break;
      case 'template':
        context.push(AppRoutes.templateBotReply, extra: bot);
        break;
      default:
        context.push(AppRoutes.simpleBotReply, extra: bot);
    }
  }

  void _showDeleteConfirmation(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bot'),
        content: const Text('Are you sure you want to delete this bot?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                bots.removeAt(index);
              });
              Navigator.pop(context); // Close confirmation dialog
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

  Widget _buildCancelButton(BuildContext context) {
    return SizedBox(
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
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: const Color(0xFFF0F3FF),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Widget? trailing,
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
            trailing ??
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
                hintText: 'Search bots',
                hintStyle: TextStyle(
                  color: const Color(0xFF9A9AA5),
                  fontSize: 16.sp,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                filled: false,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotCard(
    BuildContext context, {
    required int index,
    required String title,
    required String status,
    required Color statusColor,
    required Color statusTextColor,
    required String type,
    required String trigger,
    required String createdOn,
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
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  GestureDetector(
                    onTap: () => _showBotActionsSheet(context, index),
                    behavior: HitTestBehavior.opaque,
                    child: Icon(Icons.more_vert, color: const Color(0xFF98A2B3), size: 20.sp),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 18.h),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem('TYPE', type),
              ),
              Expanded(
                child: _buildInfoItem('TRIGGER', trigger),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildInfoItem('CREATED ON', createdOn),
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
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF344054),
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
      ],
    );
  }

  Widget _buildLoadMoreButton() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(100.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Load More',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF344054),
            ),
          ),
          SizedBox(width: 4.w),
          Icon(Icons.keyboard_arrow_down, color: const Color(0xFF344054), size: 18.sp),
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
            Icon(Icons.smart_toy_outlined, color: Colors.white, size: 24.sp),
            Icon(Icons.add, color: Colors.white, size: 14.sp),
          ],
        ),
      ),
    );
  }
}
