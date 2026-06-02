import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:file_picker/file_picker.dart';

class UploadCsvScreen extends StatefulWidget {
  const UploadCsvScreen({super.key});

  @override
  State<UploadCsvScreen> createState() => _UploadCsvScreenState();
}

class _UploadCsvScreenState extends State<UploadCsvScreen> {
  String? _selectedFileName;
  bool _isUploading = false;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        setState(() {
          _selectedFileName = result.files.single.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
                child: Column(
                  children: [
                    _buildInfoBanner(),
                    SizedBox(height: 16.h),
                    _buildConventionsCard(),
                    SizedBox(height: 16.h),
                    _buildUploadBox(),
                    SizedBox(height: 40.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            'Close',
                            const Color(0xFFEFEFEF),
                            const Color(0xFF151515),
                            () => context.pop(),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _buildActionButton(
                            'Import',
                            const Color(0xFF007176),
                            Colors.white,
                            () {
                              if (_selectedFileName != null) {
                                // Handle import logic
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Importing $_selectedFileName...')),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please select a CSV file first')),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: 390.w,
      height: 57.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE8E8EC), width: 1)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Icon(Icons.arrow_back, size: 20.sp, color: Colors.black),
          ),
          SizedBox(width: 12.w),
          Text(
            'Import Contacts',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: 358.w,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Please use template from download contacts dialog.',
            style: TextStyle(
              fontSize: 11.5.sp,
              color: const Color(0xFF151515),
              fontFamily: 'Geist',
              height: 15 / 11.5,
              letterSpacing: -0.08.sp,
            ),
          ),
          Text(
            'You can import csv file with new contacts or existing updated.',
            style: TextStyle(
              fontSize: 11.5.sp,
              color: const Color(0xFF151515),
              fontFamily: 'Geist',
              height: 15 / 11.5,
              letterSpacing: -0.08.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConventionsCard() {
    return Container(
      width: 358.w,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28.w,
                height: 28.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFE4E4E4),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                alignment: Alignment.center,
                child: Icon(Iconsax.info_circle, color: const Color(0xFF667085), size: 14.sp),
              ),
              SizedBox(width: 12.w),
              Text(
                'Conventions',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF151515),
                  fontFamily: 'Inter',
                  height: 1.0,
                  letterSpacing: -0.08.sp,
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(left: 40.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16.h),
                _buildConventionItem(
                  'Mobile Number',
                  'Mobile number treated as unique entity, it should be with country code without prefixing 0 or +, if the Mobile number is found in the records other information for the same will get updated with data from the csv file.',
                ),
                SizedBox(height: 16.h),
                _buildConventionItem(
                  'Group',
                  'Use comma separated group title, make sure groups are already exists into the system. Groups won\'t be deleted, only new groups will be assigned.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConventionItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF151515),
            fontFamily: 'Inter',
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          description,
          style: TextStyle(
            fontSize: 12.sp,
            color: const Color(0xFF344054),
            fontFamily: 'Inter',
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildUploadBox() {
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        width: 358.w,
        height: 96.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: const Color(0xFFF2F4F7), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: const Color(0xFFE4E4E4),
                borderRadius: BorderRadius.circular(8.r),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.upload,
                color: const Color(0xFF151515),
                size: 24.sp,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _selectedFileName ?? 'SELECT CSV FILE',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: _selectedFileName != null ? const Color(0xFF007176) : const Color(0xFF3C494B),
                fontFamily: 'Plus Jakarta Sans',
                height: 16 / 11,
                letterSpacing: 0.55.sp,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, Color bgColor, Color textColor, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 0,
        fixedSize: Size(171.w, 48.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.r),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
      ),
    );
  }
}
