import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    return status.isGranted;
  }

  static Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    return status.isGranted;
  }

  static Future<bool> requestGalleryPermission() async {
    final photosGranted = await Permission.photos.request();
    final videosGranted = await Permission.videos.request();
    final storageGranted = await Permission.storage.request();

    if (photosGranted.isGranted ||
        videosGranted.isGranted ||
        storageGranted.isGranted) {
      return true;
    }
    if (photosGranted.isPermanentlyDenied ||
        videosGranted.isPermanentlyDenied ||
        storageGranted.isPermanentlyDenied) {
      await openAppSettings();
    }
    return false;
  }

  static Future<bool> handlePermanentDenial() async {
    return await openAppSettings();
  }
}
