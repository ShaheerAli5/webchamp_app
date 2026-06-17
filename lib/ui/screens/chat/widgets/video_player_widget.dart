import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:visibility_detector/visibility_detector.dart';

class FullScreenVideoPlayer extends StatefulWidget {
  final String videoUrl;
  const FullScreenVideoPlayer({super.key, required this.videoUrl});

  @override
  State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      if (widget.videoUrl.startsWith('http')) {
        _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      } else {
        _videoPlayerController = VideoPlayerController.file(File(widget.videoUrl));
      }

      await _videoPlayerController.initialize();
      
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      );
      setState(() {});
    } catch (e) {
      debugPrint("Video Player Error: $e");
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: _hasError
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 60),
                        SizedBox(height: 16.h),
                        const Text("Failed to load video", style: TextStyle(color: Colors.white)),
                        TextButton(onPressed: _initializePlayer, child: const Text("Retry"))
                      ],
                    )
                  : (_chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
                      ? Chewie(controller: _chewieController!)
                      : const CircularProgressIndicator()),
            ),
            Positioned(
              top: 10.h,
              left: 10.w,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoBubblePreview extends StatefulWidget {
  final String videoUrl;
  final bool isMe;
  final VoidCallback onTap;

  const VideoBubblePreview({
    super.key,
    required this.videoUrl,
    required this.isMe,
    required this.onTap,
  });

  @override
  State<VideoBubblePreview> createState() => _VideoBubblePreviewState();
}

class _VideoBubblePreviewState extends State<VideoBubblePreview> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isVisible = false;

  void _initController() {
    if (_controller != null || !_isVisible) return;

    setState(() {
      _hasError = false;
      _isInitialized = false;
    });

    try {
      if (widget.videoUrl.startsWith('http')) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      } else {
        _controller = VideoPlayerController.file(File(widget.videoUrl));
      }
      
      _controller?.initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }).catchError((e) {
        debugPrint("Video preview init error: $e");
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
      });
    } catch (e) {
       if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.videoUrl),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.1 && !_isVisible) {
          _isVisible = true;
          _initController();
        } else if (info.visibleFraction == 0 && _isVisible) {
          _isVisible = false;
        }
      },
      child: GestureDetector(
        onTap: _hasError ? _initController : widget.onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: Container(
            width: 200.w,
            height: 150.h,
            color: Colors.black,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_isInitialized && _controller != null)
                  SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller!.value.size.width,
                        height: _controller!.value.size.height,
                        child: VideoPlayer(_controller!),
                      ),
                    ),
                  )
                else if (_hasError)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.white, size: 30.sp),
                      SizedBox(height: 4.h),
                      Text("Error loading", style: TextStyle(color: Colors.white, fontSize: 10.sp)),
                      Text("Tap to retry", style: TextStyle(color: Colors.white70, fontSize: 8.sp)),
                    ],
                  )
                else
                  const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                
                if (_isInitialized)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    padding: EdgeInsets.all(8.w),
                    child: Icon(Icons.play_arrow, color: Colors.white, size: 40.sp),
                  ),
                
                if (_isInitialized && _controller != null)
                  Positioned(
                    bottom: 8.h,
                    left: 8.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        _formatDuration(_controller!.value.duration),
                        style: TextStyle(color: Colors.white, fontSize: 10.sp),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
