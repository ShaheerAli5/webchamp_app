import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class AddTeamMemberScreen extends StatefulWidget {
  const AddTeamMemberScreen({super.key});

  @override
  State<AddTeamMemberScreen> createState() => _AddTeamMemberScreenState();
}

class _AddTeamMemberScreenState extends State<AddTeamMemberScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isAdmin = true;
  bool _manageContacts = false;
  bool _manageCampaigns = false;
  bool _messaging = true;
  bool _manageTemplates = false;
  bool _assignedChatOnly = false;
  bool _manageBots = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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
                  'Add New User',
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 40.h,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: const Color(0xFFEAECF0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 20.h),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputField('FIRST NAME', 'Enter first name', _firstNameController),
                          _buildInputField('LAST NAME', 'Enter last name', _lastNameController),
                          _buildInputField('MOBILE NUMBER', 'e.g. 91987654321', _mobileController),
                          _buildInputField('USERNAME', 'wabchamp', _usernameController),
                          _buildInputField('EMAIL', 'example@domain.com', _emailController),
                          _buildInputField('PASSWORD', '••••••••', _passwordController, isPassword: true),
                          
                          SizedBox(height: 12.h),
                          const Divider(color: Color(0xFFF2F4F7), height: 1),
                          SizedBox(height: 16.h),
                          
                          _buildLabel('PERMISSIONS'),
                          SizedBox(height: 16.h),
                          
                          _buildPermissionRow(
                            'ADMINISTRATIVE',
                            'Allow/Deny permissions like Configuration, Subscription, Team Members, Message Log etc',
                            _isAdmin,
                            (val) => setState(() => _isAdmin = val),
                          ),
                          _buildPermissionRow(
                            'MANAGE CONTACTS',
                            'Allow/Deny access for Manage Contacts, Groups, Custom Contact Fields etc',
                            _manageContacts,
                            (val) => setState(() => _manageContacts = val),
                          ),
                          _buildPermissionRow(
                            'MANAGE CAMPAIGNS',
                            'Allow/Deny access like Creating, Executing and Scheduling Campaigns etc',
                            _manageCampaigns,
                            (val) => setState(() => _manageCampaigns = val),
                          ),
                          _buildPermissionRow(
                            'MESSAGING',
                            'Allow/Deny access like Chat, Sync Templates etc',
                            _messaging,
                            (val) => setState(() => _messaging = val),
                          ),
                          _buildPermissionRow(
                            'MANAGE TEMPLATES',
                            'Allow/Deny access like Creating, Editing and Deleting Templates etc',
                            _manageTemplates,
                            (val) => setState(() => _manageTemplates = val),
                          ),
                          _buildPermissionRow(
                            'ASSIGNED CHAT ONLY',
                            'Restrict users to assigned chat only, unless they will have access to all chats',
                            _assignedChatOnly,
                            (val) => setState(() => _assignedChatOnly = val),
                          ),
                          _buildPermissionRow(
                            'MANAGE BOT REPLIES AND FLOWS',
                            'Allow/Deny access for Bot Replies and Flows',
                            _manageBots,
                            (val) => setState(() => _manageBots = val),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          SizedBox(height: 24.h),
                          const Divider(color: Color(0xFFEAECF0), height: 1),
                          SizedBox(height: 24.h),
                          Row(
                            children: [
                              Expanded(
                                child: _buildFooterButton(
                                  'Close',
                                  const Color(0xFFF2F4F7),
                                  const Color(0xFF344054),
                                  onTap: () => context.pop(),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: _buildFooterButton(
                                  'Submit',
                                  const Color(0xFF007176),
                                  Colors.white,
                                  onTap: () {},
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11.sp,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF667085),
        fontFamily: 'Plus Jakarta Sans',
        letterSpacing: 0.5.sp,
      ),
    );
  }

  Widget _buildInputField(String label, String hint, TextEditingController controller, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        SizedBox(height: 8.h),
        Container(
          height: 48.h,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F4F4),
            borderRadius: BorderRadius.circular(12.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          alignment: Alignment.centerLeft,
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: const Color(0xFF98A2B3),
                fontSize: 14.sp,
                fontFamily: 'Plus Jakarta Sans',
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
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
        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _buildPermissionRow(String title, String description, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40.w,
            height: 24.h,
            child: Transform.scale(
              scale: 0.7,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeColor: const Color(0xFF007176),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF344054),
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF667085),
                    fontFamily: 'Plus Jakarta Sans',
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterButton(String text, Color bgColor, Color textColor, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48.h,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(99.r),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}
