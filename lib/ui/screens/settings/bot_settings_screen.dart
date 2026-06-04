import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class BotSettingsScreen extends StatefulWidget {
  const BotSettingsScreen({super.key});

  @override
  State<BotSettingsScreen> createState() => _BotSettingsScreenState();
}

class _BotSettingsScreenState extends State<BotSettingsScreen> {
  bool _showTip = true;
  bool _isTimingExpanded = false;
  bool _isGeneralExpanded = false;
  bool _isOpenAIExpanded = false;
  bool _isFlowiseExpanded = false;
  
  bool _enableTimingRestrictions = true;
  bool _enableBotByDefault = true;
  
  final TextEditingController _errorMessageController = TextEditingController(
    text: 'Sorry but something went wrong while processing your request by our AI.',
  );

  @override
  void dispose() {
    _errorMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: const Color(0xFF151515), size: 24.sp),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: Text(
          'Bot Settings',
          style: TextStyle(
            color: const Color(0xFF151515),
            fontSize: 20.sp,
            fontWeight: FontWeight.w500,
            fontFamily: 'Plus Jakarta Sans',
            letterSpacing: 0.06,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(
            color: const Color(0xFFEAECF0),
            height: 1.h,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('BOT SETTINGS'),
              _buildExpandableSettingsCard(
                title: 'Bot Timing Settings',
                isExpanded: _isTimingExpanded,
                onTap: () => setState(() {
                  _isTimingExpanded = !_isTimingExpanded;
                  if (_isTimingExpanded) _isGeneralExpanded = false;
                }),
                expandedContent: _buildTimingExpandedContent(),
              ),
              SizedBox(height: 16.h),
              _buildExpandableSettingsCard(
                title: 'AI Bot General Settings',
                isExpanded: _isGeneralExpanded,
                onTap: () => setState(() {
                  _isGeneralExpanded = !_isGeneralExpanded;
                  if (_isGeneralExpanded) _isTimingExpanded = false;
                }),
                expandedContent: _buildGeneralExpandedContent(),
              ),
              
              SizedBox(height: 24.h),
              _buildSectionHeader('AI BOTS INTEGRATIONS'),
              
              if (_showTip) ...[
                _buildTipBox(),
                SizedBox(height: 16.h),
              ],
              
              _buildExpandableSettingsCard(
                title: 'OpenAI Bot Setup',
                isExpanded: _isOpenAIExpanded,
                onTap: () => setState(() {
                  _isOpenAIExpanded = !_isOpenAIExpanded;
                  if (_isOpenAIExpanded) {
                    _isTimingExpanded = false;
                    _isGeneralExpanded = false;
                  }
                }),
                leading: Image.asset(
                  'assets/images/AI-logo.png',
                  width: 16.w,
                  height: 16.w,
                  fit: BoxFit.contain,
                ),
                expandedContent: _buildOpenAIExpandedContent(),
              ),
              SizedBox(height: 16.h),
              _buildExpandableSettingsCard(
                title: 'Flowise Bot Setup',
                isExpanded: _isFlowiseExpanded,
                onTap: () => setState(() {
                  _isFlowiseExpanded = !_isFlowiseExpanded;
                  if (_isFlowiseExpanded) {
                    _isTimingExpanded = false;
                    _isGeneralExpanded = false;
                    _isOpenAIExpanded = false;
                  }
                }),
                leading: Image.asset(
                  'assets/images/2-logo.png',
                  width: 16.w,
                  height: 16.w,
                  fit: BoxFit.contain,
                ),
                expandedContent: _buildFlowiseExpandedContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF007176),
          letterSpacing: 0.55,
          fontFamily: 'Plus Jakarta Sans',
        ),
      ),
    );
  }

  Widget _buildExpandableSettingsCard({
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    Widget? expandedContent,
    Widget? leading,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFEAECF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Row(
                children: [
                  if (leading != null) ...[
                    leading,
                    SizedBox(width: 12.w),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF0F172A),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: const Color(0xFF667085),
                    size: 24.sp,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded && expandedContent != null) ...[
            const Divider(height: 1, color: Color(0xFFEAECF0)),
            expandedContent,
          ],
        ],
      ),
    );
  }

  Widget _buildSimpleSettingsCard(String title, {Widget? leading}) {
    return Container(
      constraints: BoxConstraints(minHeight: 58.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFEAECF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading,
            SizedBox(width: 12.w),
          ],
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0F172A),
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
          ),
          Icon(
            Icons.keyboard_arrow_down,
            color: const Color(0xFF667085),
            size: 24.sp,
          ),
        ],
      ),
    );
  }

  Widget _buildTimingExpandedContent() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          Row(
            children: [
              _buildCustomSwitch(
                value: _enableTimingRestrictions,
                onChanged: (val) => setState(() => _enableTimingRestrictions = val),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Enable Bot Timing Restrictions',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF667085),
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          _buildActionButtons(onCancel: () => setState(() => _isTimingExpanded = false)),
        ],
      ),
    );
  }

  Widget _buildOpenAIExpandedContent() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Using OpenAI you can build your chat bot for your custom information so it can answer the questions of the customer based on the information you have provided.',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF475467),
              height: 1.5,
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          SizedBox(height: 24.h),
          Container(
            width: 324.w,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEECD),
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: const Color(0xFFD8953D).withOpacity(0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9DBAF),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.error_outline,
                    color: const Color(0xFF633600),
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upgrade',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF633600),
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'This Feature is not available in your plan, please upgrade your subscription plan.',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF633600).withOpacity(0.8),
                          height: 1.4,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                      SizedBox(height: 16.h),
                      GestureDetector(
                        onTap: () => context.push('/subscription'),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: const Color(0xFFEAECF0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Upgrade Now',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF101828),
                                  fontFamily: 'Plus Jakarta Sans',
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Icon(
                                Icons.arrow_outward,
                                size: 14.sp,
                                color: const Color(0xFF101828),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowiseExpandedContent() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 324.w,
            child: Text(
              'FlowiseAI is a platform designed to simplify the creation and management of chatbots by leveraging OpenAI\'s powerful AI models, including GPT (Generative Pre-trained Transformer). It provides users with tools to design, build, and deploy AI-powered chatbots tailored to a wide range of applications, from customer service and support to personalized interactions and engagement. FlowiseAI aims to make the development of intelligent chatbots accessible to businesses and developers of all sizes, emphasizing ease of use, scalability, and integration capabilities. By utilizing FlowiseAI, organizations can enhance their customer experience, automate responses to',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF475467),
                height: 1.375, // 19.25/14
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF43F5E),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_circle_outline, color: Colors.white, size: 20.sp),
                      SizedBox(width: 8.w),
                      Text(
                        'Tutorials',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Container(
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFF94A3B8),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Official Website',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralExpandedContent() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Error Message Section
          SizedBox(
            width: 326.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 16.h,
                  child: Text(
                    'ERROR MESSAGE',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3C494B),
                      letterSpacing: 0.55,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  width: 326.w,
                  height: 60.h, // Adjusted to fit text and padding comfortably
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F4F7).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  child: TextField(
                    controller: _errorMessageController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF151C27),
                      fontFamily: 'Plus Jakarta Sans',
                      height: 1.42, // 20/14
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                SizedBox(
                  width: 326.w,
                  child: Text(
                    'If for some reason AI Bot failed to respond this error message will be sent to contact WhatsApp, Leave blank if you do not want to send such a message.',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF3C494B).withOpacity(0.8),
                      fontStyle: FontStyle.italic,
                      height: 1.5, // 18/12
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 32.h), // Gap between sections as per Figma

          // Enable AI Bot Section
          SizedBox(
            width: 324.w,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 4.h),
                  child: _buildCustomSwitch(
                    value: _enableBotByDefault,
                    onChanged: (val) => setState(() => _enableBotByDefault = val),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ENABLE AI CHAT BOT BY DEFAULT FOR ALL NEW CONTACTS',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3C494B),
                          letterSpacing: 0.55,
                          fontFamily: 'Plus Jakarta Sans',
                          height: 1.45, // 16/11
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'It will enable for AI Chat bot for contacts created using incoming messages, import etc.',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF3C494B),
                          height: 1.375, // 19.25/14
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),
          _buildActionButtons(onCancel: () => setState(() => _isGeneralExpanded = false)),
        ],
      ),
    );
  }

  Widget _buildCustomSwitch({required bool value, required ValueChanged<bool> onChanged}) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 40.w,
        height: 24.h,
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9999.r),
          color: value ? const Color(0xFF007176) : const Color(0xFFD0D5DD),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20.w,
            height: 20.w,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons({required VoidCallback onCancel}) {
    return SizedBox(
      width: 324.w,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onCancel,
              child: Container(
                height: 48.h,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEFEF),
                  borderRadius: BorderRadius.circular(18.r),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF344054),
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 16.w), // Updated gap to 16px as per Figma
          Expanded(
            child: GestureDetector(
              onTap: onCancel,
              child: Container(
                height: 48.h,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF007176),
                  borderRadius: BorderRadius.circular(18.r),
                ),
                child: Text(
                  'Save',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipBox() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.bannerBg,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.bannerBorder.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28.w,
            height: 28.w,
            decoration: BoxDecoration(
              color: const Color(0xFFD8953D).withOpacity(0.3),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Center(
              child: Icon(
                Icons.lightbulb_outline,
                color: AppColors.bannerText,
                size: 16.sp,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tip',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.bannerText,
                    fontFamily: 'Plus Jakarta Sans',
                    letterSpacing: -0.08,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'AI Chat bot only get triggered if manual chat bot did not respond and contact has enabled for AI Bot reply.',
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.bannerText,
                    height: 1.4,
                    fontFamily: 'Plus Jakarta Sans',
                    letterSpacing: -0.08,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: () => setState(() => _showTip = false),
            child: Padding(
              padding: EdgeInsets.only(top: 2.h),
              child: Icon(
                Icons.close,
                size: 14.sp,
                color: AppColors.bannerText.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
