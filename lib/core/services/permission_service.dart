import 'dart:io';
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
    if (Platform.isIOS) {
      // On iOS, only Permission.photos is meaningful.
      // Permission.videos and Permission.storage are Android-only; requesting
      // them on iOS always returns PermissionStatus.denied, which would make
      // this function incorrectly return false even when photo access is granted.
      //
      // iOS 14+ also introduced "Limited" access (user selects specific photos).
      // isGranted is false for limited access, so we must accept isLimited too;
      // the system photo picker works fine with limited access.
      final status = await Permission.photos.request();
      if (status.isGranted || status.isLimited) return true;
      if (status.isPermanentlyDenied) await openAppSettings();
      return false;
    }

    // Android: check photos (API 33+), videos (API 33+) and storage (< API 33)
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