import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../features/contacts/presentation/providers/contact_group_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/helpers.dart';

class GroupDetailsScreen extends StatefulWidget {
  final String groupUid;
  final dynamic initialGroup;

  const GroupDetailsScreen({super.key, required this.groupUid, this.initialGroup});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  late dynamic _group;
  List<dynamic> _members = [];
  bool _isLoadingMembers = false;

  @override
  void initState() {
    super.initState();
    _group = widget.initialGroup;
    _initializeMembers();
  }

  void _initializeMembers() {
    if (_group != null && _group['contacts'] is List) {
      _members = List.from(_group['contacts']);
    } else if (_group != null && _group['members'] is List) {
      _members = List.from(_group['members']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = Helpers.sanitizeString((_group?['title'] ?? _group?['name'] ?? 'Group Details').toString());
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF151C27)),
        title: Text(
          title,
          style: TextStyle(
            color: const Color(0xFF151C27),
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: _addMembers,
            tooltip: 'Add Members',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _members.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    itemCount: _members.length,
                    itemBuilder: (context, index) {
                      final member = _members[index];
                      return _buildMemberCard(member);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final description = Helpers.sanitizeString((_group?['description'] ?? '').toString());
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (description.isNotEmpty) ...[
            Text(
              'Description',
              style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 4.h),
            Text(
              description,
              style: TextStyle(fontSize: 14.sp, color: AppColors.textPrimary),
            ),
            SizedBox(height: 16.h),
          ],
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_outline, size: 16.sp, color: AppColors.primary),
                    SizedBox(width: 6.w),
                    Text(
                      '${_members.length} Members',
                      style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(dynamic member) {
    final name = Helpers.sanitizeString((member['full_name'] ?? member['first_name'] ?? 'No Name').toString());
    final phone = Helpers.sanitizeString((member['wa_id'] ?? member['phone_number'] ?? '').toString());
    final uid = (member['uid'] ?? member['id']).toString();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        leading: CircleAvatar(
          radius: 20.r,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(
            Helpers.getInitial(name), 
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14.sp)
          ),
        ),
        title: Text(name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.sp, color: AppColors.textPrimary)),
        subtitle: Text(phone, style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary)),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
          onPressed: () => _confirmRemoveMember(member),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_off_outlined, size: 64.sp, color: Colors.grey[300]),
          SizedBox(height: 16.h),
          Text('No members in this group', style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp)),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: _addMembers,
            icon: const Icon(Icons.person_add_outlined),
            label: const Text('Add Members'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
          ),
        ],
      ),
    );
  }

  void _addMembers() async {
    final dynamic result = await context.push('/select-contacts');
    
    // Result could be a List or a single contact depending on SelectContactsScreen implementation
    if (result != null) {
      List<dynamic> selected;
      if (result is List) {
        selected = result;
      } else {
        selected = [result];
      }

      if (selected.isEmpty) return;

      final List<String> contactUids = selected.map((c) => (c['uid'] ?? c['id']).toString()).toList();
      
      final provider = context.read<ContactGroupProvider>();
      final success = await provider.assignContactsToGroup(contactUids, [widget.groupUid]);
      
      if (success && mounted) {
        Helpers.showSnackBar(context, 'Successfully added ${selected.length} members');
        setState(() {
          for (var s in selected) {
            final uid = (s['uid'] ?? s['id']).toString();
            if (!_members.any((m) => (m['uid'] ?? m['id']).toString() == uid)) {
              _members.add(s);
            }
          }
        });
      } else if (provider.errorMessage != null && mounted) {
        Helpers.showSnackBar(context, provider.errorMessage!);
      }
    }
  }

  void _confirmRemoveMember(dynamic member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Are you sure you want to remove ${member['full_name'] ?? 'this contact'} from the group?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final contactUid = (member['uid'] ?? member['id']).toString();
              final success = await context.read<ContactGroupProvider>().removeContactFromGroup(contactUid, widget.groupUid);
              if (success && mounted) {
                setState(() {
                  _members.removeWhere((m) => (m['uid'] ?? m['id']).toString() == contactUid);
                });
                Helpers.showSnackBar(context, 'Member removed from group');
              }
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
