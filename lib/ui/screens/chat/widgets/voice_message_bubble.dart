import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
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
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static String? _activeUrl;
  static double _speed = 1.0;

  StreamSubscription? _stateSub;
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _compSub;

  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isLoading = false;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() {
    _attachListeners();
  }

  void _attachListeners() {
    _stateSub?.cancel();
    _stateSub = _audioPlayer.onPlayerStateChanged.listen((s) {
      if (mounted) {
        setState(() {
          _playerState = (_activeUrl == widget.audioUrl) ? s : PlayerState.stopped;
        });
      }
    });

    _posSub?.cancel();
    _posSub = _audioPlayer.onPositionChanged.listen((p) {
      if (_activeUrl == widget.audioUrl && mounted) {
        setState(() => _position = p);
      }
    });

    _durSub?.cancel();
    _durSub = _audioPlayer.onDurationChanged.listen((d) {
      if (_activeUrl == widget.audioUrl && mounted) {
        setState(() => _duration = d);
      }
    });

    _compSub?.cancel();
    _compSub = _audioPlayer.onPlayerComplete.listen((_) {
      if (_activeUrl == widget.audioUrl && mounted) {
        setState(() {
          _playerState = PlayerState.completed;
          _position = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _compSub?.cancel();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_activeUrl == widget.audioUrl) {
      if (_playerState == PlayerState.playing) {
        await _audioPlayer.pause();
      } else if (_playerState == PlayerState.completed) {
        await _audioPlayer.seek(Duration.zero);
        await _audioPlayer.resume();
      } else {
        await _audioPlayer.resume();
      }
    } else {
      await _startNew();
    }
  }

  Future<void> _startNew() async {
    if (_isLoading) return;
    
    setState(() { 
      _isLoading = true; 
      _isError = false; 
    });

    try {
      _activeUrl = widget.audioUrl;
      await _audioPlayer.stop();

      Source source;
      if (widget.audioUrl.startsWith('http')) {
        final file = await DefaultCacheManager().getSingleFile(widget.audioUrl);
        source = DeviceFileSource(file.path);
      } else {
        source = DeviceFileSource(widget.audioUrl);
      }

      await _audioPlayer.setSource(source);
      await _audioPlayer.setPlaybackRate(_speed);
      await _audioPlayer.resume();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _playerState = _audioPlayer.state;
        });
      }
    } catch (e) {
      debugPrint("Audio Playback Error: $e");
      if (mounted) {
        setState(() { 
          _isLoading = false; 
          _isError = true; 
          _activeUrl = null; 
        });
      }
    }
  }

  void _changeSpeed() {
    setState(() {
      if (_speed == 1.0) _speed = 1.5;
      else if (_speed == 1.5) _speed = 2.0;
      else _speed = 1.0;
    });
    if (_activeUrl == widget.audioUrl) {
      _audioPlayer.setPlaybackRate(_speed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isActive = _activeUrl == widget.audioUrl;
    final bool isPlaying = isActive && _playerState == PlayerState.playing;
    final bool isCompleted = isActive && _playerState == PlayerState.completed;

    return Container(
      width: 250.w,
      padding: EdgeInsets.fromLTRB(10.w, 8.h, 12.w, 4.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildAvatar(),
              SizedBox(width: 8.w),
              _buildPlayButton(isPlaying, isCompleted),
              SizedBox(width: 4.w),
              _buildWaveform(isActive),
              if (isActive || _speed != 1.0) ...[
                SizedBox(width: 8.w),
                _buildSpeedButton(),
              ],
            ],
          ),
          SizedBox(height: 2.h),
          _buildInfoRow(isActive),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 20.r,
          backgroundColor: Colors.grey[300],
          backgroundImage: widget.senderImageUrl != null && widget.senderImageUrl!.isNotEmpty 
              ? NetworkImage(widget.senderImageUrl!) 
              : null,
          child: (widget.senderImageUrl == null || widget.senderImageUrl!.isEmpty) 
              ? Icon(Icons.person, color: Colors.white, size: 24.sp) 
              : null,
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: EdgeInsets.all(1.r),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Icon(Icons.mic, size: 12.sp, color: const Color(0xFF34B7F1)),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayButton(bool isPlaying, bool isCompleted) {
    if (_isLoading) {
      return SizedBox(
        width: 32.w, 
        height: 32.w, 
        child: const Center(
          child: SizedBox(
            width: 18, 
            height: 18, 
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00A884))
          )
        )
      );
    }
    if (_isError) {
      return IconButton(
        onPressed: _startNew, 
        icon: Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28.sp),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      );
    }
    return IconButton(
      onPressed: _togglePlay,
      icon: Icon(
        isCompleted ? Icons.replay : (isPlaying ? Icons.pause : Icons.play_arrow),
        color: const Color(0xFF54656F),
        size: 32.sp,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }

  Widget _buildWaveform(bool isActive) {
    final double progress = (isActive && _duration.inMilliseconds > 0)
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    return Expanded(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(24, (i) {
              final double barProgress = i / 24;
              // Simple pseudo-random heights for waveform look
              final heights = [10, 14, 18, 12, 16, 20, 14, 10, 16, 18, 14, 12, 20, 16, 12, 18, 14, 10, 16, 14, 12, 18, 16, 10];
              return Container(
                width: 2.w,
                height: heights[i % heights.length].h,
                decoration: BoxDecoration(
                  color: barProgress < progress ? const Color(0xFF34B7F1) : Colors.grey[300],
                  borderRadius: BorderRadius.circular(1.r),
                ),
              );
            }),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 24.h,
              thumbShape: isActive 
                  ? RoundSliderThumbShape(enabledThumbRadius: 6.r, elevation: 2) 
                  : SliderComponentShape.noThumb,
              activeTrackColor: Colors.transparent,
              inactiveTrackColor: Colors.transparent,
              thumbColor: const Color(0xFF34B7F1),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 0),
            ),
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              onChanged: isActive ? (v) {
                _audioPlayer.seek(Duration(milliseconds: (v * _duration.inMilliseconds).toInt()));
              } : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedButton() {
    return GestureDetector(
      onTap: _changeSpeed,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: const Color(0xFFE9EDEF),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Text(
          "${_speed.toStringAsFixed(1).replaceAll('.0', '')}x", 
          style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: const Color(0xFF54656F))
        ),
      ),
    );
  }

  Widget _buildInfoRow(bool isActive) {
    String durationText = "0:00";
    if (isActive && _duration.inSeconds > 0) {
      durationText = "${Helpers.formatDuration(_position.inSeconds)} / ${Helpers.formatDuration(_duration.inSeconds)}";
    } else if (widget.duration != null) {
      durationText = Helpers.formatDuration(widget.duration!);
    }

    if (_isLoading) durationText = "Loading Audio...";
    if (_isError) durationText = "Audio Failed";

    return Padding(
      padding: EdgeInsets.only(left: 48.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            durationText, 
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
