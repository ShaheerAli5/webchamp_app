import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isMonthly = true;
  String _selectedPlan = 'Basic';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(57.h),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFEAECF0), width: 1),
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
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
                  child: SizedBox(
                    width: 24.w,
                    height: 24.h,
                    child: Icon(Icons.arrow_back, color: Colors.black, size: 24.sp),
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'My Subscription',
                  style: TextStyle(
                    color: const Color(0xFF151515),
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 120.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCurrentPlanCard(),
                SizedBox(height: 24.h),
                _buildSectionHeader(),
                SizedBox(height: 16.h),
                _buildPaidPlansList(),
                SizedBox(height: 24.h),
                _buildManualPaymentSection(),
              ],
            ),
          ),
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildCurrentPlanCard() {
    return Container(
      width: 358.w,
      height: 479.h, // Fixed height from design
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: const Color(0xFFE7F6EC),
              borderRadius: BorderRadius.circular(99.r),
            ),
            child: Text(
              'CURRENT PLAN',
              style: TextStyle(
                color: const Color(0xFF039855),
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(height: 16.h), // Gap 16px from design
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Free',
                    style: TextStyle(
                      color: const Color(0xFF007176),
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                  Text(
                    'Great for getting started',
                    style: TextStyle(
                      color: const Color(0xFF667085),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              Container(
                width: 48.w,
                height: 48.w,
                decoration: const BoxDecoration(
                  color: Color(0xFFE1F4F4),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.workspace_premium_outlined, color: const Color(0xFF007176), size: 28.sp),
              ),
            ],
          ),
          SizedBox(height: 16.h), // Gap 16px from design
          _buildFeatureItem('5 Contacts', true),
          _buildFeatureItem('0 Campaigns Per Month', true),
          _buildFeatureItem('0 Bot Replies', true),
          _buildFeatureItem('Unlimited Bot Flows', true),
          _buildFeatureItem('0 Contact Custom Fields', true),
          _buildFeatureItem('1 Team Members/Agents', true),
          _buildFeatureItem('AI Chat Bot', false),
          _buildFeatureItem('API and Webhook Access', false),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'SUBSCRIBE PAID PLANS',
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF475467),
            letterSpacing: 0.5,
          ),
        ),
        Container(
          height: 32.h,
          decoration: BoxDecoration(
            color: const Color(0xFFF2F4F7),
            borderRadius: BorderRadius.circular(99.r),
          ),
          padding: EdgeInsets.all(2.w),
          child: Row(
            children: [
              _buildToggleButton('Monthly', _isMonthly, () => setState(() => _isMonthly = true)),
              _buildToggleButton('Yearly', !_isMonthly, () => setState(() => _isMonthly = false)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        height: double.infinity,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF006C70) : Colors.transparent,
          borderRadius: BorderRadius.circular(99.r),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF475467),
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildPaidPlansList() {
    return SizedBox(
      height: 530.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: [
          _buildPlanCard(
            title: 'Basic',
            price: '10.00',
            badge: 'RECOMMENDED FOR INDIVIDUALS',
            badgeColor: const Color(0xFFE0F2F2),
            badgeTextColor: const Color(0xFF007176),
            isRecommended: true,
            isSelected: _selectedPlan == 'Basic',
            onTap: () => setState(() => _selectedPlan = 'Basic'),
            features: [
              '5000 Contacts',
              'Unlimited Campaigns',
              'Unlimited Bot Replies',
              'Unlimited Bot Flows',
              '3 Contact Custom Fields',
              '3 Team Members/Agents',
              'AI Chat Bot',
            ],
            missingFeatures: ['API Access and Webhook Access'],
          ),
          SizedBox(width: 16.w),
          _buildPlanCard(
            title: 'Premium',
            price: '30.00',
            badge: 'MOST POPULAR',
            badgeColor: const Color(0xFFFEF3F2),
            badgeTextColor: const Color(0xFFB42318),
            isSelected: _selectedPlan == 'Premium',
            onTap: () => setState(() => _selectedPlan = 'Premium'),
            features: [
              'Unlimited Contacts',
              'Unlimited Campaigns',
              'Unlimited Bot Replies',
              'Unlimited Bot Flows',
              'Unlimited Custom Fields',
              'Unlimited Team Members',
              'AI Chat Bot',
              'API Access and Webhook Access',
            ],
          ),
          SizedBox(width: 16.w),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    String? badge,
    Color? badgeColor,
    Color? badgeTextColor,
    bool isRecommended = false,
    required bool isSelected,
    required VoidCallback onTap,
    required List<String> features,
    List<String> missingFeatures = const [],
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 304.3.w,
        height: 503.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
              color: isSelected ? const Color(0xFF007176) : const Color(0xFFEAECF0),
              width: isSelected ? 1.5 : 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
          gradient: isRecommended
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFFFFF), Color(0xFFF0F3FF)],
                )
              : null,
        ),
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (badge != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(99.r),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        color: badgeTextColor,
                        fontSize: 8.5.sp,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                      ),
                    ),
                  )
                else
                  const SizedBox(),
                Container(
                  width: 18.w,
                  height: 18.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF007176) : const Color(0xFFD0D5DD),
                      width: isSelected ? 5.w : 1.w,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 32.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF101828),
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
            SizedBox(height: 6.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF101828),
                    fontFamily: 'Inter',
                  ),
                ),
                SizedBox(width: 4.w),
                Text(
                  'USD /mo',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF667085),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            Expanded(
              child: ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  ...features.map((f) => _buildFeatureItem(f, true, isSmall: true)),
                  ...missingFeatures.map((f) => _buildFeatureItem(f, false, isSmall: true)),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              height: 48.h,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F7),
                borderRadius: BorderRadius.circular(12.r),
              ),
              alignment: Alignment.center,
              child: Text(
                'Choose $title',
                style: TextStyle(
                  color: const Color(0xFF344054),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text, bool isEnabled, {bool isSmall = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Icon(
            isEnabled ? Icons.check_rounded : Icons.close_rounded,
            color: isEnabled ? const Color(0xFF039855) : const Color(0xFFD92D20),
            size: isSmall ? 16.sp : 18.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isEnabled ? const Color(0xFF344054) : const Color(0xFF98A2B3),
                fontSize: isSmall ? 13.sp : 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualPaymentSection() {
    return Container(
      width: 358.w,
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(18.r),
      ),
      padding: EdgeInsets.all(12.w),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Use min size to "hug" content
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38.w,
                height: 38.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFE4E7EC),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(Icons.account_balance_wallet_outlined,
                    color: const Color(0xFF007176), size: 20.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prefer Manual Payment?',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF101828),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'We accept wire transfers and crypto.',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: const Color(0xFF475467),
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.only(left: 50.w),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: const Color(0xFFEAECF0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Manual/Prepaid Subscription',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF101828),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Icon(Icons.north_east_rounded, size: 14.sp, color: const Color(0xFF101828)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, MediaQuery.of(context).padding.bottom + 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: () {},
          child: Container(
            height: 48.h, // Fixed 48px from design
            width: 358.w, // Fill 358px from design
            decoration: BoxDecoration(
              color: const Color(0xFF007176), // #007176 from design
              borderRadius: BorderRadius.circular(18.r), // 18px from design
            ),
            alignment: Alignment.center,
            child: Text(
              'Continue to Payment',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
