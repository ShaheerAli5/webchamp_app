import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class GeneralSettingsScreen extends StatefulWidget {
  const GeneralSettingsScreen({super.key});

  @override
  State<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends State<GeneralSettingsScreen> {
  final TextEditingController _vendorTitleController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String _selectedCountry = 'None';
  String _selectedTimezone = 'UTC';
  String _selectedLanguage = 'None';

  @override
  void dispose() {
    _vendorTitleController.dispose();
    _addressController.dispose();
    _postalCodeController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(56.h),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFEAECF0), width: 1),
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 20.w),
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
                  child: Icon(Icons.arrow_back, color: const Color(0xFF004D4F), size: 24.sp),
                ),
                SizedBox(width: 16.w),
                Text(
                  'Add New User',
                  style: TextStyle(
                    color: const Color(0xFF0A0A0A),
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(color: const Color(0xFFEAECF0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('BASIC SETTINGS'),
                _buildLabel('VENDOR TITLE'),
                _buildTextField(_vendorTitleController, 'Enter first name'),
                
                _buildSectionHeader('BUSINESS INFORMATION'),
                _buildLabel('ADDRESS LINE'),
                _buildTextField(_addressController, '123 Street Ave'),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('POSTAL CODE'),
                          _buildTextField(_postalCodeController, '0000'),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('CITY'),
                          _buildTextField(_cityController, 'City'),
                        ],
                      ),
                    ),
                  ],
                ),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('STATE'),
                          _buildTextField(_stateController, 'State'),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('COUNTRY'),
                          _buildDropdown(['None', 'USA', 'UK', 'Pakistan'], _selectedCountry, (val) {
                            setState(() => _selectedCountry = val!);
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
                
                _buildLabel('BUSINESS PHONE'),
                _buildTextField(_phoneController, '+12345123123'),
                
                _buildLabel('CONTACT EMAIL'),
                _buildTextField(_emailController, 'example@domain.com'),
                
                _buildSectionHeader('OTHER'),
                _buildLabel('TIMEZONE'),
                _buildDropdown(['UTC', 'GMT+5', 'EST'], _selectedTimezone, (val) {
                  setState(() => _selectedTimezone = val!);
                }),
                
                _buildLabel('DEFAULT LANGUAGE'),
                _buildDropdown(['None', 'English', 'Spanish'], _selectedLanguage, (val) {
                  setState(() => _selectedLanguage = val!);
                }),
                
                SizedBox(height: 32.h),
                const Divider(color: Color(0xFFEAECF0)),
                SizedBox(height: 24.h),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          height: 48.h,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F4F7),
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF344054),
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          height: 48.h,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFF006B70),
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                          ),
                        ),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 8.h, bottom: 16.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF006B70),
          fontFamily: 'Plus Jakarta Sans',
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF475467),
          letterSpacing: 0.5,
          fontFamily: 'Plus Jakarta Sans',
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: const Color(0xFF98A2B3),
            fontSize: 14.sp,
            fontFamily: 'Plus Jakarta Sans',
          ),
          filled: true,
          fillColor: const Color(0xFFF2F4F7).withOpacity(0.5),
          contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.r),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.r),
            borderSide: const BorderSide(color: Color(0xFF006B70), width: 1.5),
          ),
        ),
        style: TextStyle(
          fontSize: 14.sp,
          color: const Color(0xFF191C1E),
          fontFamily: 'Plus Jakarta Sans',
        ),
      ),
    );
  }

  Widget _buildDropdown(List<String> items, String value, void Function(String?) onChanged) {
    return Container(
      height: 48.h,
      margin: EdgeInsets.only(bottom: 20.h),
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7).withOpacity(0.5),
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: const Color(0xFF667085), size: 20.sp),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF191C1E),
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
