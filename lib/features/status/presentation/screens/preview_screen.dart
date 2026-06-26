import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webchamp_app/features/status/presentation/providers/status_provider.dart';

class PreviewScreen extends ConsumerStatefulWidget {
  final File file;
  final String type; // 'image' or 'video'

  const PreviewScreen({super.key, required this.file, required this.type});

  @override
  ConsumerState<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends ConsumerState<PreviewScreen> {
  late VideoPlayerController _videoController;
  final TextEditingController _captionController = TextEditingController();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.type == 'video') {
      _videoController = VideoPlayerController.file(widget.file)
        ..initialize().then((_) {
          setState(() {});
          _videoController.play();
        });
    }
  }

  @override
  void dispose() {
    if (widget.type == 'video') {
      _videoController.dispose();
    }
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _upload() async {
    setState(() => _isUploading = true);
    try {
      final api = ref.read(statusApiServiceProvider);
      await api.uploadStatus(
        file: widget.file,
        type: widget.type,
        caption: _captionController.text,
        onProgress: (sent, total) {
          ref.read(uploadProgressProvider.notifier).state = sent / total;
        },
      );
      if (mounted) {
        Navigator.pop(context); // Back to gallery/home
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Status Uploaded!")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(uploadProgressProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
           IconButton(icon: const Icon(Icons.crop), onPressed: () {/* Implement Crop */}),
           IconButton(icon: const Icon(Icons.text_fields), onPressed: () {/* Implement Text */}),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: widget.type == 'image'
                ? Image.file(widget.file)
                : _videoController.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: _videoController.value.aspectRatio,
                        child: VideoPlayer(_videoController),
                      )
                    : const CircularProgressIndicator(),
          ),
          if (_isUploading)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(value: progress),
                  const SizedBox(height: 10),
                  Text("${(progress * 100).toInt()}%", style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
          Positioned(
            bottom: 20,
            left: 10,
            right: 10,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _captionController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Add a caption...",
                      hintStyle: const TextStyle(color: Colors.white70),
                      fillColor: Colors.black45,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor: Colors.green,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _isUploading ? null : _upload,
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
