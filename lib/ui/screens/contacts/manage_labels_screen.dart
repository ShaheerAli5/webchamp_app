import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/contacts/presentation/providers/contact_provider.dart';
import '../../../../features/contacts/data/models/label_model.dart';
import '../../widgets/contacts/add_edit_label_dialog.dart';

class ManageLabelsScreen extends StatelessWidget {
  const ManageLabelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Manage Labels',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF151C27)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: () => _showAddLabelDialog(context),
          ),
        ],
      ),
      body: Consumer<ContactProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.allAvailableLabels.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (provider.allAvailableLabels.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.tag, size: 64.sp, color: Colors.grey[300]),
                  SizedBox(height: 16.h),
                  Text('No labels found', style: TextStyle(color: AppColors.textSecondary, fontSize: 16.sp)),
                  SizedBox(height: 8.h),
                  ElevatedButton(
                    onPressed: () => _showAddLabelDialog(context),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Text('Create First Label', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: provider.allAvailableLabels.length,
            itemBuilder: (context, index) {
              final label = provider.allAvailableLabels[index];
              return _LabelItem(label: label);
            },
          );
        },
      ),
    );
  }

  void _showAddLabelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddEditLabelDialog(),
    );
  }
}

class _LabelItem extends StatelessWidget {
  final LabelModel label;

  const _LabelItem({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: _parseColor(label.bgColor),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              label.title,
              style: TextStyle(
                color: _parseColor(label.textColor),
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Iconsax.edit, size: 20, color: Colors.blue),
            onPressed: () => _showEditDialog(context),
          ),
          IconButton(
            icon: const Icon(Iconsax.trash, size: 20, color: Colors.red),
            onPressed: () => _showDeleteConfirm(context),
          ),
        ],
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

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddEditLabelDialog(label: label),
    );
  }

  void _showDeleteConfirm(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DeleteLabelDialog(label: label),
    );
  }
}

class _DeleteLabelDialog extends StatefulWidget {
  final LabelModel label;
  const _DeleteLabelDialog({required this.label});

  @override
  State<_DeleteLabelDialog> createState() => _DeleteLabelDialogState();
}

class _DeleteLabelDialogState extends State<_DeleteLabelDialog> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Label'),
      content: Text('Are you sure you want to delete the label "${widget.label.title}"?'),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.of(context, rootNavigator: true).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _isDeleting ? null : _handleDelete,
          child: _isDeleting
              ? SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                )
              : const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  void _handleDelete() async {
    setState(() => _isDeleting = true);
    final provider = context.read<ContactProvider>();
    final success = await provider.deleteLabel(widget.label.uid);
    
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Label deleted'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage ?? 'Delete failed'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
