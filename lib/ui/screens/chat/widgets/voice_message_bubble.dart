import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../core/utils/helpers.dart';

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
  late AudioPlayer _audioPlayer;
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isDownloading = false;

  static VoiceMessageBubble? _activeBubble;
  static AudioPlayer? _globalAudioPlayer;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  void _initPlayer() {
    if (_globalAudioPlayer == null) {
      _globalAudioPlayer = AudioPlayer();
    }
    _audioPlayer = _globalAudioPlayer!;

    _audioPlayer.onDurationChanged.listen((d) {
      if (_activeBubble == widget) {
        if (mounted) setState(() => _duration = d);
      }
    });

    _audioPlayer.onPositionChanged.listen((p) {
      if (_activeBubble == widget) {
        if (mounted) setState(() => _position = p);
      }
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (_activeBubble == widget) {
        if (mounted) setState(() => _playerState = state);
      } else if (mounted) {
        setState(() => _playerState = PlayerState.stopped);
      }
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (_activeBubble == widget) {
        if (mounted) {
          setState(() {
            _position = Duration.zero;
            _playerState = PlayerState.stopped;
          });
        }
      }
    });
  }

  Future<void> _playPause() async {
    try {
      if (_activeBubble != widget) {
        await _audioPlayer.stop();
        _activeBubble = widget;
        
        setState(() => _isDownloading = true);
        await _audioPlayer.setSource(UrlSource(widget.audioUrl));
        setState(() => _isDownloading = false);
        
        await _audioPlayer.resume();
      } else {
        if (_playerState == PlayerState.playing) {
          await _audioPlayer.pause();
        } else {
          await _audioPlayer.resume();
        }
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color iconColor = Colors.black87;
    final Color progressColor = const Color(0xFF34B7F1);

    Widget avatar = Stack(
      children: [
        CircleAvatar(
          radius: 22.r,
          backgroundColor: const Color(0xFFDFE5E7),
          backgroundImage: widget.senderImageUrl != null ? NetworkImage(widget.senderImageUrl!) : null,
          child: widget.senderImageUrl == null 
              ? Icon(Icons.person, size: 28.r, color: Colors.white)
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.all(1.w),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mic,
              size: 13.sp,
              color: const Color(0xFF34B7F1),
            ),
          ),
        ),
      ],
    );

    Widget playButton = SizedBox(
      width: 36.w,
      height: 36.w,
      child: _isDownloading 
        ? Center(child: SizedBox(width: 18.w, height: 18.w, child: const CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00A884))))
        : IconButton(
            onPressed: _playPause,
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
            icon: Icon(
              (_activeBubble == widget && _playerState == PlayerState.playing) ? Icons.pause : Icons.play_arrow,
              color: iconColor,
              size: 32.sp,
            ),
          ),
    );

    Widget waveform = Expanded(
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.r),
          overlayShape: RoundSliderOverlayShape(overlayRadius: 10.r),
          trackHeight: 2.5.h,
          activeTrackColor: progressColor,
          inactiveTrackColor: Colors.grey[300],
          thumbColor: progressColor,
          trackShape: const RectangularSliderTrackShape(),
        ),
        child: Slider(
          value: (_activeBubble == widget) ? _position.inMilliseconds.toDouble() : 0.0,
          max: (_activeBubble == widget && _duration.inMilliseconds > 0) 
              ? _duration.inMilliseconds.toDouble() 
              : 1.0,
          onChanged: (value) {
            if (_activeBubble == widget) {
              _audioPlayer.seek(Duration(milliseconds: value.toInt()));
            }
          },
        ),
      ),
    );

    return Container(
      width: 260.w,
      padding: EdgeInsets.fromLTRB(6.w, 6.h, 6.w, 4.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: widget.isMe 
              ? [
                  avatar,
                  SizedBox(width: 4.w),
                  playButton,
                  waveform,
                ]
              : [
                  playButton,
                  waveform,
                  SizedBox(width: 4.w),
                  avatar,
                ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: widget.isMe ? 55.w : 40.w),
                  child: Text(
                    (_activeBubble == widget && _position.inSeconds > 0)
                        ? Helpers.formatDuration(_position.inSeconds)
                        : (widget.duration != null ? Helpers.formatDuration(widget.duration!) : "0:00"),
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: const Color(0xFF667781),
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.time,
                      style: TextStyle(fontSize: 10.sp, color: const Color(0xFF667781)),
                    ),
                    if (widget.isMe && widget.statusIcon != null) ...[
                      SizedBox(width: 2.w),
                      widget.statusIcon!,
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
