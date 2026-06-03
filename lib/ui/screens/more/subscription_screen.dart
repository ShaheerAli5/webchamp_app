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
                  'My Subscription',
                  style: TextStyle(
                    color: const Color(0xFF111212),
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
                SizedBox(height: 32.h),
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
        mainAxisSize: MainAxisSize.min,
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
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
          ),
          SizedBox(height: 16.h),
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
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                  Text(
                    'Great for getting started',
                    style: TextStyle(
                      color: const Color(0xFF667085),
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                ],
              ),
              Container(
                width: 40.w,
                height: 40.w,
                decoration: const BoxDecoration(
                  color: Color(0xFFE1F4F4),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.workspace_premium_outlined, color: const Color(0xFF007176), size: 24.sp),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          ListView(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildFeatureItem('5 Contacts', true, isSmall: true),
              _buildFeatureItem('0 Campaigns Per Month', true, isSmall: true),
              _buildFeatureItem('0 Bot Replies', true, isSmall: true),
              _buildFeatureItem('Unlimited Bot Flows', true, isSmall: true),
              _buildFeatureItem('0 Contact Custom Fields', true, isSmall: true),
              _buildFeatureItem('1 Team Members/Agents', true, isSmall: true),
              _buildFeatureItem('AI Chat Bot', false, isSmall: true),
              _buildFeatureItem('API and Webhook Access', false, isSmall: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Container(
      width: 358.w,
      height: 32.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'SUBSCRIBE PAID PLANS',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF475467),
              letterSpacing: 0.5,
              fontFamily: 'Plus Jakarta Sans',
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
      ),
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
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
      ),
    );
  }

  Widget _buildPaidPlansList() {
    return SizedBox(
      height: 440.h,
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
          SizedBox(width: 12.w),
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
          SizedBox(width: 12.w),
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
        width: 280.w,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
              color: isSelected ? const Color(0xFF007176) : const Color(0xFFEAECF0),
              width: isSelected ? 1.5 : 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
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
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (badge != null)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(99.r),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: badgeTextColor,
                    fontSize: 7.5.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ),
            SizedBox(height: 12.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF101828),
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF101828),
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
                SizedBox(width: 4.w),
                Text(
                  'USD /mo',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF667085),
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Expanded(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  ...features.map((f) => _buildFeatureItem(f, true, isSmall: true)),
                  ...missingFeatures.map((f) => _buildFeatureItem(f, false, isSmall: true)),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            Container(
              width: double.infinity,
              height: 40.h,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F7),
                borderRadius: BorderRadius.circular(12.r),
              ),
              alignment: Alignment.center,
              child: Text(
                'Choose $title',
                style: TextStyle(
                  color: const Color(0xFF344054),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualPaymentSection() {
    return Container(
      width: 358.w,
      height: 96.h,
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(18.r),
      ),
      padding: EdgeInsets.all(12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28.w,
                height: 28.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFE4E4E4),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(Icons.account_balance_wallet_outlined,
                    color: const Color(0xFF007176), size: 16.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prefer Manual Payment?',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF151515),
                        fontFamily: 'Plus Jakarta Sans',
                        height: 1.3,
                      ),
                    ),
                    Text(
                      'We accept wire transfers and crypto.',
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        color: const Color(0xFF151C27),
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Plus Jakarta Sans',
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 196.w,
            height: 26.h,
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(color: const Color(0xFFDFDEDA)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Manual/Prepaid Subscription',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF151515),
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(Icons.north_east_rounded, size: 10.sp, color: const Color(0xFF151515)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text, bool isEnabled, {bool isSmall = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Icon(
            isEnabled ? Icons.check_rounded : Icons.close_rounded,
            color: isEnabled ? const Color(0xFF039855) : const Color(0xFFD92D20),
            size: 14.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isEnabled ? const Color(0xFF344054) : const Color(0xFF98A2B3),
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                fontFamily: 'Plus Jakarta Sans',
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
            height: 48.h,
            width: 358.w,
            decoration: BoxDecoration(
              color: const Color(0xFF007176),
              borderRadius: BorderRadius.circular(18.r),
            ),
            alignment: Alignment.center,
            child: Text(
              'Continue to Payment',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
