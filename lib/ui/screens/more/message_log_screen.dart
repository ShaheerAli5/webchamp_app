import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../routes/app_routes.dart';

class MessageLogScreen extends StatefulWidget {
  const MessageLogScreen({super.key});

  @override
  State<MessageLogScreen> createState() => _MessageLogScreenState();
}

class _MessageLogScreenState extends State<MessageLogScreen> {
  String _selectedType = 'All Messages';
  final TextEditingController _searchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF006B70),
              onPrimary: Colors.white,
              onSurface: Color(0xFF191C1E),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(56.h),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFEAECF0), width: 1),
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 20.w),
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
                  child: Icon(Icons.arrow_back, color: const Color(0xFF004D4F), size: 24.sp),
                ),
                SizedBox(width: 16.w),
                Text(
                  'Message Log',
                  style: TextStyle(
                    color: const Color(0xFF0A0A0A),
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildFilterSection(),
              _buildSearchSection(),
              _buildLogList(),
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      width: 354.w,
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, size: 16.sp, color: const Color(0xFF667085)),
              SizedBox(width: 8.w),
              Text(
                'FILTER RECORDS',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF667085),
                  letterSpacing: 0.5,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            'Select Message Type',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF0A0A0A),
              height: 20/14,
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              _buildTypeChip('All Messages'),
              SizedBox(width: 8.w),
              _buildTypeChip('Incoming'),
              SizedBox(width: 8.w),
              _buildTypeChip('Outgoing'),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildDatePicker(
                  'Start Date',
                  _startDate == null ? 'mm/dd/yyyy' : DateFormat('MM/dd/yyyy').format(_startDate!),
                  () => _selectDate(context, true),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildDatePicker(
                  'End Date',
                  _endDate == null ? 'mm/dd/yyyy' : DateFormat('MM/dd/yyyy').format(_endDate!),
                  () => _selectDate(context, false),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            height: 36.h,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006B70),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, color: Colors.white, size: 16.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'Show Results',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String label) {
    bool isSelected = _selectedType == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = label),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF006B70) : Colors.white,
          borderRadius: BorderRadius.circular(99.r),
          border: Border.all(
            color: isSelected ? const Color(0xFF006B70) : const Color(0xFFD0D5DD),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF475467),
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker(String label, String hint, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF191C1E),
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 36.h,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  hint,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: hint == 'mm/dd/yyyy' ? const Color(0xFF98A2B3) : const Color(0xFF191C1E),
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
                Icon(Icons.calendar_month_outlined, size: 16.sp, color: const Color(0xFF667085)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by recipient or status...',
          hintStyle: TextStyle(
            color: const Color(0xFF98A2B3),
            fontSize: 14.sp,
            fontFamily: 'Plus Jakarta Sans',
          ),
          prefixIcon: Icon(Icons.search, color: const Color(0xFF98A2B3), size: 20.sp),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 20.w),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.r),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.r),
            borderSide: const BorderSide(color: Color(0xFF006B70), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildLogList() {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(16.w),
      children: [
        _buildLogCard(
          recipient: '+1(555) 012-3456',
          status: 'Sent',
          statusColor: const Color(0xFF039855),
          from: 'Admin Portal',
          via: 'WhatsApp API',
          viaIcon: Icons.message,
          messagedAt: '2023-11-20 14:30',
          type: 'Template',
          showDetails: true,
          content: 'This is a sent template message.',
        ),
        SizedBox(height: 12.h),
        _buildLogCard(
          recipient: '+1(555) 012-3456',
          status: 'Failed',
          statusColor: const Color(0xFFD92D20),
          from: 'System Bot',
          via: 'WhatsApp API',
          viaIcon: Icons.smartphone,
          messagedAt: '2023-11-20 14:30',
          type: 'Session',
          showRetry: true,
          content: 'Message failed to deliver due to connectivity issues.',
        ),
        SizedBox(height: 12.h),
        _buildLogCard(
          recipient: '+1(555) 012-3456',
          status: 'Delivered',
          statusColor: const Color(0xFF667085),
          from: 'Marketing',
          via: 'WhatsApp Cloud',
          viaIcon: Icons.message,
          messagedAt: '2023-11-20 14:30',
          type: 'Bulk',
          showDetails: true,
          content: 'Hi Rehman, thank you for your inquiry. Our team will get back to you shortly.',
        ),
      ],
    );
  }

  Widget _buildLogCard({
    required String recipient,
    required String status,
    required Color statusColor,
    required String from,
    required String via,
    required IconData viaIcon,
    required String messagedAt,
    required String type,
    String content = '',
    bool showDetails = false,
    bool showRetry = false,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RECIPIENT',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF98A2B3),
                      letterSpacing: 0.5,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    recipient,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF191C1E),
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      status == 'Sent' ? Icons.check : (status == 'Failed' ? Icons.close : Icons.done_all),
                      size: 12.sp,
                      color: statusColor,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          const Divider(color: Color(0xFFEAECF0)),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem('FROM', from),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VIA',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF98A2B3),
                        letterSpacing: 0.5,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(viaIcon, size: 14.sp, color: const Color(0xFF191C1E)),
                        SizedBox(width: 4.w),
                        Text(
                          via,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF191C1E),
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildInfoItem('MESSAGED AT', messagedAt),
          SizedBox(height: 12.h),
          const Divider(color: Color(0xFFEAECF0)),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem('TYPE', type),
              if (showDetails)
                GestureDetector(
                  onTap: () {
                    context.push(AppRoutes.messageLogDetail, extra: {
                      'recipient': recipient,
                      'status': status,
                      'from': from,
                      'via': via,
                      'messagedAt': messagedAt,
                      'type': type,
                      'content': content,
                    });
                  },
                  child: Container(
                    height: 32.h,
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF006973),
                      borderRadius: BorderRadius.circular(8.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Details',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Icon(Icons.chevron_right, color: Colors.white, size: 14.sp),
                      ],
                    ),
                  ),
                ),
              if (showRetry)
                GestureDetector(
                  onTap: () {},
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, color: const Color(0xFFD92D20), size: 16.sp),
                      SizedBox(width: 4.w),
                      Text(
                        'Retry',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFD92D20),
                          fontFamily: 'Plus Jakarta Sans',
                        ),
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

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF98A2B3),
            letterSpacing: 0.5,
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF191C1E),
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
      ],
    );
  }
}
