import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class AddTeamMemberScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const AddTeamMemberScreen({super.key, this.userData});

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
  void initState() {
    super.initState();
    if (widget.userData != null) {
      final nameParts = widget.userData!['name'].split(' ');
      _firstNameController.text = nameParts.isNotEmpty ? nameParts[0] : '';
      _lastNameController.text = nameParts.length > 1 ? nameParts[1] : '';
      _usernameController.text = widget.userData!['username'].replaceAll('@', '');
      _emailController.text = widget.userData!['email'];
      _mobileController.text = widget.userData!['phone'];
    }
  }

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
    final bool isEditing = widget.userData != null;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(64.h),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFF2F4F7), width: 1),
            ),
          ),
          padding: EdgeInsets.only(left: 8.w, right: 16.w),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            titleSpacing: 0,
            title: Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: Icon(Icons.arrow_back, color: const Color(0xFF151515), size: 24.sp),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                SizedBox(width: 8.w),
                Text(
                  isEditing ? 'Edit Data' : 'Add New User',
                  style: TextStyle(
                    color: const Color(0xFF151515),
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
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
                              onTap: () {
                                context.pop();
                                _showSuccessPopup(context, isEditing ? 'Successfully Updated' : 'Successfully Added');
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
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
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF344054),
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: const Color(0xFF667085),
                    fontFamily: 'Plus Jakarta Sans',
                    height: 1.3,
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
