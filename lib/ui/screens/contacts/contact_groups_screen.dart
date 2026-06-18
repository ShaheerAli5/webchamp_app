import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../features/contacts/presentation/providers/contact_group_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/helpers.dart';

class ContactGroupsScreen extends StatefulWidget {
  const ContactGroupsScreen({super.key});

  @override
  State<ContactGroupsScreen> createState() => _ContactGroupsScreenState();
}

class _ContactGroupsScreenState extends State<ContactGroupsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ContactGroupProvider>().fetchGroups();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Contact Groups',
          style: TextStyle(
            color: const Color(0xFF151C27),
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF151C27)),
      ),
      body: Consumer<ContactGroupProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.groups.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && provider.groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.errorMessage!),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () => provider.fetchGroups(refresh: true),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.groups.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => provider.fetchGroups(refresh: true),
              child: Stack(
                children: [
                  ListView(),
                  const Center(child: Text('No groups found')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchGroups(refresh: true),
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              itemCount: provider.groups.length,
              itemBuilder: (context, index) {
                final group = provider.groups[index];
                return _buildGroupCard(group);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateEditGroupModal(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildGroupCard(dynamic group) {
    final title = Helpers.sanitizeString((group['title'] ?? group['name'] ?? 'No Name').toString());
    final description = Helpers.sanitizeString((group['description'] ?? '').toString());
    final count = group['contacts_count'] ?? group['member_count'] ?? 0;
    final uid = (group['uid'] ?? group['id']).toString();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        leading: Container(
          width: 48.w,
          height: 48.w,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.group_outlined, color: AppColors.primary, size: 24.sp),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp, color: AppColors.textPrimary),
        ),
        subtitle: Text(
          description.isNotEmpty ? description : '$count members',
          style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Color(0xFFD0D5DD)),
          onSelected: (val) {
            if (val == 'edit') {
              _showCreateEditGroupModal(context, group: group);
            } else if (val == 'delete') {
              _confirmDelete(context, uid);
            }
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: () {
          context.push('/group-details/$uid', extra: group);
        },
      ),
    );
  }

  void _showCreateEditGroupModal(BuildContext context, {dynamic group}) {
    final isEditing = group != null;
    final titleController = TextEditingController(text: isEditing ? (group['title'] ?? group['name']) : '');
    final descController = TextEditingController(text: isEditing ? group['description'] : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24.h,
          left: 20.w,
          right: 20.w,
          top: 20.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              isEditing ? 'Edit Group' : 'Create New Group',
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            SizedBox(height: 24.h),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                prefixIcon: const Icon(Icons.title),
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                prefixIcon: const Icon(Icons.description_outlined),
              ),
              maxLines: 2,
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton(
                onPressed: () async {
                  if (titleController.text.trim().isEmpty) {
                    Helpers.showSnackBar(context, 'Please enter a group name');
                    return;
                  }

                  final provider = context.read<ContactGroupProvider>();
                  bool success;
                  if (isEditing) {
                    success = await provider.updateGroup(
                      (group['uid'] ?? group['id']).toString(),
                      titleController.text.trim(),
                      description: descController.text.trim(),
                    );
                  } else {
                    success = await provider.createGroup(
                      titleController.text.trim(),
                      description: descController.text.trim(),
                    );
                  }

                  if (success && mounted) {
                    Navigator.pop(ctx);
                    Helpers.showSnackBar(context, 'Group ${isEditing ? 'updated' : 'created'} successfully');
                  } else if (provider.errorMessage != null && mounted) {
                    Helpers.showSnackBar(context, provider.errorMessage!);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: Text(isEditing ? 'Update Group' : 'Create Group', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String uid) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Group'),
        content: const Text('Are you sure you want to delete this group? This action cannot be undone.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final success = await context.read<ContactGroupProvider>().deleteGroup(uid);
              if (success && mounted) {
                Navigator.pop(ctx);
                Helpers.showSnackBar(context, 'Group deleted successfully');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
