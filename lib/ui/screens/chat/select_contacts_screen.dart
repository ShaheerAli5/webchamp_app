import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class SelectContactsScreen extends StatefulWidget {
  const SelectContactsScreen({super.key});

  @override
  State<SelectContactsScreen> createState() => _SelectContactsScreenState();
}

class _SelectContactsScreenState extends State<SelectContactsScreen> {
  final List<Map<String, String>> _allContacts = [
    {'name': 'Aazam Bashir', 'phone': '+92 300 1234567'},
    {'name': 'WabChamp', 'phone': '+91 98765 43210'},
    {'name': 'Atta', 'phone': '+92 311 2345678'},
    {'name': 'Ibrahim', 'phone': '+92 321 3456789'},
    {'name': 'Rehmanullah', 'phone': '+92 333 4567890'},
    {'name': 'John Doe', 'phone': '+1 234 567 890'},
    {'name': 'Jane Smith', 'phone': '+1 987 654 321'},
  ];

  final List<Map<String, String>> _selectedContacts = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(64.h),
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
                  child: Icon(Icons.arrow_back, color: const Color(0xFF151515), size: 28.sp),
                ),
                SizedBox(width: 16.w),
                Text(
                  'Select Contacts',
                  style: TextStyle(
                    color: const Color(0xFF151515),
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
                const Spacer(),
                if (_selectedContacts.isNotEmpty)
                  TextButton(
                    onPressed: () => context.pop(_selectedContacts),
                    child: Text(
                      'Done',
                      style: TextStyle(
                        color: const Color(0xFF007176),
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: ListView.separated(
              itemCount: _allContacts.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF2F4F7)),
              itemBuilder: (context, index) {
                final contact = _allContacts[index];
                final isSelected = _selectedContacts.contains(contact);
                return ListTile(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedContacts.remove(contact);
                      } else {
                        _selectedContacts.add(contact);
                      }
                    });
                  },
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFF2F4F7),
                    child: Text(
                      contact['name']![0],
                      style: const TextStyle(color: Color(0xFF667085)),
                    ),
                  ),
                  title: Text(
                    contact['name']!,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF151C27),
                    ),
                  ),
                  subtitle: Text(
                    contact['phone']!,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: const Color(0xFF667085),
                    ),
                  ),
                  trailing: Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedContacts.add(contact);
                        } else {
                          _selectedContacts.remove(contact);
                        }
                      });
                    },
                    activeColor: const Color(0xFF007176),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48.h,
      margin: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(12.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Icon(Icons.search, color: const Color(0xFF667085), size: 20.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search contacts',
                hintStyle: TextStyle(
                  color: const Color(0xFF667085),
                  fontSize: 14.sp,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
