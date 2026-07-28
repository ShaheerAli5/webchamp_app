import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/helpers.dart';
import '../../../features/contacts/presentation/providers/contact_provider.dart';
import '../../../features/contacts/data/models/label_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/contacts/assign_labels_dialog.dart';

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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<ContactProvider>().getContacts(
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
                    const _ActionButtons(),
                    SizedBox(height: 16.h),
                    const _LabelFilterBar(),
                    SizedBox(height: 16.h),
                    Selector<ContactProvider, int>(
                      selector: (_, p) => p.total > 0 ? p.total : p.contacts.length,
                      builder: (context, total, _) => _CounterCard(count: total),
                    ),
                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ),
            Consumer<ContactProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.contacts.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  );
                }
                
                if (provider.errorMessage != null && provider.contacts.isEmpty) {
                  return SliverFillRemaining(
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
                  );
                }

                if (provider.contacts.isEmpty && _searchController.text.isEmpty) {
                  return SliverFillRemaining(child: _buildEmptyState());
                }

                if (provider.contacts.isEmpty && _searchController.text.isNotEmpty) {
                  return SliverFillRemaining(child: _buildNoResultsState());
                }

                final contacts = provider.filteredContacts;
                if (contacts.isEmpty && provider.selectedLabel != null) {
                   return SliverFillRemaining(
                     child: Center(
                       child: Text('No contacts with label "${provider.selectedLabel}"'),
                     ),
                   );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return ContactCard(
                        contact: contacts[index],
                        onTap: (action, contact) => _handleContactAction(action, contact),
                      );
                    },
                    childCount: contacts.length,
                    addAutomaticKeepAlives: true,
                    addRepaintBoundaries: true,
                  ),
                );
              },
            ),
            Selector<ContactProvider, bool>(
              selector: (_, p) => p.hasMore,
              builder: (context, hasMore, _) {
                if (hasMore) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.h),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  );
                }
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              },
            ),
            SliverToBoxAdapter(child: SizedBox(height: 80.h)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'contacts_fab',
        onPressed: () => context.push('/add-contact').then((_) => _fetchContacts()),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
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
          icon: const Icon(Iconsax.tag, color: Color(0xFF151C27)),
          onPressed: () => context.push('/manage-labels'),
          tooltip: 'Manage Labels',
        ),
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
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, value, _) {
                return value.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          _fetchContacts();
                        },
                      )
                    : const SizedBox.shrink();
              },
            ),
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

  void _handleContactAction(String action, dynamic contact) {
    final uid = (contact['_uid'] ?? contact['uid'] ?? contact['id'])?.toString() ?? '';
    final name = (contact['full_name'] ?? contact['first_name'] ?? 'Contact').toString();
    
    if (action == 'view') {
      if (uid.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Unable to open chat: Missing contact ID"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final encodedUid = Uri.encodeComponent(uid);
      final encodedName = Uri.encodeComponent(name);
      context.push('/chat-detail/$encodedUid/$encodedName');
    } else if (action == 'edit') {
      context.push('/edit-contact', extra: contact).then((_) => _fetchContacts());
    } else if (action == 'labels') {
      final List<dynamic> rawLabels = contact['labels'] ?? [];
      final initialLabels = rawLabels.map((e) => LabelModel.fromJson(e)).toList();
      
      showDialog(
        context: context,
        builder: (context) => AssignLabelsDialog(
          contactUid: uid,
          initialLabels: initialLabels,
        ),
      );
    }
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 64.sp, color: Colors.grey[300]),
            SizedBox(height: 16.h),
            Text(
              'No results found for "${_searchController.text}"',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
            ),
            SizedBox(height: 8.h),
            Text(
              'Try a different name or phone number.',
              style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 12.sp),
            ),
          ],
        ),
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

class _ActionButtons extends StatelessWidget {
  const _ActionButtons();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ActionButton(
              onTap: () => context.push('/add-contact').then((_) => context.read<ContactProvider>().getContacts()),
              icon: Icons.add,
              label: 'Create Contact',
              isPrimary: true,
            ),
            SizedBox(width: 8.w),
            _ActionButton(
              onTap: () => context.push('/upload-csv').then((_) => context.read<ContactProvider>().getContacts()),
              icon: Icons.upload_outlined,
              label: 'Upload Contacts',
              isPrimary: false,
            ),
            SizedBox(width: 8.w),
            _ActionButton(
              onTap: () => context.push('/contact-groups'),
              icon: Icons.group_outlined,
              label: 'Groups',
              isPrimary: false,
            ),
            SizedBox(width: 8.w),
            _ActionButton(
              onTap: () => context.push('/manage-labels'),
              icon: Iconsax.tag,
              label: 'Labels',
              isPrimary: false,
            ),
            SizedBox(width: 8.w),
            _ActionButton(
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
}

class _LabelFilterBar extends StatelessWidget {
  const _LabelFilterBar();

