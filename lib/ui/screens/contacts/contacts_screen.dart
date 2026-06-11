import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../features/contacts/presentation/providers/contact_provider.dart';
import '../../../core/theme/app_colors.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Only fetch if contacts are empty to avoid spamming the API on every mount
    // or use addPostFrameCallback if a refresh is explicitly needed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<ContactProvider>();
        if (provider.contacts.isEmpty) {
          _fetchContacts();
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _fetchContacts() {
    // Check if already loading to prevent redundant calls
    final provider = context.read<ContactProvider>();
    if (provider.isLoading) return;

    provider.getContacts(
      perPage: 100,
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Iconsax.menu, color: Color(0xFF151C27)),
          onPressed: () {
            // Scaffold.of(context).openDrawer(); 
          },
        ),
        title: Text(
          'Contacts',
          style: TextStyle(
            color: const Color(0xFF151C27),
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Color(0xFF151C27)),
            onPressed: () {
              // TODO: Implement filters
            },
          ),
        ],
      ),
      body: Consumer<ContactProvider>(
        builder: (context, provider, child) {
          final bool isInitialLoading = provider.isLoading && provider.contacts.isEmpty;
          final bool isListEmpty = provider.contacts.isEmpty && _searchController.text.isEmpty;
          final bool isNoSearchResults = provider.contacts.isEmpty && _searchController.text.isNotEmpty;

          if (isInitialLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && provider.contacts.isEmpty) {
             return Center(
               child: Padding(
                 padding: EdgeInsets.all(20.w),
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
                     SizedBox(height: 16.h),
                     Text(
                       provider.errorMessage!,
                       textAlign: TextAlign.center,
                       style: TextStyle(color: Colors.red, fontSize: 14.sp),
                     ),
                     SizedBox(height: 16.h),
                     ElevatedButton(
                       onPressed: _fetchContacts,
                       child: const Text('Retry'),
                     ),
                   ],
                 ),
               ),
             );
          }

          return RefreshIndicator(
            onRefresh: () async => _fetchContacts(),
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              children: [
                _buildSearchBar(),
                SizedBox(height: 16.h),
                _buildActionButtons(),
                SizedBox(height: 16.h),
                _buildCounterCard(provider.contacts.length),
                SizedBox(height: 16.h),
                if (isListEmpty)
                  _buildEmptyState()
                else if (isNoSearchResults)
                  _buildNoResultsState()
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.contacts.length,
                    itemBuilder: (context, index) {
                      return _buildContactCard(provider.contacts[index]);
                    },
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-contact').then((_) => _fetchContacts()),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        height: 52.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search contacts...',
            hintStyle: TextStyle(color: const Color(0xFF98A2B3), fontSize: 14.sp),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF98A2B3)),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 14.h),
            filled: false,
          ),
          onSubmitted: (_) => _fetchContacts(),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildActionButton(
              onTap: () => context.push('/add-contact').then((_) => _fetchContacts()),
              icon: Icons.add,
              label: 'Create Contact',
              isPrimary: true,
            ),
            SizedBox(width: 8.w),
            _buildActionButton(
              onTap: () => context.push('/upload-csv').then((_) => _fetchContacts()),
              icon: Icons.upload_outlined,
              label: 'Upload Contacts',
              isPrimary: false,
            ),
            SizedBox(width: 8.w),
            _buildActionButton(
              onTap: () {
                // TODO: Export contacts
              },
              icon: Icons.download_outlined,
              label: 'Export Contacts',
              isPrimary: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required bool isPrimary,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: isPrimary ? null : Border.all(color: AppColors.primary),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18.sp,
              color: isPrimary ? Colors.white : AppColors.primary,
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: isPrimary ? Colors.white : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterCard(int count) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.people_outline, color: AppColors.primary, size: 24.sp),
          ),
          SizedBox(width: 16.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Contacts',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(dynamic contact) {
    final firstName = contact['first_name'] ?? contact['fname'] ?? '';
    final lastName = contact['last_name'] ?? contact['lname'] ?? '';
    final fullName = contact['full_name'] ?? contact['name'] ?? '';
    final name = fullName.isNotEmpty ? fullName : '$firstName $lastName'.trim();
    final phone = (contact['wa_id'] ??
                 contact['phone_number'] ??
                 contact['mobile_number'] ?? 
                 contact['phone'] ?? 
                 contact['mobile'] ?? '').toString();
    final email = (contact['email'] ?? 'No email').toString();
    final country = (contact['country'] ?? 'Not specified').toString();
    final optOut = contact['whatsapp_opt_out'] == true || 
                   contact['opt_out'] == 1 || 
                   contact['opt_out'] == '1' ||
                   contact['opt_out'] == true;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24.r,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                  ),
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
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    _buildInfoRow(Icons.phone_outlined, phone),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Color(0xFFD0D5DD)),
                onSelected: (value) => _handleContactAction(value, contact),
                itemBuilder: (context) => [
                  _buildPopupItem('view', Icons.visibility_outlined, 'View Contact', AppColors.textPrimary),
                  _buildPopupItem('edit', Iconsax.edit_2, 'Edit Contact', AppColors.textPrimary),
                  _buildPopupItem('delete', Iconsax.trash, 'Delete Contact', Colors.red),
                ],
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(left: 60.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.email_outlined, email),
                SizedBox(height: 4.h),
                _buildInfoRow(Icons.public_outlined, country),
                SizedBox(height: 12.h),
                _buildStatusBadge(optOut),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14.sp, color: AppColors.textSecondary),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textSecondary,
              fontFamily: 'Inter',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(bool isOptedOut) {
    final color = isOptedOut ? Colors.red : AppColors.primary;
    final bgColor = isOptedOut ? Colors.red.withOpacity(0.1) : AppColors.primary.withOpacity(0.1);
    final text = isOptedOut ? 'Opted Out' : 'Opted In';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(String value, IconData icon, String label, Color color) {
    return PopupMenuItem(
      value: value,
      height: 36.h,
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: color),
          SizedBox(width: 12.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _handleContactAction(String action, dynamic contact) {
    final name = contact['full_name'] ?? contact['first_name'] ?? 'Contact';
    final uid = contact['_uid'] ?? contact['uid'] ?? contact['id'];

    switch (action) {
      case 'view':
        context.push('/chat-detail/$uid/$name');
        break;
      case 'edit':
        context.push('/edit-contact', extra: contact).then((_) => _fetchContacts());
        break;
      case 'delete':
        _showDeleteConfirmation(contact);
        break;
    }
  }

  void _showDeleteConfirmation(dynamic contact) {
    final name = contact['full_name'] ?? contact['first_name'] ?? 'this contact';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(
          'Delete Contact',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete $name?\nThis action cannot be undone.',
          style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final uid = contact['_uid'] ?? contact['uid'] ?? contact['id'];

              if (uid != null && uid.toString().isNotEmpty) {
                final contactProvider = context.read<ContactProvider>();
                final success = await contactProvider.deleteContact(uid.toString());
                
                if (!mounted) return;
                
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Contact deleted successfully')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        contactProvider.errorMessage ?? 'Failed to delete contact',
                      ),
                    ),
                  );
                }
              }
            },
            child: Text(
              'Delete',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40.h),
        child: Text(
          'No contacts found matching "${_searchController.text}"',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: 358.w,
      margin: EdgeInsets.symmetric(horizontal: 16.w),
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
