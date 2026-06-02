import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  bool _optOutMarketing = false;
  bool _enableReplyBot = true;
  String? _selectedCountry;
  String? _selectedLanguage;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otherInfoController = TextEditingController();

  final Map<String, String> _countryCodes = {
    'Pakistan': '92',
    'United States': '1',
    'United Kingdom': '44',
    'United Arab Emirates': '971',
    'Saudi Arabia': '966',
    'India': '91',
    'Canada': '1',
    'Australia': '61',
  };

  final List<String> _languages = ['English', 'Urdu'];

  void _onCountryChanged(String? country) {
    setState(() {
      _selectedCountry = country;
      if (country != null && _countryCodes.containsKey(country)) {
        String code = _countryCodes[country]!;
        _mobileController.text = code;
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _otherInfoController.dispose();
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
            border: Border(bottom: BorderSide(color: Color(0xFFE8E8EC), width: 1)),
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
                    child: Icon(Icons.arrow_back, size: 20.sp, color: Colors.black),
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Add New Contact',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
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
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(color: const Color(0xFFE8E8EC)),
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
                          _buildFieldContainer('FIRST NAME', _buildTextField('Enter first name', controller: _firstNameController)),
                          _buildFieldContainer('LAST NAME', _buildTextField('Enter last name', controller: _lastNameController)),
                          _buildFieldContainer('COUNTRY', _buildCountryDropdown()),
                          _buildMobileFieldContainer(),
                          _buildFieldContainer('LANGUAGE', _buildLanguageDropdown()),
                          _buildFieldContainer('EMAIL', _buildTextField('email@example.com', controller: _emailController)),
                          _buildFieldContainer('GROUPS', _buildDropdownField('Select groups')),
                          SizedBox(height: 8.h),
                          _buildSwitchRow(
                            'Opt out marketing messages',
                            _optOutMarketing,
                            (val) => setState(() => _optOutMarketing = val),
                          ),
                          SizedBox(height: 12.h),
                          _buildSwitchRow(
                            'Enable reply bot',
                            _enableReplyBot,
                            (val) => setState(() => _enableReplyBot = val),
                          ),
                          SizedBox(height: 16.h),
                          const Divider(color: Color(0xFFE8E8EC)),
                          SizedBox(height: 16.h),
                          _buildFieldContainer('OTHER INFORMATION', _buildTextField('', maxLines: 4, controller: _otherInfoController), height: 112.h),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 20.h),
                      child: Column(
                        children: [
                          SizedBox(height: 24.h),
                          const Divider(color: Color(0xFFE8E8EC)),
                          SizedBox(height: 24.h),
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  'Close',
                                  const Color(0xFFF2F4F7),
                                  const Color(0xFF344054),
                                  () => context.pop(),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: _buildActionButton(
                                  'Submit',
                                  const Color(0xFF007176),
                                  Colors.white,
                                  () {},
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

  Widget _buildFieldContainer(String label, Widget child, {double? height}) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF667085),
              fontFamily: 'Inter',
            ),
          ),
          SizedBox(height: 8.h),
          SizedBox(
            height: height ?? 44.h,
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFieldContainer() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MOBILE NUMBER',
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF667085),
              fontFamily: 'Inter',
            ),
          ),
          Text(
            'Number should be with country code without 0 or +',
            style: TextStyle(
              fontSize: 9.sp,
              color: const Color(0xFF98A2B3),
              fontFamily: 'Inter',
            ),
          ),
          SizedBox(height: 8.h),
          SizedBox(
            height: 44.h,
            child: _buildTextField('eg. 92 344 1234567', controller: _mobileController),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String hint, {int maxLines = 1, TextEditingController? controller}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(
          fontSize: 14.sp,
          color: const Color(0xFF151C27),
          fontFamily: 'Plus Jakarta Sans',
          fontWeight: FontWeight.w400,
          height: 20 / 14,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: const Color(0xFF98A2B3),
            fontSize: 14.sp,
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w400,
            height: 20 / 14,
          ),
          filled: true,
          fillColor: const Color(0xFFF4F4F4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: maxLines > 1 ? 12.h : 0),
        ),
      ),
    );
  }

  Widget _buildCountryDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(12.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCountry,
          hint: Text(
            'Select country',
            style: TextStyle(
              color: const Color(0xFF98A2B3),
              fontSize: 14.sp,
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w400,
              height: 20 / 14,
            ),
          ),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: const Color(0xFF667085), size: 20.sp),
          items: _countryCodes.keys.map((String country) {
            return DropdownMenuItem<String>(
              value: country,
              child: Text(
                country,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF151C27),
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w400,
                  height: 20 / 14,
                ),
              ),
            );
          }).toList(),
          onChanged: _onCountryChanged,
        ),
      ),
    );
  }

  Widget _buildLanguageDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(12.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedLanguage,
          hint: Text(
            'Select language',
            style: TextStyle(
              color: const Color(0xFF98A2B3),
              fontSize: 14.sp,
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w400,
              height: 20 / 14,
            ),
          ),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: const Color(0xFF667085), size: 20.sp),
          items: _languages.map((String language) {
            return DropdownMenuItem<String>(
              value: language,
              child: Text(
                language,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF151C27),
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w400,
                  height: 20 / 14,
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedLanguage = newValue;
            });
          },
        ),
      ),
    );
  }

  Widget _buildDropdownField(String hint) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            hint,
            style: TextStyle(
              color: const Color(0xFF98A2B3),
              fontSize: 14.sp,
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w400,
              height: 20 / 14,
            ),
          ),
          Icon(Icons.keyboard_arrow_down, color: const Color(0xFF667085), size: 20.sp),
        ],
      ),
    );
  }

  Widget _buildSwitchRow(String label, bool value, Function(bool) onChanged) {
    return SizedBox(
      width: double.infinity,
      height: 24.h,
      child: Row(
        children: [
          SizedBox(
            width: 40.w,
            child: Transform.scale(
              scale: 0.7,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeColor: const Color(0xFF007176),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF344054),
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, Color bgColor, Color textColor, VoidCallback onTap) {
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
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}
