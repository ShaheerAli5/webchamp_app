import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:photo_manager/photo_manager.dart';

final mediaPickerProvider = Provider((ref) => MediaPickerService());

class MediaPickerService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    return image != null ? File(image.path) : null;
  }

  Future<File?> pickVideo(ImageSource source) async {
    final XFile? video = await _picker.pickVideo(source: source);
    return video != null ? File(video.path) : null;
  }

  Future<List<File>> pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.media,
    );

    if (result != null) {
      return result.paths.map((path) => File(path!)).toList();
    }
    return [];
  }

  Future<List<AssetEntity>> fetchGalleryMedia() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtended();
    if (ps.isAuth) {
      List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.common,
      );
      if (albums.isNotEmpty) {
        return await albums[0].getAssetListRange(start: 0, end: 10000);
      }
    }
    return [];
  }
}
