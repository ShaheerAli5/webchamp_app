import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:webchamp_app/features/status/presentation/providers/media_picker_provider.dart';
import 'package:webchamp_app/features/status/presentation/screens/preview_screen.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  List<AssetEntity> _mediaList = [];
  List<AssetEntity> _selectedMedia = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  Future<void> _loadMedia() async {
    final media = await ref.read(mediaPickerProvider).fetchGalleryMedia();
    setState(() {
      _mediaList = media;
      _isLoading = false;
    });
  }

  void _toggleSelection(AssetEntity asset) {
    setState(() {
      if (_selectedMedia.contains(asset)) {
        _selectedMedia.remove(asset);
      } else {
        if (asset.type == AssetType.image && _selectedMedia.where((e) => e.type == AssetType.image).length >= 30) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Max 30 images allowed")));
           return;
        }
        if (asset.type == AssetType.video && _selectedMedia.where((e) => e.type == AssetType.video).length >= 10) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Max 10 videos allowed")));
           return;
        }
        _selectedMedia.add(asset);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Media"),
        actions: [
          if (_selectedMedia.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () async {
                if (_selectedMedia.isNotEmpty) {
                  final asset = _selectedMedia.first; // For now, single select logic
                  final file = await asset.file;
                  if (file != null && mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PreviewScreen(
                          file: file,
                          type: asset.type == AssetType.video ? 'video' : 'image',
                        ),
                      ),
                    );
                  }
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(2),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: _mediaList.length,
              itemBuilder: (context, index) {
                final asset = _mediaList[index];
                return GestureDetector(
                  onTap: () => _toggleSelection(asset),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: AssetThumbnail(asset: asset),
                      ),
                      if (asset.type == AssetType.video)
                        Positioned(
                          bottom: 5,
                          right: 5,
                          child: Text(
                            _formatDuration(asset.videoDuration),
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      if (_selectedMedia.contains(asset))
                        Container(
                          color: Colors.black26,
                          child: const Center(
                            child: Icon(Icons.check_circle, color: Colors.green, size: 30),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}

class AssetThumbnail extends StatelessWidget {
  final AssetEntity asset;
  const AssetThumbnail({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: asset.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
          return Image.memory(snapshot.data!, fit: BoxFit.cover);
        }
        return Container(color: Colors.grey[300]);
      },
    );
  }
}
