import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';
import 'package:webchamp_app/core/network/api_constants.dart';

class StatusApiService {
  final Dio _dio;

  StatusApiService(this._dio);

  Future<Response> uploadStatus({
    required File file,
    required String type, // 'image' or 'video'
    String? caption,
    Function(int, int)? onProgress,
  }) async {
    File uploadFile = file;

    // Compression
    if (type == 'image') {
      final compressed = await _compressImage(file);
      if (compressed != null) uploadFile = compressed;
    } else if (type == 'video') {
      final stat = await file.length();
      if (stat > 50 * 1024 * 1024) { // > 50MB
        final mediaInfo = await VideoCompress.compressVideo(
          file.path,
          quality: VideoQuality.MediumQuality,
          deleteOrigin: false,
        );
        if (mediaInfo?.file != null) uploadFile = mediaInfo!.file!;
      }
    }

    String fileName = uploadFile.path.split('/').last;
    FormData formData = FormData.fromMap({
      "media": await MultipartFile.fromFile(uploadFile.path, filename: fileName),
      "type": type,
      "caption": caption ?? "",
    });

    return await _dio.post(
      ApiConstants.uploadStatus,
      data: formData,
      onSendProgress: onProgress,
    );
  }

  Future<File?> _compressImage(File file) async {
    final filePath = file.absolute.path;
    final lastIndex = filePath.lastIndexOf(RegExp(r'.png|.jp'));
    final splitted = filePath.substring(0, (lastIndex));
    final outPath = "${splitted}_out${filePath.substring(lastIndex)}";
    
    return await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      outPath,
      quality: 70,
    );
  }
}