  @override
  Widget build(BuildContext context) {
    return Consumer<ContactProvider>(
      builder: (context, provider, child) {
        if (provider.allAvailableLabels.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 36.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: provider.allAvailableLabels.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                final isSelected = provider.selectedLabel == null || provider.selectedLabel == 'all';
                return Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: FilterChip(
                    label: const Text('All'),
                    selected: isSelected,
                    onSelected: (_) => provider.setSelectedLabel(null),
                    backgroundColor: Colors.white,
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      fontSize: 12.sp,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.r),
                      side: BorderSide(color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.3)),
                    ),
                  ),
                );
              }

              final label = provider.allAvailableLabels[index - 1];
              final isSelected = provider.selectedLabel?.toLowerCase() == label.title.toLowerCase();

              return Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: FilterChip(
                  label: Text(label.title),
                  selected: isSelected,
                  onSelected: (_) => provider.setSelectedLabel(isSelected ? null : label.title),
                  backgroundColor: Colors.white,
                  selectedColor: _parseColor(label.bgColor).withOpacity(0.2),
                  checkmarkColor: _parseColor(label.bgColor),
                  labelStyle: TextStyle(
                    color: isSelected ? _parseColor(label.bgColor) : AppColors.textSecondary,
                    fontSize: 12.sp,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.r),
                    side: BorderSide(
                      color: isSelected ? _parseColor(label.bgColor) : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final bool isPrimary;

  const _ActionButton({
    required this.onTap,
    required this.icon,
    required this.label,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
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
}

class _CounterCard extends StatelessWidget {
  final int count;
  const _CounterCard({required this.count});

  @override
  Widget build(BuildContext context) {
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
}

class ContactCard extends StatelessWidget {
  final dynamic contact;
  final Function(String, dynamic) onTap;

  const ContactCard({super.key, required this.contact, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final firstName = Helpers.sanitizeString((contact['first_name'] ?? contact['fname'] ?? '').toString());
    final lastName = Helpers.sanitizeString((contact['last_name'] ?? contact['lname'] ?? '').toString());
    final fullName = Helpers.sanitizeString((contact['full_name'] ?? contact['name'] ?? '').toString());
    final name = fullName.isNotEmpty ? fullName : '$firstName $lastName'.trim();
    final phone = Helpers.sanitizeString((contact['wa_id'] ?? contact['phone_number'] ?? contact['mobile_number'] ?? '').toString());
    final country = Helpers.sanitizeString((contact['country'] ?? '').toString());
    final optOut = contact['whatsapp_opt_out'] == true || contact['opt_out'] == 1 || contact['opt_out'] == true;
    
    final unreadCount = Helpers.toInt(contact['unread_messages_count'] ?? contact['unread_count']);
    final latestPreview = Helpers.getMessagePreview(contact is Map ? Map<String, dynamic>.from(contact) : {});
    final latestTime = contact['latest_message'] ?? (contact['last_message'] is Map ? contact['last_message']['created_at'] : null) ?? contact['updated_at'] ?? contact['messaged_at'];

    return RepaintBoundary(
      child: InkWell(
        onTap: () => onTap('view', contact),
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
                      Helpers.getInitial(name),
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
                                Helpers.formatShortTimestamp(latestTime),
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
                    onSelected: (val) => onTap(val, contact),
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'view', child: Text('View')),
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'labels', child: Text('Labels')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
              _buildLabels(contact['labels']),
              if (latestPreview.isNotEmpty) ...[
                SizedBox(height: 8.h),
                Padding(
                  padding: EdgeInsets.only(left: 60.w),
                  child: Text(
                    latestPreview,
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
                    _StatusBadge(isOptedOut: optOut),
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
      ),
    );
  }

  Widget _buildLabels(dynamic labels) {
    if (labels == null || labels is! List || labels.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(left: 60.w, top: 4.h),
      child: Wrap(
        spacing: 4.w,
        runSpacing: 4.h,
        children: labels.map((l) {
          final label = LabelModel.fromJson(l is Map ? Map<String, dynamic>.from(l) : {});
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: _parseColor(label.bgColor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: _parseColor(label.bgColor).withOpacity(0.2)),
            ),
            child: Text(
              label.title,
              style: TextStyle(
                color: _parseColor(label.bgColor),
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isOptedOut;
  const _StatusBadge({required this.isOptedOut});

  @override
  Widget build(BuildContext context) {
    final color = isOptedOut ? Colors.red : AppColors.primary;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12.r)),
      child: Text(isOptedOut ? 'Opted Out' : 'Opted In', style: TextStyle(color: color, fontSize: 10.sp, fontWeight: FontWeight.w600)),
    );
  }
}
