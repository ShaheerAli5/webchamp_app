import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/helpers.dart';
import '../../../features/contacts/presentation/providers/contact_provider.dart';
import '../../../core/theme/app_colors.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchContacts();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      final provider = context.read<ContactProvider>();
      if (!provider.isLoading && provider.hasMore) {
        provider.getContacts(
          search: _searchController.text.isNotEmpty ? _searchController.text : null,
          loadMore: true,
        );
      }
    }
  }

  void _fetchContacts() {
    final provider = context.read<ContactProvider>();
    if (provider.isLoading) return;

    provider.getContacts(
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ContactProvider>(
      builder: (context, provider, child) {
        debugPrint('ContactsScreen Build: isLoading=${provider.isLoading}, contacts=${provider.contacts.length}, total=${provider.total}');
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(),
          body: RefreshIndicator(
            onRefresh: () async {
              await provider.getContacts(
                search: _searchController.text.isNotEmpty ? _searchController.text : null,
              );
            },
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.h),
                    child: Column(
                      children: [
                        _buildSearchBar(),
                        SizedBox(height: 16.h),
                        _buildActionButtons(),
                        SizedBox(height: 16.h),
                        _buildCounterCard(provider.total > 0 ? provider.total : provider.contacts.length),
                        SizedBox(height: 16.h),
                      ],
                    ),
                  ),
                ),
                if (provider.isLoading && provider.contacts.isEmpty)
                  SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  )
                else if (provider.errorMessage != null && provider.contacts.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
                          SizedBox(height: 16.h),
                          Text(provider.errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
                          SizedBox(height: 16.h),
                          ElevatedButton(onPressed: _fetchContacts, child: const Text('Retry')),
                        ],
                      ),
                    ),
                  )
                else if (provider.contacts.isEmpty && _searchController.text.isEmpty)
                  SliverFillRemaining(child: _buildEmptyState())
                else if (provider.contacts.isEmpty && _searchController.text.isNotEmpty)
                  SliverFillRemaining(child: _buildNoResultsState())
                else ...[
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _buildContactCard(provider.contacts[index]);
                      },
                      childCount: provider.contacts.length,
                    ),
                  ),
                  if (provider.hasMore)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.h),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  SliverToBoxAdapter(child: SizedBox(height: 80.h)),
                ],
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.push('/add-contact').then((_) => _fetchContacts()),
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Iconsax.menu, color: Color(0xFF151C27)),
        onPressed: () {},
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
          onPressed: () {},
        ),
      ],
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
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search contacts...',
            hintStyle: TextStyle(color: const Color(0xFF98A2B3), fontSize: 14.sp),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF98A2B3)),
            suffixIcon: _searchController.text.isNotEmpty 
              ? IconButton(icon: const Icon(Icons.close), onPressed: () {
                  _searchController.clear();
                  _fetchContacts();
                }) 
              : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 14.h),
            filled: false,
          ),
          onChanged: (val) {
            _searchTimer?.cancel();
            _searchTimer = Timer(const Duration(milliseconds: 500), () {
              _fetchContacts();
            });
          },
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
              onTap: () {},
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
            Icon(icon, size: 18.sp, color: isPrimary ? Colors.white : AppColors.primary),
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
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
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
                style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
              Text(
                count.toString(),
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(dynamic contact) {
    final firstName = Helpers.sanitizeString((contact['first_name'] ?? contact['fname'] ?? '').toString());
    final lastName = Helpers.sanitizeString((contact['last_name'] ?? contact['lname'] ?? '').toString());
    final fullName = Helpers.sanitizeString((contact['full_name'] ?? contact['name'] ?? '').toString());
    final name = fullName.isNotEmpty ? fullName : '$firstName $lastName'.trim();
    final phone = Helpers.sanitizeString((contact['wa_id'] ?? contact['phone_number'] ?? contact['mobile_number'] ?? '').toString());
    final email = Helpers.sanitizeString((contact['email'] ?? '').toString());
    final country = Helpers.sanitizeString((contact['country'] ?? '').toString());
    final optOut = contact['whatsapp_opt_out'] == true || contact['opt_out'] == 1 || contact['opt_out'] == true;
    
    // Extract unread count and latest message
    final unreadCount = Helpers.toInt(contact['unread_messages_count'] ?? contact['unread_count']);
    final latestMessage = contact['latest_message_text'] ?? contact['message'] ?? contact['last_message'];
    final latestTime = contact['formatted_message_time'] ?? contact['messaged_at'];

    return InkWell(
      onTap: () => _handleContactAction('view', contact),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
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
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18.sp),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name.isNotEmpty ? name : 'No Name',
                              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (latestTime != null)
                            Text(
                              latestTime.toString().split(' ').last,
                              style: TextStyle(fontSize: 10.sp, color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                      if (phone.isNotEmpty) ...[
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Icon(Icons.phone_outlined, size: 14.sp, color: AppColors.textSecondary),
                            SizedBox(width: 8.w),
                            Text(phone, style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (unreadCount != null && unreadCount > 0)
                  Container(
                    margin: EdgeInsets.only(left: 8.w),
                    padding: EdgeInsets.all(6.w),
                    decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                    child: Text(unreadCount.toString(), style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold)),
                  ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Color(0xFFD0D5DD)),
                  onSelected: (val) => _handleContactAction(val, contact),
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'view', child: Text('View')),
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            if (latestMessage != null) ...[
              SizedBox(height: 8.h),
              Padding(
                padding: EdgeInsets.only(left: 60.w),
                child: Text(
                  latestMessage.toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                ),
              ),
            ],
            Padding(
              padding: EdgeInsets.only(left: 60.w, top: 8.h),
              child: Row(
                children: [
                  _buildStatusBadge(optOut),
                  if (country.isNotEmpty) ...[
                    SizedBox(width: 8.w),
                    Icon(Icons.public_outlined, size: 12.sp, color: AppColors.textSecondary),
                    SizedBox(width: 4.w),
                    Text(country, style: TextStyle(fontSize: 10.sp, color: AppColors.textSecondary)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14.sp, color: AppColors.textSecondary),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(bool isOptedOut) {
    final color = isOptedOut ? Colors.red : AppColors.primary;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12.r)),
      child: Text(isOptedOut ? 'Opted Out' : 'Opted In', style: TextStyle(color: color, fontSize: 10.sp, fontWeight: FontWeight.w600)),
    );
  }

  void _handleContactAction(String action, dynamic contact) {
    final uid = (contact['_uid'] ?? contact['uid'] ?? contact['id']).toString();
    final name = (contact['full_name'] ?? contact['first_name'] ?? 'Contact').toString();
    if (action == 'view') {
      final encodedUid = Uri.encodeComponent(uid);
      final encodedName = Uri.encodeComponent(name);
      context.push('/chat-detail/$encodedUid/$encodedName');
    } else if (action == 'edit') {
      context.push('/edit-contact', extra: contact).then((_) => _fetchContacts());
    }
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40.h),
        child: Text('No results for "${_searchController.text}"', style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40.h),
        child: Text('You have no contacts.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp)),
      ),
    );
  }
}
