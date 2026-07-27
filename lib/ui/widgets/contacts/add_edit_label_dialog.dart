import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/contacts/data/models/label_model.dart';
import '../../../../features/contacts/presentation/providers/contact_provider.dart';

class AddEditLabelDialog extends StatefulWidget {
  final LabelModel? label;

  const AddEditLabelDialog({super.key, this.label});

  @override
  State<AddEditLabelDialog> createState() => _AddEditLabelDialogState();
}

class _AddEditLabelDialogState extends State<AddEditLabelDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late String _textColor;
  late String _bgColor;

  final List<String> _commonColors = [
    '#F44336', '#E91E63', '#9C27B0', '#673AB7', '#3F51B5', 
    '#2196F3', '#03A9F4', '#00BCD4', '#009688', '#4CAF50', 
    '#8BC34A', '#CDDC39', '#FFEB3B', '#FFC107', '#FF9800', 
    '#FF5722', '#795548', '#9E9E9E', '#607D8B', '#000000',
    '#FFFFFF'
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.label?.title ?? '');
    _textColor = widget.label?.textColor ?? '#FFFFFF';
    _bgColor = widget.label?.bgColor ?? '#136166';
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Text(
        widget.label == null ? 'Add Label' : 'Edit Label',
        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Label Title',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a title' : null,
              ),
              SizedBox(height: 20.h),
              Text('Background Color', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp)),
              SizedBox(height: 10.h),
              _buildColorPicker(isBackground: true),
              SizedBox(height: 20.h),
              Text('Text Color', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp)),
              SizedBox(height: 10.h),
              _buildColorPicker(isBackground: false),
              SizedBox(height: 20.h),
              Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: _parseColor(_bgColor),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    _titleController.text.isEmpty ? 'Preview' : _titleController.text,
                    style: TextStyle(color: _parseColor(_textColor), fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
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
          child: const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildColorPicker({required bool isBackground}) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: _commonColors.map((colorHex) {
        final isSelected = isBackground ? _bgColor == colorHex : _textColor == colorHex;
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isBackground) {
                _bgColor = colorHex;
              } else {
                _textColor = colorHex;
              }
            });
          },
          child: Container(
            width: 30.w,
            height: 30.w,
            decoration: BoxDecoration(
              color: _parseColor(colorHex),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.black : Colors.grey.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: isSelected
                ? Icon(Icons.check, size: 16.sp, color: _getContrastColor(colorHex))
                : null,
          ),
        );
      }).toList(),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  Color _getContrastColor(String hex) {
    final color = _parseColor(hex);
    return ThemeData.estimateBrightnessForColor(color) == Brightness.light
        ? Colors.black
        : Colors.white;
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ContactProvider>();
    bool success;

    if (widget.label == null) {
      success = await provider.createLabel(
        title: _titleController.text,
        textColor: _textColor,
        bgColor: _bgColor,
      );
    } else {
      success = await provider.updateLabel(
        labelUid: widget.label!.uid,
        title: _titleController.text,
        textColor: _textColor,
        bgColor: _bgColor,
      );
    }

    if (mounted) {
      if (success) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage ?? 'Operation failed')),
        );
      }
    }
  }
}
