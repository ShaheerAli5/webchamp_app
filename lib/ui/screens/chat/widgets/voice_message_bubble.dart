import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/utils/voice_playback_manager.dart';

class VoiceMessageBubble extends StatefulWidget {
  final String audioUrl;
  final bool isMe;
  final int? duration;
  final String? senderImageUrl;
  final String time;
  final Widget? statusIcon;

  const VoiceMessageBubble({
    super.key,
    required this.audioUrl,
    required this.isMe,
    this.duration,
    this.senderImageUrl,
    required this.time,
    this.statusIcon,
  });

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  late final VoicePlaybackManager _manager;

  @override
  void initState() {
    super.initState();
    _manager = VoicePlaybackManager();
    _manager.addListener(_onManagerUpdate);
  }

  @override
  void dispose() {
    _manager.removeListener(_onManagerUpdate);
    super.dispose();
  }

  void _onManagerUpdate() {
    if (mounted) setState(() {});
  }

  bool get _isThisPlaying => _manager.currentAudioUrl == widget.audioUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250.w,
      padding: EdgeInsets.fromLTRB(10.w, 6.h, 12.w, 4.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildAvatar(),
              _buildPlayButton(),
              Expanded(child: _buildSlider()),
            ],
          ),
          SizedBox(height: 2.h),
          _buildInfoRow(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      margin: EdgeInsets.only(right: 8.w),
      child: Stack(
        children: [
          CircleAvatar(
            radius: 18.r,
            backgroundColor: Colors.grey[300],
            backgroundImage: widget.senderImageUrl != null && widget.senderImageUrl!.isNotEmpty 
                ? NetworkImage(widget.senderImageUrl!) 
                : null,
            child: (widget.senderImageUrl == null || widget.senderImageUrl!.isEmpty) 
                ? Icon(Icons.person, color: Colors.white, size: 24.sp) 
                : null,
          ),
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              padding: EdgeInsets.all(1.r),
              decoration: BoxDecoration(
                color: widget.isMe ? const Color(0xFFE2FFC7) : Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.mic, size: 12.sp, color: const Color(0xFF34B7F1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayButton() {
    final bool isPlaying = _isThisPlaying && _manager.isPlaying;
    return IconButton(
      onPressed: () => _manager.togglePlay(widget.audioUrl),
      icon: Icon(
        isPlaying ? Icons.pause : Icons.play_arrow,
        color: const Color(0xFF54656F),
        size: 32.sp,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }

  Widget _buildSlider() {
    final bool active = _isThisPlaying;
    final Duration position = active ? _manager.player.position : Duration.zero;
    final Duration duration = active 
        ? (_manager.player.duration ?? Duration(seconds: widget.duration ?? 0))
        : Duration(seconds: widget.duration ?? 0);
    
    final double max = duration.inMilliseconds.toDouble();
    final double value = position.inMilliseconds.toDouble().clamp(0, max);
    
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 2.h,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.r),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 12.r),
        activeTrackColor: const Color(0xFF34B7F1),
        inactiveTrackColor: Colors.grey[300],
        thumbColor: const Color(0xFF34B7F1),
      ),
      child: Slider(
        value: value,
        max: max > 0 ? max : 1.0,
        onChanged: (v) {
          if (active) {
            _manager.player.seek(Duration(milliseconds: v.toInt()));
          } else {
             // If not playing, start it and seek
             _manager.togglePlay(widget.audioUrl).then((_) {
               _manager.player.seek(Duration(milliseconds: v.toInt()));
             });
          }
        },
      ),
    );
  }

  Widget _buildInfoRow() {
    final bool active = _isThisPlaying;
    final Duration position = active ? _manager.player.position : Duration.zero;
    final Duration duration = active 
        ? (_manager.player.duration ?? Duration(seconds: widget.duration ?? 0))
        : Duration(seconds: widget.duration ?? 0);

    final displayDuration = active && _manager.isPlaying 
        ? position 
        : duration;
        
    return Padding(
      padding: EdgeInsets.only(left: 44.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            Helpers.formatDuration(displayDuration.inSeconds),
            style: TextStyle(fontSize: 11.sp, color: const Color(0xFF667781))
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.time, 
                style: TextStyle(fontSize: 10.sp, color: const Color(0xFF667781))
              ),
              if (widget.isMe) ...[
                SizedBox(width: 4.w),
                if (widget.statusIcon != null) widget.statusIcon!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}

