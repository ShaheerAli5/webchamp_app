import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class AddBotFlowScreen extends StatefulWidget {
  const AddBotFlowScreen({super.key});

  @override
  State<AddBotFlowScreen> createState() => _AddBotFlowScreenState();
}

class _AddBotFlowScreenState extends State<AddBotFlowScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _triggerController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _triggerController.dispose();
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
                  'Add New Bot Flow',
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
                          _buildLabel('FLOW TITLE'),
                          TextField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              hintText: 'Enter flow title',
                            ),
                            style: TextStyle(
                              color: const Color(0xFF151C27),
                              fontSize: 14.sp,
                              fontFamily: 'Plus Jakarta Sans',
                              height: 20 / 14,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          _buildLabel('START TRIGGER SUBJECT'),
                          SizedBox(
                            height: 100.h,
                            child: TextField(
                              controller: _triggerController,
                              maxLines: null,
                              expands: true,
                              textAlignVertical: TextAlignVertical.top,
                              decoration: const InputDecoration(
                                hintText: 'Enter trigger words',
                              ),
                              style: TextStyle(
                                color: const Color(0xFF151C27),
                                fontSize: 14.sp,
                                fontFamily: 'Plus Jakarta Sans',
                                height: 20 / 14,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 16.h),
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: const Color(0xFF3C494B).withOpacity(0.8),
                                  fontFamily: 'Plus Jakarta Sans',
                                  height: 18 / 12,
                                ),
                                children: const [
                                  TextSpan(
                                    text: 'You can have comma separated multiple triggers.\n',
                                    style: TextStyle(fontStyle: FontStyle.italic),
                                  ),
                                  TextSpan(
                                    text: 'Users will start this flow when they mention these subjects.',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 20.h),
                      child: Column(
                        children: [
                          SizedBox(height: 24.h),
                          const Divider(color: Color(0xFFF2F4F7), height: 1),
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
          fontFamily: 'Plus Jakarta Sans',
          letterSpacing: 0.55.sp,
          height: 16 / 11,
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
