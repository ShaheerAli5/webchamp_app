import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class QrCodeScreen extends StatelessWidget {
  const QrCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(57.h),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleSpacing: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black, size: 24.sp),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'QR Code',
            style: TextStyle(
              color: const Color(0xFF151515),
              fontSize: 20.sp,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
              height: 13.1 / 20,
              letterSpacing: 0.06,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              color: const Color(0xFFDCE2F3),
              height: 1,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Subtle WhatsApp-style doodle background pattern
          Positioned.fill(
            child: Opacity(
              opacity: 0.03,
              child: Image.network(
                'https://w0.peakpx.com/wallpaper/580/551/HD-wallpaper-whatsapp-doodle-patterns-thumbnail.jpg',
                repeat: ImageRepeat.repeat,
                fit: BoxFit.none,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              children: [
                SizedBox(height: 32.h),
                // QR Code Main Container
                Container(
                  width: 358.w,
                  height: 412.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: 40.h),
                      // QR Code Frame
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 200.w,
                              height: 200.w,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black12, width: 1),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            Icon(
                              Iconsax.scan_barcode,
                              size: 140.sp,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Instruction Card
                      Container(
                        width: 358.w,
                        height: 124.h,
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFEFEF),
                          borderRadius: BorderRadius.circular(18.r),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 28.w,
                                  height: 28.w,
                                  padding: EdgeInsets.all(5.w),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE4E4E4),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Icon(Iconsax.message_2, size: 16.sp, color: Colors.black),
                                ),
                                SizedBox(width: 12.w),
                                Text(
                                  'Link your device',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF151515),
                                    height: 17 / 16,
                                    fontFamily: 'Inter',
                                    letterSpacing: -0.08,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12.h),
                            Expanded(
                              child: Text(
                                'Open WhatsApp on your phone, tap Menu or Settings and select Linked Devices. Point your phone to this screen to capture the code.',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: const Color(0xFF344054),
                                  height: 1.4,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Bottom Buttons
                Padding(
                  padding: EdgeInsets.only(bottom: 24.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 171.w,
                        height: 48.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFEFEF),
                          borderRadius: BorderRadius.circular(18.r),
                        ),
                        child: TextButton(
                          onPressed: () {},
                          child: Text(
                            'Need Help?',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 171.w,
                        height: 48.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFF007176),
                          borderRadius: BorderRadius.circular(18.r),
                        ),
                        child: TextButton(
                          onPressed: () {},
                          child: Text(
                            'Refresh QR Code',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontFamily: 'Inter',
                            ),
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
}
