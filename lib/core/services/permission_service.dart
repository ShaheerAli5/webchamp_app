import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> requestGalleryPermission() async {
    if (await Permission.photos.request().isGranted || 
        await Permission.videos.request().isGranted ||
        await Permission.storage.request().isGranted) {
      return true;
    }
    return false;
  }

  static Future<bool> handlePermanentDenial() async {
    return await openAppSettings();
  }
}
