import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';

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
  final bool isFullWidth;
  final double? width;
  final double? height;
  final int? duration;

  const VideoBubblePreview({
    super.key,
    required this.videoUrl,
    required this.isMe,
    required this.onTap,
    this.isFullWidth = false,
    this.width,
    this.height,
    this.duration,
  });

  @override
  State<VideoBubblePreview> createState() => _VideoBubblePreviewState();
}

class _VideoBubblePreviewState extends State<VideoBubblePreview> {
  String? _thumbnailPath;
  bool _isGeneratingThumbnail = false;
  int? _duration;
  static final Map<String, String> _thumbnailCache = {};

  @override
  void initState() {
    super.initState();
    _duration = widget.duration;
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    if (_thumbnailCache.containsKey(widget.videoUrl)) {
      if (mounted) setState(() => _thumbnailPath = _thumbnailCache[widget.videoUrl]);
      if (_duration == null) _extractDuration();
      return;
    }

    if (mounted) setState(() => _isGeneratingThumbnail = true);

    try {
      final String? path = await VideoThumbnail.thumbnailFile(
        video: widget.videoUrl,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 400,
        quality: 75,
      );

      if (path != null) {
        _thumbnailCache[widget.videoUrl] = path;
        if (mounted) setState(() => _thumbnailPath = path);
      }
      
      if (_duration == null) _extractDuration();
    } catch (e) {
      debugPrint("Thumbnail generation error: $e");
    } finally {
      if (mounted) setState(() => _isGeneratingThumbnail = false);
    }
  }

  Future<void> _extractDuration() async {
    try {
      final controller = widget.videoUrl.startsWith('http')
          ? VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
          : VideoPlayerController.file(File(widget.videoUrl));
      
      await controller.initialize();
      if (mounted) {
        setState(() {
          _duration = controller.value.duration.inSeconds;
        });
      }
      await controller.dispose();
    } catch (e) {
      debugPrint("Duration extraction error: $e");
    }
  }

  String _formatDuration(int? seconds) {
    if (seconds == null || seconds <= 0) return "00:00";
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final double defaultWidth = widget.isFullWidth ? 1.sw : 240.w;
    final double defaultHeight = widget.isFullWidth ? 1.sh : 180.h;
    
    return Container(
      width: widget.width ?? defaultWidth,
      height: widget.height ?? defaultHeight,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(widget.isFullWidth ? 0 : 16.r),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Thumbnail or Placeholder
          if (_thumbnailPath != null)
            Image.file(
              File(_thumbnailPath!),
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            )
          else if (_isGeneratingThumbnail)
            const Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
            )
          else
            Container(
              color: Colors.black,
              child: Icon(Icons.videocam, color: Colors.white24, size: 40.sp),
            ),

          // Play Button Overlay (Simple white triangle)
          GestureDetector(
            onTap: widget.onTap,
            child: Container(
              padding: EdgeInsets.all(8.w),
              child: Icon(Icons.play_arrow, color: Colors.white, size: 48.sp),
            ),
          ),
          
          // Transparent clickable area for the whole thumbnail
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(onTap: widget.onTap),
            ),
          ),
          
          // Duration overlay on bottom left
          Positioned(
            bottom: 8.h,
            left: 10.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                _formatDuration(_duration),
                style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
