import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:go_router/go_router.dart';

class SimpleBotReplyScreen extends StatefulWidget {
  const SimpleBotReplyScreen({super.key});

  @override
  State<SimpleBotReplyScreen> createState() => _SimpleBotReplyScreenState();
}

class _SimpleBotReplyScreenState extends State<SimpleBotReplyScreen> {
  bool _isStatusActive = true;
  bool _isValidateActive = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _replyTextController = TextEditingController();
  final TextEditingController _triggerSubjectController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _replyTextController.dispose();
    _triggerSubjectController.dispose();
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
                  child: Container(
                    height: 40.h,
                    alignment: Alignment.center,
                    child: Icon(Icons.arrow_back, color: Colors.black, size: 24.sp),
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Simple Bot Reply',
                  style: TextStyle(
                    color: const Color(0xFF151515),
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 40.h),
          child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: const Color(0xFFEAECF0)),
          ),
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                icon: Iconsax.message_2_copy,
                title: 'REPLY MESSAGE',
                color: const Color(0xFF007176),
                bgColor: const Color(0xFFE0F2F2),
              ),
              SizedBox(height: 20.h),
              _buildInputGroup('NAME', 'Enter bot name', controller: _nameController),
              SizedBox(height: 16.h),
              _buildInputGroup('REPLY TEXT', 'Enter reply text', isTextArea: true, height: 100.h, controller: _replyTextController),
              SizedBox(height: 16.h),
              _buildInputGroup('TEMPLATE LANGUAGE CODE', 'Select template language', isDropdown: true),
              SizedBox(height: 16.h),
              _buildInputGroup('CATEGORY', 'Marketing', isDropdown: true),
              SizedBox(height: 16.h),
              _buildLabel('TAP VARIABLES TO INSERT INTO YOUR REPLY'),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  _buildVariableChip('{first_name}', controller: _replyTextController),
                  _buildVariableChip('{last_name}', controller: _replyTextController),
                  _buildVariableChip('{phone_number}', controller: _replyTextController),
                  _buildVariableChip('{email}', controller: _replyTextController),
                  _buildVariableChip('{country}', controller: _replyTextController),
                  _buildVariableChip('{language_code}', controller: _replyTextController),
                ],
              ),
              SizedBox(height: 24.h),
              const Divider(color: Color(0xFFF2F4F7), height: 1),
              SizedBox(height: 24.h),
              _buildSectionHeader(
                icon: Iconsax.flash_1_copy,
                title: 'TRIGGER SETTINGS',
                color: const Color(0xFF6D8C00),
                bgColor: const Color(0xFFF4F9E6),
              ),
              SizedBox(height: 20.h),
              _buildInputGroup('TRIGGER TYPE', 'How do you want to trigger message?', isDropdown: true),
              SizedBox(height: 16.h),
              _buildInputGroup(
                'REPLY TRIGGER SUBJECT',
                'What\'s that magic words that will trigger this reply?',
                isTextArea: true,
                height: 80.h,
                controller: _triggerSubjectController,
              ),
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Text(
                  'You can have comma separated multiple triggers.',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF667085),
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              const Divider(color: Color(0xFFF2F4F7), height: 1),
              SizedBox(height: 24.h),
              _buildSectionHeader(
                icon: Iconsax.status_copy,
                title: 'STATUS & VALIDATION',
                color: const Color(0xFFB42318),
                bgColor: const Color(0xFFFEF3F2),
              ),
              SizedBox(height: 20.h),
              _buildSwitchRow(
                'STATUS',
                'Bot response is currently active',
                _isStatusActive,
                (val) => setState(() => _isStatusActive = val),
              ),
              SizedBox(height: 16.h),
              _buildSwitchRow(
                'VALIDATE BOT REPLY',
                'Sending Test Message after save',
                _isValidateActive,
                (val) => setState(() => _isValidateActive = val),
              ),
              SizedBox(height: 32.h),
              const Divider(color: Color(0xFFF2F4F7), height: 1),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: _buildFooterButton(
                      'Close',
                      const Color(0xFFEFEFEF),
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
        ),
      ),
    ),
  );
}

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
    required Color bgColor,
  }) {
    return Row(
      children: [
        Container(
          width: 32.w,
          height: 32.w,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16.sp),
        ),
        SizedBox(width: 12.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.5,
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF475467), // Updated to match greyish label color
          fontFamily: 'Plus Jakarta Sans',
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildInputGroup(String label, String hint, {bool isDropdown = false, bool isTextArea = false, double? height, TextEditingController? controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        if (isDropdown)
          Container(
            height: height ?? 44.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F7),
              borderRadius: BorderRadius.circular(12.r),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hint,
                    style: TextStyle(
                      color: hint != 'Select template language' && hint != 'How do you want to trigger message?' && hint != 'Marketing'
                          ? const Color(0xFF151C27) 
                          : const Color(0xFF98A2B3),
                      fontSize: 14.sp,
                      fontFamily: 'Plus Jakarta Sans',
                      height: 1.2,
                    ),
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, color: const Color(0xFF667085), size: 20.sp),
              ],
            ),
          )
        else
          SizedBox(
            height: height,
            child: TextField(
              controller: controller,
              maxLines: isTextArea ? null : 1,
              expands: isTextArea,
              textAlignVertical: isTextArea ? TextAlignVertical.top : TextAlignVertical.center,
              decoration: InputDecoration(
                hintText: hint == 'Enter reply text' ? '' : hint,
              ),
              style: TextStyle(
                color: const Color(0xFF151C27),
                fontSize: 14.sp,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVariableChip(String text, {TextEditingController? controller}) {
    return GestureDetector(
      onTap: () {
        if (controller != null) {
          final currentText = controller.text;
          final selection = controller.selection;
          final newText = currentText.replaceRange(
            selection.start == -1 ? currentText.length : selection.start,
            selection.end == -1 ? currentText.length : selection.end,
            text,
          );
          controller.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(
              offset: (selection.start == -1 ? currentText.length : selection.start) + text.length,
            ),
          );
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2F2),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: const Color(0xFFB2D4D4)),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF007176),
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchRow(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Transform.scale(
            scale: 0.8,
            child: Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeTrackColor: const Color(0xFF007176),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF344054),
                    fontFamily: 'Plus Jakarta Sans',
                    height: 1.2,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: const Color(0xFF667085),
                    fontFamily: 'Plus Jakarta Sans',
                    height: 1.2,
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
        padding: EdgeInsets.symmetric(horizontal: 12.w),
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
