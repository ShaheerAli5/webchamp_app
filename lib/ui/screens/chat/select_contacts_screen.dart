import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/helpers.dart';
import '../../../features/contacts/presentation/providers/contact_provider.dart';

class SelectContactsScreen extends StatefulWidget {
  const SelectContactsScreen({super.key});

  @override
  State<SelectContactsScreen> createState() => _SelectContactsScreenState();
}

class _SelectContactsScreenState extends State<SelectContactsScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchTimer;
  final List<dynamic> _selectedContacts = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchContacts(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  void _fetchContacts({bool refresh = false}) {
    context.read<ContactProvider>().getContacts(
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
      refresh: refresh,
      autoLoadAll: true, // Ensure we get everything
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ContactProvider>(
      builder: (context, provider, child) {
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Select Contacts',
                          style: TextStyle(
                            color: const Color(0xFF151515),
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                          ),
                        ),
                        if (provider.contacts.isNotEmpty)
                          Text(
                            '${provider.contacts.length} contacts available',
                            style: TextStyle(
                              color: const Color(0xFF667085),
                              fontSize: 12.sp,
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    if (_selectedContacts.isNotEmpty)
                      TextButton(
                        onPressed: () => context.pop(_selectedContacts),
                        child: Text(
                          'Done (${_selectedContacts.length})',
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
              if (provider.isLoading && provider.contacts.isEmpty)
                const Expanded(child: Center(child: CircularProgressIndicator(color: Color(0xFF007176))))
              else if (provider.contacts.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      _searchController.text.isEmpty ? 'No contacts found.' : 'No results found for search.',
                      style: TextStyle(color: const Color(0xFF667085), fontSize: 14.sp),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: provider.contacts.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF2F4F7)),
                    itemBuilder: (context, index) {
                      final contact = provider.contacts[index];
                      final name = Helpers.sanitizeString((contact['full_name'] ?? contact['first_name'] ?? 'No Name').toString());
                      final phone = (contact['wa_id'] ?? contact['phone_number'] ?? '').toString();
                      final uid = (contact['_uid'] ?? contact['uid'] ?? contact['id']).toString();
                      
                      final isSelected = _selectedContacts.any((c) => (c['_uid'] ?? c['uid'] ?? c['id']).toString() == uid);

                      return ListTile(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedContacts.removeWhere((c) => (c['_uid'] ?? c['uid'] ?? c['id']).toString() == uid);
                            } else {
                              _selectedContacts.add(contact);
                            }
                          });
                        },
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFF2F4F7),
                          child: Text(
                            Helpers.getInitial(name),
                            style: const TextStyle(color: Color(0xFF667085)),
                          ),
                        ),
                        title: Text(
                          name,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF151C27),
                          ),
                        ),
                        subtitle: Text(
                          phone,
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
                                if (!isSelected) _selectedContacts.add(contact);
                              } else {
                                _selectedContacts.removeWhere((c) => (c['_uid'] ?? c['uid'] ?? c['id']).toString() == uid);
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
              if (provider.hasMore && provider.isLoading)
                Padding(
                  padding: EdgeInsets.all(8.w),
                  child: const CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF007176)),
                ),
            ],
          ),
        );
      },
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
              controller: _searchController,
              onChanged: (val) {
                _searchTimer?.cancel();
                _searchTimer = Timer(const Duration(milliseconds: 500), () {
                  _fetchContacts(refresh: true);
                });
              },
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
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.close, size: 20.sp, color: const Color(0xFF667085)),
              onPressed: () {
                _searchController.clear();
                _fetchContacts(refresh: true);
              },
            ),
        ],
      ),
    );
  }
}
