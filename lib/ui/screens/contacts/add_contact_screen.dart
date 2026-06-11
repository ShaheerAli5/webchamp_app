import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../features/contacts/presentation/providers/contact_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AddContactScreen extends StatefulWidget {
  final Map<String, dynamic>? contactData;
  const AddContactScreen({super.key, this.contactData});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  bool _optOutMarketing = false;
  bool _enableReplyBot = true;
  bool _enableAiBot = true;
  
  dynamic _selectedCountryId;
  String? _selectedLanguage = 'en';
  List<int> _selectedGroups = [];

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool get isEditing => widget.contactData != null;

  @override
  void initState() {
    super.initState();
    _initializeData();
    
    // Fetch fresh data from API
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMetadataAndContact();
    });
  }

  void _initializeData() {
    if (isEditing) {
      final data = widget.contactData!;
      _firstNameController.text = (data['first_name'] ?? data['fname'] ?? '').toString();
      _lastNameController.text = (data['last_name'] ?? data['lname'] ?? '').toString();
      _mobileController.text = (data['wa_id'] ?? data['phone_number'] ?? data['mobile_number'] ?? '').toString();
      _emailController.text = (data['email'] ?? '').toString();
      _addressController.text = (data['address'] ?? '').toString();
      
      _selectedLanguage = data['language_code'] ?? data['language'] ?? 'en';
      _optOutMarketing = data['whatsapp_opt_out'] == '1' || data['whatsapp_opt_out'] == true || data['opt_out'] == 1 || data['opt_out'] == true;
      _enableReplyBot = data['enable_reply_bot'] == true || data['disable_reply_bot'] == false || data['disable_reply_bot'] == 0 || data['disable_reply_bot'] == '0';
      _enableAiBot = data['enable_ai_bot'] == true;
      
      if (data['contact_groups'] is List) {
        try {
           _selectedGroups = List<int>.from(data['contact_groups'].map((e) => e is int ? e : int.parse(e.toString())));
        } catch (_) {}
      }
      
      final countryVal = data['country'];
      if (countryVal != null) {
        if (countryVal is int) {
          _selectedCountryId = countryVal;
        } else if (countryVal is Map && countryVal['id'] != null) {
          _selectedCountryId = countryVal['id'];
        }
      }
    }
  }

  Future<void> _loadMetadataAndContact() async {
    final provider = context.read<ContactProvider>();
    
    // Fetch specific metadata for the form
    await provider.getContactMetadata();
    
    if (isEditing) {
      final phone = _mobileController.text;
      final email = _emailController.text;
      
      if (phone.isNotEmpty || email.isNotEmpty) {
        await provider.getContact(
          phoneNumber: phone.isNotEmpty ? phone : null,
          email: email.isNotEmpty ? email : null,
        );
        
        if (provider.selectedContact != null && mounted) {
          setState(() {
            final data = provider.selectedContact!;
            _firstNameController.text = (data['first_name'] ?? data['fname'] ?? _firstNameController.text).toString();
            _lastNameController.text = (data['last_name'] ?? data['lname'] ?? _lastNameController.text).toString();
            _emailController.text = (data['email'] ?? _emailController.text).toString();
            _addressController.text = (data['address'] ?? _addressController.text).toString();
            
            _selectedLanguage = data['language_code'] ?? data['language'] ?? _selectedLanguage;
            _optOutMarketing = data['whatsapp_opt_out'] == '1' || data['whatsapp_opt_out'] == true || data['opt_out'] == 1 || data['opt_out'] == true;
            _enableReplyBot = data['enable_reply_bot'] == true || data['disable_reply_bot'] == false || data['disable_reply_bot'] == 0 || data['disable_reply_bot'] == '0';
            _enableAiBot = data['enable_ai_bot'] == true;

            if (data['contact_groups'] is List) {
              try {
                 _selectedGroups = List<int>.from(data['contact_groups'].map((e) => e is int ? e : int.parse(e.toString())));
              } catch (_) {}
            }

            final countryVal = data['country'];
            if (countryVal != null) {
              if (countryVal is int) {
                _selectedCountryId = countryVal;
              } else if (countryVal is Map && countryVal['id'] != null) {
                _selectedCountryId = countryVal['id'];
              }
            }
          });
        }
      }
    }
    
    if (mounted) setState(() {});
  }

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'ur', 'name': 'Urdu'},
  ];

  void _onCountryChanged(dynamic countryId) {
    setState(() {
      _selectedCountryId = countryId;
      if (!isEditing && countryId != null) {
        final provider = context.read<ContactProvider>();
        final countries = provider.availableCountries;
        final country = countries.firstWhere((c) => c['id'] == countryId || c['countries__id'] == countryId, orElse: () => null);
        if (country != null) {
          _mobileController.text = (country['phone_code'] ?? country['code'] ?? '').toString();
        }
      }
    });
  }

  Future<void> _submit() async {
    final contactProvider = context.read<ContactProvider>();

    if (_firstNameController.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: "First name is required");
      return;
    }

    if (_selectedCountryId == null) {
      Fluttertoast.showToast(msg: "Country is required");
      return;
    }

    if (!isEditing && _mobileController.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: "Phone number is required");
      return;
    }

    final email = _emailController.text.trim();
    final address = _addressController.text.trim();
    if (email.isNotEmpty && !email.contains('@')) {
      Fluttertoast.showToast(msg: "Enter a valid email");
      return;
    }

    bool success;
    if (isEditing) {
      final uid = widget.contactData!['_uid']?.toString() ?? widget.contactData!['uid']?.toString();
      if (uid == null) {
        Fluttertoast.showToast(msg: "Error: Contact UID not found");
        return;
      }

      success = await contactProvider.updateContact(
        uid,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: email.isEmpty ? null : email,
        address: address.isEmpty ? null : address,
        languageCode: _selectedLanguage,
        country: _selectedCountryId,
        contactGroups: _selectedGroups,
        whatsappOptOut: _optOutMarketing,
        enableAiBot: _enableAiBot,
        enableReplyBot: _enableReplyBot,
      );
    } else {
      success = await contactProvider.createContact(
        phoneNumber: _mobileController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: email.isEmpty ? null : email,
        address: address.isEmpty ? null : address,
        languageCode: _selectedLanguage,
        country: _selectedCountryId,
        contactGroups: _selectedGroups,
        whatsappOptOut: _optOutMarketing,
        enableAiBot: _enableAiBot,
        enableReplyBot: _enableReplyBot,
      );
    }

    if (success) {
      Fluttertoast.showToast(msg: isEditing ? "Contact updated successfully" : "Contact created successfully");
      if (mounted) context.pop();
    } else {
      Fluttertoast.showToast(
          msg: contactProvider.errorMessage ?? (isEditing ? "Failed to update contact" : "Failed to create contact"));
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: _buildAppBar(),
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
                          _buildFieldContainer('FIRST NAME *', _buildTextField('Enter first name', controller: _firstNameController)),
                          _buildFieldContainer('LAST NAME', _buildTextField('Enter last name', controller: _lastNameController)),
                          _buildFieldContainer('COUNTRY *', _buildCountryDropdown()),
                          _buildMobileFieldContainer(),
                          _buildFieldContainer('LANGUAGE', _buildLanguageDropdown()),
                          _buildFieldContainer('EMAIL', _buildTextField('Enter email', controller: _emailController)),
                          _buildFieldContainer('ADDRESS', _buildTextField('Enter address', controller: _addressController)),
                          _buildFieldContainer('GROUPS', _buildGroupsMultiSelect()),
                          SizedBox(height: 8.h),
                          _buildSwitchRow(
                            'WhatsApp Opt Out',
                            _optOutMarketing,
                            (val) => setState(() => _optOutMarketing = val),
                          ),
                          SizedBox(height: 12.h),
                          _buildSwitchRow(
                            'Enable AI Bot',
                            _enableAiBot,
                            (val) => setState(() => _enableAiBot = val),
                          ),
                          SizedBox(height: 12.h),
                          _buildSwitchRow(
                            'Enable Reply Bot',
                            _enableReplyBot,
                            (val) => setState(() => _enableReplyBot = val),
                          ),
                          SizedBox(height: 16.h),
                        ],
                      ),
                    ),
                    _buildBottomActions(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
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
                isEditing ? 'Edit Contact' : 'Create New Contact',
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
            'PHONE NUMBER ${isEditing ? "" : "*"}',
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF667085),
              fontFamily: 'Inter',
            ),
          ),
          if (!isEditing)
            Text(
              'Include country code without 0 or +',
              style: TextStyle(
                fontSize: 9.sp,
                color: const Color(0xFF98A2B3),
                fontFamily: 'Inter',
              ),
            ),
          SizedBox(height: 8.h),
          SizedBox(
            height: 44.h,
            child: _buildTextField('eg. 923441234567', controller: _mobileController, enabled: !isEditing),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String hint, {int maxLines = 1, TextEditingController? controller, bool enabled = true}) {
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
        enabled: enabled,
        style: TextStyle(
          fontSize: 14.sp,
          color: enabled ? const Color(0xFF151C27) : Colors.grey,
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
          fillColor: enabled ? const Color(0xFFF4F4F4) : const Color(0xFFE8E8EC),
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
    final countries = context.watch<ContactProvider>().availableCountries;

    if (countries.isEmpty) {
      return _buildTextField('Loading countries...', enabled: false);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Autocomplete<Map<String, dynamic>>(
          displayStringForOption: (option) => (option['name'] ?? option['countries__name'] ?? '').toString(),
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return countries.cast<Map<String, dynamic>>();
            }
            return countries.where((country) {
              final name = (country['name'] ?? country['countries__name'] ?? '').toString().toLowerCase();
              return name.contains(textEditingValue.text.toLowerCase());
            }).cast<Map<String, dynamic>>();
          },
          onSelected: (option) {
            final id = option['id'] ?? option['countries__id'];
            _onCountryChanged(id);
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            // Synchronize controller with selection if it exists
            if (_selectedCountryId != null && controller.text.isEmpty) {
              final selected = countries.firstWhere(
                (c) => (c['id'] ?? c['countries__id']) == _selectedCountryId,
                orElse: () => null,
              );
              if (selected != null) {
                controller.text = (selected['name'] ?? selected['countries__name'] ?? '').toString();
              }
            }

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
                focusNode: focusNode,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF151C27),
                  fontFamily: 'Plus Jakarta Sans',
                ),
                decoration: InputDecoration(
                  hintText: 'Search country...',
                  hintStyle: TextStyle(
                    color: const Color(0xFF98A2B3),
                    fontSize: 14.sp,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF4F4F4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: Icon(Icons.search, size: 20.sp, color: const Color(0xFF98A2B3)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                ),
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12.r),
                child: Container(
                  width: constraints.maxWidth,
                  constraints: BoxConstraints(maxHeight: 250.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        title: Text(
                          (option['name'] ?? option['countries__name'] ?? '').toString(),
                          style: TextStyle(fontSize: 14.sp),
                        ),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
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
            ),
          ),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: const Color(0xFF667085), size: 20.sp),
          items: _languages.map((lang) {
            return DropdownMenuItem<String>(
              value: lang['code'],
              child: Text(
                lang['name']!,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF151C27),
                  fontFamily: 'Plus Jakarta Sans',
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

  Widget _buildGroupsMultiSelect() {
    final availableGroups = context.watch<ContactProvider>().availableGroups;
    
    String text = _selectedGroups.isEmpty 
        ? 'Select groups' 
        : availableGroups
            .where((g) => _selectedGroups.contains(g['id'] ?? g['contact_groups__id']))
            .map((g) => g['name'] ?? g['contact_groups__name'] ?? '')
            .where((name) => name.isNotEmpty)
            .join(', ');

    return GestureDetector(
      onTap: () => _showGroupsDialog(availableGroups),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: _selectedGroups.isEmpty ? const Color(0xFF98A2B3) : const Color(0xFF151C27),
                  fontSize: 14.sp,
                  fontFamily: 'Plus Jakarta Sans',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down, color: const Color(0xFF667085), size: 20.sp),
          ],
        ),
      ),
    );
  }

  void _showGroupsDialog(List<dynamic> availableGroups) {
    if (availableGroups.isEmpty) {
      Fluttertoast.showToast(msg: "No groups available. Please create them in the web portal.");
      return;
    }
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Groups'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: availableGroups.map((group) {
                    final id = group['id'] ?? group['contact_groups__id'];
                    final name = group['name'] ?? group['contact_groups__name'] ?? 'Unnamed Group';
                    final isSelected = _selectedGroups.contains(id);
                    
                    return CheckboxListTile(
                      title: Text(name),
                      value: isSelected,
                      activeColor: const Color(0xFF007176),
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == true) {
                            if (id != null) _selectedGroups.add(id);
                          } else {
                            _selectedGroups.remove(id);
                          }
                        });
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done', style: TextStyle(color: Color(0xFF007176))),
                ),
              ],
            );
          },
        );
      },
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

  Widget _buildBottomActions() {
    return Padding(
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
                child: Consumer<ContactProvider>(
                  builder: (context, provider, child) {
                    return _buildActionButton(
                      provider.isLoading ? 'Processing...' : (isEditing ? 'Update Contact' : 'Save'),
                      const Color(0xFF007176),
                      Colors.white,
                      provider.isLoading ? () {} : _submit,
                    );
                  },
                ),
              ),
            ],
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
