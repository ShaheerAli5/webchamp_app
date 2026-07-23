import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/utils/voice_playback_manager.dart';

class VoiceMessageBubble extends StatefulWidget {
  final String audioUrl;
  final String messageId;
  final bool isMe;
  final int? duration;
  final String? senderImageUrl;
  final String time;
  final Widget? statusIcon;

  const VoiceMessageBubble({
    super.key,
    required this.audioUrl,
    required this.messageId,
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
  StreamSubscription<Duration?>? _durationSubscription;
  int? _autoDetectedDuration;
  int? _knownTotalDuration;
  bool _isDetecting = false;

  @override
  void initState() {
    super.initState();
    _manager = VoicePlaybackManager();
    _manager.addListener(_onManagerUpdate);
    _knownTotalDuration = _initialDuration;

    // 🚀 PRELOAD: Buffer audio as soon as it's visible
    if (widget.audioUrl.isNotEmpty) {
      _manager.preload(widget.audioUrl);
    }

    _durationSubscription = _manager.durationStream.listen((duration) {
      if (!mounted) return;
      if (_isThisPlaying && duration != null && duration.inSeconds > 0) {
        setState(() {});
      }
    });

    // 🛡️ If duration is missing or 0, try to auto-detect it from the source
    if (widget.duration == null || widget.duration == 0) {
      _detectDuration();
    }
  }

  int? get _initialDuration {
    final int? widgetDuration =
        (widget.duration != null && widget.duration! > 0)
        ? widget.duration
        : null;
    return widgetDuration ?? _cachedManagerDuration ?? _autoDetectedDuration;
  }

  Future<void> _detectDuration() async {
    if (_isDetecting || widget.audioUrl.isEmpty) return;

    setState(() => _isDetecting = true);
    try {
      final duration = await _manager.getOrDetectDuration(
        widget.audioUrl,
        messageId: widget.messageId,
      );
      if (mounted && duration != null && duration > 0) {
        setState(() {
          _autoDetectedDuration = duration;
          _knownTotalDuration ??= duration;
        });
      }
    } catch (e) {
      debugPrint('⚠️ [VOICE] Could not auto-detect duration: $e');
    } finally {
      if (mounted) setState(() => _isDetecting = false);
    }
  }

  @override
  void didUpdateWidget(VoiceMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);

    // URL changed → reset auto-detection for the new URL if duration still unknown.
    if (oldWidget.audioUrl != widget.audioUrl) {
      if (widget.duration == null || widget.duration == 0) {
        _autoDetectedDuration = null;
        _detectDuration();
      }
      return;
    }

    // Server returned a valid duration for the first time (e.g. after optimistic
    // update is replaced by the server response). Prefer the server value and
    // clear the locally auto-detected one to avoid a stale override.
    final bool serverNowHasDuration =
        (widget.duration != null && widget.duration! > 0) &&
        (oldWidget.duration == null || oldWidget.duration == 0);
    if (serverNowHasDuration && _autoDetectedDuration != null) {
      // Server value takes precedence — clear the local detection result.
      setState(() => _autoDetectedDuration = null);
    }

    if (widget.duration != null && widget.duration! > 0) {
      _knownTotalDuration = widget.duration;
    }

    // If duration is still absent after the widget update, try detection again.
    if (widget.duration == null || widget.duration == 0) {
      if (_autoDetectedDuration == null && !_isDetecting) {
        _detectDuration();
      }
    }
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _manager.removeListener(_onManagerUpdate);
    super.dispose();
  }

  void _onManagerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  bool get _isThisPlaying => _manager.currentAudioMessageId == widget.messageId;

  int? get _cachedManagerDuration {
    return _manager.getCachedDurationByMessageId(widget.messageId) ??
        _manager.getCachedDuration(widget.audioUrl);
  }

  int? get _resolvedTotalDuration {
    final int? widgetDuration =
        (widget.duration != null && widget.duration! > 0)
        ? widget.duration
        : null;
    final int? managerDuration = _cachedManagerDuration;
    return widgetDuration ??
        _knownTotalDuration ??
        managerDuration ??
        _autoDetectedDuration;
  }

  Future<void> _ensureDurationSeeded() async {
    if (_resolvedTotalDuration != null && _resolvedTotalDuration! > 0) return;
    if (_isDetecting || widget.audioUrl.isEmpty) return;

    _isDetecting = true;
    try {
      final duration = await _manager.getOrDetectDuration(
        widget.audioUrl,
        messageId: widget.messageId,
      );
      if (!mounted || duration == null || duration <= 0) return;

      setState(() {
        _autoDetectedDuration = duration;
        _knownTotalDuration = duration;
      });
    } catch (e) {
      debugPrint('⚠️ [VOICE] Seed duration probe failed: $e');
    } finally {
      _isDetecting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          (widget.duration == null || widget.duration == 0) &&
          _resolvedTotalDuration == null) {
        _ensureDurationSeeded();
      }
    });

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
            backgroundImage:
                widget.senderImageUrl != null &&
                    widget.senderImageUrl!.isNotEmpty
                ? NetworkImage(widget.senderImageUrl!)
                : null,
            child:
                (widget.senderImageUrl == null ||
                    widget.senderImageUrl!.isEmpty)
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
              child: Icon(
                Icons.mic,
                size: 12.sp,
                color: const Color(0xFF34B7F1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayButton() {
    final bool isThisPlaying = _isThisPlaying;
    final bool isPlaying = isThisPlaying && _manager.isPlaying;
    final bool isBuffering = isThisPlaying && _manager.isBuffering;

    return Container(
      width: 48.w,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isBuffering)
            SizedBox(
              width: 30.r,
              height: 30.r,
              child: const CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF54656F)),
              ),
            ),
          IconButton(
            onPressed: () => _manager.togglePlay(
              widget.audioUrl,
              messageId: widget.messageId,
            ),
            icon: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: const Color(0xFF54656F),
              size: 32.sp,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider() {
    final bool active = _isThisPlaying;

    // 🛡️ Priority: 1. Active Player (live) → 2. Server/prop duration → 3. Auto-detected → 0
    final int? activePlayerSeconds = _manager.currentDuration?.inSeconds;
    final int effectiveSeconds = active && (activePlayerSeconds ?? 0) > 0
        ? activePlayerSeconds!
        : (_resolvedTotalDuration ?? 0);

    final double max = effectiveSeconds * 1000.0;

    return StreamBuilder<Duration>(
      stream: active ? _manager.positionStream : const Stream<Duration>.empty(),
      initialData: Duration.zero,
      builder: (context, snapshot) {
        final double value = snapshot.data!.inMilliseconds.toDouble().clamp(
          0,
          max > 0 ? max : 1.0,
        );

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
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildInfoRow() {
    final bool active = _isThisPlaying;

    final int? activePlayerSeconds = _manager.currentDuration?.inSeconds;
    final int? cachedDuration = _cachedManagerDuration;
    final int effectiveSeconds = active && (activePlayerSeconds ?? 0) > 0
        ? activePlayerSeconds!
        : (_resolvedTotalDuration ?? cachedDuration ?? 0);

    return Padding(
      padding: EdgeInsets.only(left: 44.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          StreamBuilder<Duration>(
            stream: active
                ? _manager.positionStream
                : Stream.value(Duration.zero),
            initialData: Duration.zero,
            builder: (context, snapshot) {
              // 🛡️ WhatsApp behavior: If playing, show current position. If stopped, show total duration.
              final int seconds = (active && _manager.isPlaying)
                  ? snapshot.data!.inSeconds
                  : effectiveSeconds;

              return Text(
                Helpers.formatDuration(seconds),
                style: TextStyle(
                  fontSize: 11.sp,
                  color: const Color(0xFF667781),
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isDetecting &&
                  (widget.duration == null || widget.duration == 0))
                // ...
                Padding(
                  padding: EdgeInsets.only(right: 4.w),
                  child: SizedBox(
                    width: 8.w,
                    height: 8.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 1,
                      color: Color(0xFF34B7F1),
                    ),
                  ),
                ),
              Text(
                widget.time,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: const Color(0xFF667781),
                ),
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
