import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../routes/app_routes.dart';
import '../../../features/contacts/presentation/providers/contact_group_provider.dart';
import '../../../core/utils/helpers.dart';

class CreateNewListScreen extends StatefulWidget {
  const CreateNewListScreen({super.key});

  @override
  State<CreateNewListScreen> createState() => _CreateNewListScreenState();
}

class _CreateNewListScreenState extends State<CreateNewListScreen> {
  final TextEditingController _listNameController = TextEditingController();
  List<dynamic> _selectedContacts = [];

  @override
  void dispose() {
    _listNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
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
                  'Create New List',
                  style: TextStyle(
                    color: const Color(0xFF151515),
                    fontSize: 22.sp,
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
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Container(
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
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('LIST NAME'),
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
                    controller: _listNameController,
                    decoration: InputDecoration(
                      hintText: 'List name',
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
                _buildLabel('INCLUDED'),
                SizedBox(height: 8.h),
                InkWell(
                  onTap: () async {
                    final result = await context.push(AppRoutes.selectContacts);
                    if (result != null && result is List) {
                      setState(() {
                        _selectedContacts = result;
                      });
                    }
                  },
                  child: Row(
                    children: [
                      Icon(Icons.add_circle, color: const Color(0xFF007176), size: 24.sp),
                      SizedBox(width: 8.w),
                      Text(
                        _selectedContacts.isEmpty 
                            ? 'Add people' 
                            : '${_selectedContacts.length} people selected',
                        style: TextStyle(
                          color: const Color(0xFF344054),
                          fontSize: 14.sp,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                    ],
                  ),
                ),
                if (_selectedContacts.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: _selectedContacts.map((contact) {
                      final name = Helpers.sanitizeString((contact['full_name'] ?? contact['first_name'] ?? 'No Name').toString());
                      return Chip(
                        label: Text(name, style: TextStyle(fontSize: 12.sp)),
                        backgroundColor: const Color(0xFFF2F4F7),
                        onDeleted: () {
                          setState(() {
                            _selectedContacts.remove(contact);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
                SizedBox(height: 32.h),
                Consumer<ContactGroupProvider>(
                  builder: (context, provider, child) {
                    return SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: ElevatedButton(
                        onPressed: provider.isLoading ? null : () async {
                          final name = _listNameController.text.trim();
                          if (name.isEmpty) {
                            Helpers.showSnackBar(context, 'Please enter a list name');
                            return;
                          }
                          
                          final success = await provider.createGroup(name);
                          if (success && mounted) {
                            // If we have selected contacts, assign them
                            if (_selectedContacts.isNotEmpty) {
                              // We need to find the UID of the newly created group.
                              // Since createGroup refreshes the list, we can find it by name or just assume it's the last one.
                              final newGroup = provider.groups.firstWhere(
                                (g) => (g['title'] ?? g['name']) == name,
                                orElse: () => null,
                              );
                              
                              if (newGroup != null) {
                                final groupUid = (newGroup['uid'] ?? newGroup['id']).toString();
                                final contactUids = _selectedContacts.map((c) => (c['uid'] ?? c['id']).toString()).toList();
                                await provider.assignContactsToGroup(contactUids, [groupUid]);
                              }
                            }
                            
                            Helpers.showSnackBar(context, 'List "$name" created successfully');
                            context.pop();
                          } else if (provider.errorMessage != null && mounted) {
                            Helpers.showSnackBar(context, provider.errorMessage!);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007176),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: 0,
                        ),
                        child: provider.isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Create List',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Inter',
                              ),
                            ),
                      ),
                    );
                  },
                ),
              ],
            ),
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
}
