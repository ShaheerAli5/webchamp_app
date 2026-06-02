import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class AddTemplateScreen extends StatefulWidget {
  const AddTemplateScreen({super.key});

  @override
  State<AddTemplateScreen> createState() => _AddTemplateScreenState();
}

class _AddTemplateScreenState extends State<AddTemplateScreen> {
  String _templateType = 'Header';

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _footerController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _bodyController.dispose();
    _footerController.dispose();
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
            titleSpacing: 0,
            automaticallyImplyLeading: false,
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
                SizedBox(width: 12.w),
                Text(
                  'Add New Template',
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
              child: Container(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 40.h,
                ),
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputGroup('TEMPLATE NAME', 'Enter template name', controller: _nameController),
                          SizedBox(height: 14.h),
                          _buildInputGroup('TEMPLATE LANGUAGE CODE', 'Select template language', isDropdown: true),
                          SizedBox(height: 14.h),
                          _buildInputGroup('CATEGORY', 'Marketing', isDropdown: true),
                          SizedBox(height: 14.h),
                          _buildLabel('CHOOSE TEMPLATE TYPE'),
                          SizedBox(
                            height: 20.h,
                            child: Row(
                              children: [
                                _buildRadioButton('Header'),
                                SizedBox(width: 20.w),
                                _buildRadioButton('Carousel'),
                              ],
                            ),
                          ),
                          SizedBox(height: 14.h),
                          _buildInputGroup('HEADER (OPTIONAL)', 'None', isDropdown: true),
                          SizedBox(height: 14.h),
                          _buildLabel('BODY'),
                          _buildTextArea(height: 112.h, controller: _bodyController),
                          SizedBox(height: 14.h),
                          _buildLabel('FOOTER (OPTIONAL)'),
                          _buildTextArea(height: 88.h, controller: _footerController),
                          SizedBox(height: 14.h),
                          const Divider(color: Color(0xFFEAECF0), height: 1),
                          SizedBox(height: 14.h),
                          _buildLabel('BUTTONS (OPTIONAL)'),
                          Text(
                            'Create buttons that let customers respond to your message or take action.',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: const Color(0xFF667085),
                              height: 1.4,
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildOptionButton(Icons.undo, 'Quick Reply Button'),
                              _buildOptionButton(Icons.phone_outlined, 'Phone Number Button'),
                              _buildOptionButton(Icons.copy_outlined, 'Copy Code Button'),
                              _buildOptionButton(Icons.link, 'URL Button'),
                              _buildOptionButton(Icons.language, 'Dynamic URL Button'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 20.h),
                      child: Column(
                        children: [
                          SizedBox(height: 24.h),
                          const Divider(color: Color(0xFFEAECF0), height: 1),
                          SizedBox(height: 24.h),
                          Row(
                            children: [
                              Expanded(
                                child: _buildFooterButton('Close', const Color(0xFFF2F4F7), const Color(0xFF344054), onTap: () => context.pop()),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: _buildFooterButton('Submit', const Color(0xFF007176), Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
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
          color: const Color(0xFF667085),
          letterSpacing: 0.55,
          fontFamily: 'Plus Jakarta Sans',
        ),
      ),
    );
  }

  Widget _buildInputGroup(String label, String value, {bool isDropdown = false, TextEditingController? controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        Container(
          height: 44.h,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F4F4),
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: isDropdown 
                ? Text(
                  value,
                  style: TextStyle(
                    color: value != 'Select template language' && value != 'Marketing' && value != 'None'
                        ? const Color(0xFF151C27) 
                        : const Color(0xFF98A2B3),
                    fontSize: 14.sp,
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w400,
                  ),
                )
                : TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: value,
                    hintStyle: TextStyle(
                      color: const Color(0xFF98A2B3),
                      fontSize: 14.sp,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: TextStyle(
                    color: const Color(0xFF151C27),
                    fontSize: 14.sp,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ),
              if (isDropdown)
                Icon(Icons.keyboard_arrow_down, color: const Color(0xFF667085), size: 20.sp),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRadioButton(String value) {
    bool isSelected = _templateType == value;
    return GestureDetector(
      onTap: () => setState(() => _templateType = value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18.w,
            height: 18.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? const Color(0xFF007176) : const Color(0xFFD0D5DD),
                width: isSelected ? 5.w : 1.w,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp, 
              color: const Color(0xFF151C27),
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextArea({required double height, TextEditingController? controller}) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(12.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: TextField(
        controller: controller,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12.h),
        ),
        style: TextStyle(
          color: const Color(0xFF151C27),
          fontSize: 14.sp,
          fontFamily: 'Plus Jakarta Sans',
        ),
      ),
    );
  }

  Widget _buildOptionButton(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Container(
        height: 34.h,
        decoration: BoxDecoration(
          color: const Color(0xFF007176),
          borderRadius: BorderRadius.circular(9999.r),
        ),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16.sp),
            SizedBox(width: 8.w),
            Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
          ],
        ),
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
            fontWeight: FontWeight.w600,
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
      ),
    );
  }
}
