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
  int? _autoDetectedDuration;
  bool _isDetecting = false;

  @override
  void initState() {
    super.initState();
    _manager = VoicePlaybackManager();
    _manager.addListener(_onManagerUpdate);
    
    // 🛡️ If duration is missing or 0, try to auto-detect it from the source
    if (widget.duration == null || widget.duration == 0) {
      _detectDuration();
    }
  }

  Future<void> _detectDuration() async {
    if (_isDetecting || widget.audioUrl.isEmpty) return;
    
    setState(() => _isDetecting = true);
    try {
      final player = AudioPlayer();
      Duration? d;
      if (widget.audioUrl.startsWith('http')) {
        d = await player.setUrl(widget.audioUrl);
      } else {
        d = await player.setFilePath(widget.audioUrl);
      }
      
      if (mounted && d != null && d.inSeconds > 0) {
        setState(() {
          _autoDetectedDuration = d!.inSeconds;
        });
        debugPrint('📊 [VOICE] Auto-detected duration for ${widget.audioUrl.split('/').last}: $_autoDetectedDuration sec');
      }
      await player.dispose();
    } catch (e) {
      debugPrint('⚠️ [VOICE] Could not auto-detect duration: $e');
    } finally {
      if (mounted) setState(() => _isDetecting = false);
    }
  }

  @override
  void didUpdateWidget(VoiceMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioUrl != widget.audioUrl && (widget.duration == null || widget.duration == 0)) {
      _detectDuration();
    }
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
      width: 220.w,
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 14.w, 8.h),
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
    if (_isThisPlaying) {
      return GestureDetector(
        onTap: () => _manager.toggleSpeed(),
        child: Container(
          width: 36.r,
          height: 36.r,
          margin: EdgeInsets.only(right: 8.w),
          decoration: BoxDecoration(
            color: const Color(0xFFE9EDEF),
            borderRadius: BorderRadius.circular(18.r),
          ),
          alignment: Alignment.center,
          child: Text(
            '${_manager.currentSpeed.toString().replaceAll('.0', '')}x',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF54656F),
            ),
          ),
        ),
      );
    }

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
    
    // 🛡️ Priority: 1. Active Player 2. Auto-detected 3. Widget Prop
    final int effectiveSeconds = (active && _manager.player.duration != null) 
        ? _manager.player.duration!.inSeconds 
        : (_autoDetectedDuration ?? widget.duration ?? 0);

    final Duration duration = Duration(seconds: effectiveSeconds);
    
    final double max = duration.inMilliseconds.toDouble();
    final double value = position.inMilliseconds.toDouble().clamp(0, max > 0 ? max : 1.0);
    
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
    
    final int effectiveSeconds = (active && _manager.player.duration != null) 
        ? _manager.player.duration!.inSeconds 
        : (_autoDetectedDuration ?? widget.duration ?? 0);

    final Duration duration = Duration(seconds: effectiveSeconds);

    // 🛡️ WhatsApp behavior: If playing, show current position. If stopped, show total duration.
    final displayDuration = (active && _manager.isPlaying) 
        ? position 
        : duration;
        
    return Padding(
      padding: EdgeInsets.only(left: 44.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            Helpers.formatDuration(displayDuration.inSeconds),
            style: TextStyle(fontSize: 11.sp, color: const Color(0xFF667781), fontWeight: FontWeight.w500)
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isDetecting && (widget.duration == null || widget.duration == 0))
                Padding(
                  padding: EdgeInsets.only(right: 4.w),
                  child: SizedBox(
                    width: 8.w,
                    height: 8.w,
                    child: const CircularProgressIndicator(strokeWidth: 1, color: Color(0xFF34B7F1)),
                  ),
                ),
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

