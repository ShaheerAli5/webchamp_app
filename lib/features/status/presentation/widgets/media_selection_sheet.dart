import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:webchamp_app/features/status/presentation/screens/gallery_screen.dart';

class MediaSelectionSheet extends StatelessWidget {
  const MediaSelectionSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const MediaSelectionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text("Camera"),
            onTap: () {
              Navigator.pop(context);
              // Handle Camera
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text("Gallery"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GalleryScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.videocam),
            title: const Text("Videos"),
            onTap: () {
              Navigator.pop(context);
              // Handle Videos specifically or use Gallery
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_copy),
            title: const Text("Files"),
            onTap: () {
              Navigator.pop(context);
              // Handle File Picker
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.close, color: Colors.red),
            title: const Text("Cancel"),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
