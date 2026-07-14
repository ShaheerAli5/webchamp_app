import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../features/contacts/presentation/providers/contact_provider.dart';

class ChatCountdownTimer extends StatefulWidget {
  const ChatCountdownTimer({super.key});

  @override
  State<ChatCountdownTimer> createState() => _ChatCountdownTimerState();
}

class _ChatCountdownTimerState extends State<ChatCountdownTimer> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      final provider = context.read<ContactProvider>();
      final lastIncoming = provider.getLastIncomingMessageTime();
      if (lastIncoming != null) {
        final expiry = lastIncoming.add(const Duration(hours: 24));
        final now = Helpers.toUtc(null);
        final diff = expiry.difference(now);

        if (diff.inSeconds != _remaining.inSeconds) {
          setState(() {
            _remaining = diff;
          });
        }
      } else if (_remaining != Duration.zero) {
        setState(() {
          _remaining = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isExpired = _remaining.isNegative || _remaining == Duration.zero;
    final String formattedTime = Helpers.format24hCountdown(_remaining);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: isExpired ? const Color(0xFFFFEBEE) : const Color(0xFFD9FDD3),
        border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isExpired ? Icons.error_outline : Icons.history,
            size: 14.sp,
            color: isExpired ? Colors.red[700] : const Color(0xFF008069),
          ),
          SizedBox(width: 8.w),
          RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 12.sp, color: const Color(0xFF111B21)),
              children: [
                const TextSpan(text: "24-hour window "),
                TextSpan(
                  text: isExpired ? "expired" : "ends in $formattedTime left",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
