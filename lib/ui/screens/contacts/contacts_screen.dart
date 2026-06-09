import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../features/contacts/presentation/providers/contact_provider.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchContacts();
    });
  }

  void _fetchContacts() {
    context.read<ContactProvider>().getContacts(perPage: 100);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/add-contact');
          _fetchContacts();
        },
        backgroundColor: const Color(0xFF007176),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabs(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildContactsList(),
                  const Center(child: Text('Archive Empty')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Contacts',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontFamily: 'Inter',
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F7),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(Icons.download_outlined, size: 16.sp, color: const Color(0xFFD0D5DD)),
                SizedBox(width: 8.w),
                Text(
                  'Download CSV',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFD0D5DD),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE8E8EC), width: 1)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: Colors.black,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: Colors.black,
        unselectedLabelColor: const Color(0xFF98A2B3),
        labelStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        dividerColor: Colors.transparent,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        tabs: const [
          Tab(text: 'Active'),
          Tab(text: 'Archive'),
        ],
      ),
    );
  }

  Widget _buildContactsList() {
    return Consumer<ContactProvider>(
      builder: (context, provider, child) {
        debugPrint("🔄 UI Rebuilding with ${provider.contacts.length} contacts");
        if (provider.isLoading && provider.contacts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () async => _fetchContacts(),
          child: ListView(
            padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 20.h),
            children: [
              _buildSearchBar(),
              SizedBox(height: 16.h),
              if (provider.errorMessage != null && provider.contacts.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.h),
                    child: Column(
                      children: [
                        Text('Error: ${provider.errorMessage}'),
                        SizedBox(height: 16.h),
                        ElevatedButton(
                          onPressed: _fetchContacts,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (provider.contacts.isEmpty)
                _buildEmptyState()
              else
                ...provider.contacts.map((contact) => _buildContactItem(contact)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContactItem(dynamic contact) {
    final firstName = contact['first_name'] ?? contact['fname'] ?? '';
    final lastName = contact['last_name'] ?? contact['lname'] ?? '';
    final fullName = contact['full_name'] ?? contact['name'] ?? '';
    final name = fullName.isNotEmpty ? fullName : '$firstName $lastName'.trim();
    final phone = contact['wa_id'] ??
                 contact['phone_number'] ??
                 contact['mobile_number'] ?? 
                 contact['phone'] ?? 
                 contact['mobile'] ?? '';
    final uid = contact['_uid'] ?? contact['uid'] ?? contact['id']?.toString() ?? '';

    return GestureDetector(
      onTap: () => context.push('/chat-detail/$uid/$name'),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFFF2F4F7)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFF2F4F7),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isNotEmpty ? name : 'No Name',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    phone,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF667085),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: const Color(0xFFD0D5DD), size: 20.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      width: 358.w,
      height: 50.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: const Color(0xFFF2F4F7)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Icon(Icons.search, color: const Color(0xFF98A2B3), size: 20.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search contacts',
                hintStyle: TextStyle(
                  color: const Color(0xFF98A2B3),
                  fontSize: 14.sp,
                  fontFamily: 'Inter',
                ),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: 358.w,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28.w,
                height: 28.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFE4E4E4),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(Iconsax.user_remove, color: const Color(0xFF667085), size: 14.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No Contacts Found',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF151515),
                        fontFamily: 'Inter',
                        height: 1.3,
                        letterSpacing: -0.08.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'You don\'t have any contacts yet. Start by creating a new contact or uploading an existing list to get started.',
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        color: const Color(0xFF151C27),
                        fontFamily: 'Geist',
                        height: 1.3,
                        letterSpacing: -0.08.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () async {
              await context.push('/add-contact');
              _fetchContacts();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
              fixedSize: Size(334.w, 48.h),
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18.r),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, size: 18.sp),
                SizedBox(width: 8.w),
                Text(
                  'Add First Contact',
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              const Expanded(child: Divider(color: Color(0xFFD0D5DD), thickness: 0.5)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text(
                  'OR',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF98A2B3),
                  ),
                ),
              ),
              const Expanded(child: Divider(color: Color(0xFFD0D5DD), thickness: 0.5)),
            ],
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () async {
              await context.push('/upload-csv');
              _fetchContacts();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
              fixedSize: Size(334.w, 48.h),
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18.r),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.upload_outlined, size: 18.sp),
                SizedBox(width: 8.w),
                Text(
                  'Upload CSV',
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
