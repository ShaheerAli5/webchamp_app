import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/contacts/data/models/label_model.dart';
import '../../../../features/contacts/presentation/providers/contact_provider.dart';

class AssignLabelsDialog extends StatefulWidget {
  final String contactUid;
  final List<LabelModel> initialLabels;

  const AssignLabelsDialog({
    super.key,
    required this.contactUid,
    required this.initialLabels,
  });

  @override
  State<AssignLabelsDialog> createState() => _AssignLabelsDialogState();
}

class _AssignLabelsDialogState extends State<AssignLabelsDialog> {
  late List<String> _selectedLabelUids;

  @override
  void initState() {
    super.initState();
    _selectedLabelUids = widget.initialLabels.map((l) => l.uid).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Text(
        'Assign Labels',
        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
      ),
      content: Consumer<ContactProvider>(
        builder: (context, provider, child) {
          if (provider.allAvailableLabels.isEmpty) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No labels available. Please create some first in Label Management.'),
                SizedBox(height: 20.h),
              ],
            );
          }

          return SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: provider.allAvailableLabels.length,
              itemBuilder: (context, index) {
                final label = provider.allAvailableLabels[index];
                final isSelected = _selectedLabelUids.contains(label.uid);

                return CheckboxListTile(
                  value: isSelected,
                  activeColor: AppColors.primary,
                  title: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: _parseColor(label.bgColor),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          label.title,
                          style: TextStyle(
                            color: _parseColor(label.textColor),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedLabelUids.add(label.uid);
                      } else {
                        _selectedLabelUids.remove(label.uid);
                      }
                    });
                  },
                );
              },
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          ),
          child: const Text('Apply', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  void _submit() async {
    final provider = context.read<ContactProvider>();
    final success = await provider.assignLabels(
      contactUid: widget.contactUid,
      labels: _selectedLabelUids,
    );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage ?? 'Failed to assign labels')),
        );
      }
    }
  }
}
