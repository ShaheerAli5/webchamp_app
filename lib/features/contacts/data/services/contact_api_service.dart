import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:http_parser/http_parser.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';

class ContactApiService {
  final ApiClient _apiClient;
  String? _csrfToken;

  ContactApiService(this._apiClient);

  int get cacheCount => _apiClient.cacheCount;

  void setCsrfToken(String token) {
    _csrfToken = token;
  }

  void clear() {
    _csrfToken = null;
  }

  Future<Response> getContacts({
    String? search,
    int page = 1,
    int? perPage,
    bool refresh = false,
    CancelToken? cancelToken,
  }) async {
    return await _apiClient.get(
      ApiConstants.contactsData,
      cancelToken: cancelToken,
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        'page': page,
        if (perPage != null) ...{
          'per_page': perPage,
          'perPage': perPage,
          'limit': perPage,
          'page_size': perPage,
          'count': perPage,
          'size': perPage,
        },
      },
      options: Options(
        extra: {
          'useCache': true,
          'refresh': refresh,
          'cacheDuration': 300000, // 5 minutes
        },
      ),
    );
  }

  Future<Response> getContactMetadata({bool refresh = false}) async {
    return await _apiClient.get(
      ApiConstants.contact,
      options: Options(
        extra: {
          'useCache': true, 
          'refresh': refresh,
          'cacheDuration': 3600000, // 1 hour
        },
      ),
    );
  }

  Future<Response> getContact({
    String? phoneNumber,
    String? email,
    bool refresh = false,
  }) async {
    return await _apiClient.get(
      ApiConstants.contact,
      queryParameters: {
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (email != null) 'email': email,
      },
      options: Options(
        extra: {
          'useCache': true,
          'refresh': refresh,
        },
      ),
    );
  }

  Future<Response> createContact({
    required String phoneNumber,
    required String firstName,
    String? lastName,
    String? email,
    String? address,
    String? languageCode,
    required dynamic country,
    List<int>? contactGroups,
    bool? whatsappOptOut,
    bool? enableAiBot,
    bool? enableReplyBot,
    Map<String, dynamic>? customInputFields,
  }) async {
    return await _apiClient.post(
      ApiConstants.createContact,
      data: {
        'phone_number': phoneNumber,
        'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (email != null) 'email': email,
        if (address != null) 'address': address,
        if (languageCode != null) 'language_code': languageCode,
        'country': country,
        if (contactGroups != null) 'contact_groups': contactGroups,
        if (whatsappOptOut != null) 'whatsapp_opt_out': whatsappOptOut ? 1 : 0,
        if (enableAiBot != null) 'enable_ai_bot': enableAiBot ? 1 : 0,
        if (enableReplyBot != null) 'enable_reply_bot': enableReplyBot ? 1 : 0,
        if (customInputFields != null) ...customInputFields,
      },
    );
  }

  Future<Response> updateContact(
    String contactUid, {
    required String firstName,
    String? lastName,
    String? email,
    String? address,
    String? languageCode,
    required dynamic country,
    List<int>? contactGroups,
    bool? whatsappOptOut,
    bool? enableAiBot,
    bool? enableReplyBot,
    Map<String, dynamic>? customInputFields,
  }) async {
    return await _apiClient.post(
      ApiConstants.updateContact(contactUid),
      data: {
        'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (email != null) 'email': email,
        if (address != null) 'address': address,
        if (languageCode != null) 'language_code': languageCode,
        'country': country,
        if (contactGroups != null) 'contact_groups': contactGroups,
        if (whatsappOptOut != null) 'whatsapp_opt_out': whatsappOptOut ? 1 : 0,
        if (enableAiBot != null) 'enable_ai_bot': enableAiBot ? 1 : 0,
        if (enableReplyBot != null) 'enable_reply_bot': enableReplyBot ? 1 : 0,
        if (customInputFields != null) ...customInputFields,
      },
    );
  }

  Future<Response> deleteContact(String phoneNumber) async {
    return await _apiClient.post(
      ApiConstants.deleteContact(phoneNumber),
    );
  }

  Future<Response> assignTeamMember({
    required String phoneNumber,
    required String usernameOrEmail,
  }) async {
    return await _apiClient.post(
      ApiConstants.assignTeamMember,
      data: {
        'phone_number': phoneNumber,
        'username_or_email': usernameOrEmail,
      },
    );
  }

  Future<Response> getChatHistory(String contactUid, {bool refresh = false, CancelToken? cancelToken}) async {
    return await _apiClient.get(
      ApiConstants.chatHistory(contactUid),
      cancelToken: cancelToken,
      options: Options(
        extra: {
          'useCache': true,
          'refresh': refresh,
          'cacheDuration': 30000, // 30 seconds
        },
      ),
    );
  }

  Future<Response> getContactChatBoxData(String contactUid, {bool refresh = false, CancelToken? cancelToken}) async {
    return await _apiClient.get(
      ApiConstants.contactChatBoxData(contactUid),
      cancelToken: cancelToken,
      options: Options(
        extra: {
          'useCache': true,
          'refresh': refresh,
          'cacheDuration': 60000, // 1 minute
        },
      ),
    );
  }

  Future<Response> getUnreadCount() async {
    return await _apiClient.get(ApiConstants.unreadCount);
  }

  Future<Response> markAsRead({required String contactUid, String? messageId}) async {
    return await _apiClient.post(
      ApiConstants.markRead,
      data: {
        'contact_uid': contactUid,
        if (messageId != null) 'message_id': messageId,
      },
    );
  }

  Future<Response> sendMessage({
    required String contactUid,
    required String message,
    String? waId,
    String? replyToMessageId,
  }) async {
    return await _apiClient.post(
      ApiConstants.sendMessage,
      data: {
        'contact_uid': contactUid,
        'message_body': message,
        if (waId != null) 'wa_id': waId,
        if (replyToMessageId != null) 'reply_to_message_id': replyToMessageId,
        if (_csrfToken != null && _csrfToken!.isNotEmpty) '_token': _csrfToken,
      },
      options: Options(
        contentType: Headers.jsonContentType,
        extra: {'stateless': true},
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
          'Api-Request-Signature': 'mobile-app-request',
        },
      ),
    );
  }

  Future<Response> sendMedia({
    required String contactUid,
    String? filePath,
    required String mediaType,
    String? uploadedFileName,
    String? waId,
    String? caption,
    bool isRecordedAudio = false,
  }) async {
    // 🛡️ Prepare data map
    final Map<String, dynamic> dataMap = {
      'contact_uid': contactUid,
      if (waId != null && waId.isNotEmpty) 'wa_id': waId,
      'media_type': mediaType,
      if (caption != null && caption.isNotEmpty) 'caption': caption,
      if (isRecordedAudio) 'is_recorded_audio': true,
      if (_csrfToken != null && _csrfToken!.isNotEmpty) '_token': _csrfToken,
    };

    // Case 1: Finalize upload using a previously uploaded temporary file name
    if (uploadedFileName != null) {
      dataMap['uploaded_media_file_name'] = uploadedFileName;
      
      debugPrint('📤 [API] Finalizing media send with temp file: $uploadedFileName');
      
      return await _apiClient.post(
        ApiConstants.sendMedia,
        data: dataMap,
        options: Options(
          contentType: Headers.jsonContentType, // Switch to JSON for finalizing
          extra: {'stateless': true},
          headers: {
            'Accept': 'application/json',
            'X-Requested-With': 'XMLHttpRequest',
            'Api-Request-Signature': 'mobile-app-request',
          },
        ),
      );
    } 

    // Case 2: Direct upload (Fallback/Legacy)
    if (filePath != null) {
      final fileName = filePath.split(RegExp(r'[/\\]')).last;
      final String ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
      
      String contentType = 'application/octet-stream';
      String safeFileName = fileName;

      if (mediaType == 'audio' || mediaType == 'voice') {
        contentType = 'audio/mp4';
      } else if (mediaType == 'image') {
        contentType = 'image/jpeg';
      } else if (mediaType == 'video') {
        contentType = 'video/mp4';
        if (ext != 'mp4' && ext != '3gp') {
          safeFileName = '${fileName.replaceAll('.$ext', '')}.mp4';
        }
      }
      
      dataMap['uploaded_media_file_name'] = safeFileName;
      
      dataMap['file'] = await MultipartFile.fromFile(
        filePath,
        filename: safeFileName,
        contentType: MediaType.parse(contentType),
      );
    }

    final formData = FormData.fromMap(dataMap);

    debugPrint('📤 [API] Sending media via FormData (direct upload)');

    return await _apiClient.post(
      ApiConstants.sendMedia,
      data: formData,
      options: Options(
        contentType: null, // Let Dio handle boundary
        extra: {'stateless': true},
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
        },
      ),
    );
  }

  Future<Response> uploadTempMedia(String filePath, String uploadItem, {ProgressCallback? onSendProgress}) async {
    final fileName = filePath.split(RegExp(r'[/\\]')).last;
    final bool isVideo = uploadItem.contains('video');
    final bool isAudio = uploadItem.contains('audio');
    
    // 🛡️ Robust extension extraction
    final String ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
    
    // 🛡️ Determine MIME type and safe filename
    String contentType = 'application/octet-stream';
    String safeFileName = fileName;

    if (isVideo) {
      contentType = 'video/mp4';
      // 🛡️ Force .mp4 extension in the filename sent to server to trick extension-based validation
      if (ext != 'mp4' && ext != '3gp' && ext != '3gpp') {
        safeFileName = '${fileName.replaceAll('.$ext', '')}.mp4';
      }
      if (ext == '3gp' || ext == '3gpp') {
        contentType = 'video/3gpp';
      }
    } else if (isAudio) {
      contentType = 'audio/mp4';
      if (ext == 'mp3') contentType = 'audio/mpeg';
      else if (ext == 'ogg') contentType = 'audio/ogg';
      else if (ext == 'amr') contentType = 'audio/amr';
      else if (ext == 'aac') contentType = 'audio/aac';
    } else if (uploadItem.contains('image')) {
      contentType = 'image/jpeg';
      if (ext == 'png') contentType = 'image/png';
      else if (ext == 'gif') contentType = 'image/gif';
    } else if (uploadItem.contains('sticker')) {
      contentType = 'image/webp';
    } else if (uploadItem.contains('document')) {
      // 🛡️ Document MIME types
      switch (ext) {
        case 'pdf': contentType = 'application/pdf'; break;
        case 'docx': contentType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'; break;
        case 'doc': contentType = 'application/msword'; break;
        case 'xlsx': contentType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'; break;
        case 'xls': contentType = 'application/vnd.ms-excel'; break;
        case 'pptx': contentType = 'application/vnd.openxmlformats-officedocument.presentationml.presentation'; break;
        case 'ppt': contentType = 'application/vnd.ms-powerpoint'; break;
        case 'txt': contentType = 'text/plain'; break;
        case 'zip': contentType = 'application/zip'; break;
        default: contentType = 'application/octet-stream';
      }
    }

    final formData = FormData.fromMap({
      'filepond': await MultipartFile.fromFile(
        filePath,
        filename: safeFileName,
        contentType: MediaType.parse(contentType),
      ),
      if (_csrfToken != null && _csrfToken!.isNotEmpty) '_token': _csrfToken,
    });

    debugPrint('📤 [API] uploadTempMedia: $fileName as $safeFileName ($contentType) -> $uploadItem');

    return await _apiClient.post(
      ApiConstants.uploadTempMedia(uploadItem),
      data: formData,
      onSendProgress: onSendProgress,
      options: Options(
        contentType: null,
        headers: {
          'Accept': '*/*', // Permissive Accept header for Filepond
          'X-Requested-With': 'XMLHttpRequest',
          'Api-Request-Signature': 'mobile-app-request',
          if (_csrfToken != null && _csrfToken!.isNotEmpty) 'X-CSRF-TOKEN': _csrfToken,
        },
      ),
    );
  }


  Future<Response> uploadMedia(String filePath, {required String contactUid, String type = 'audio'}) async {
    final fileName = filePath.split(RegExp(r'[/\\]')).last;
    final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
    
    String contentType = (type == 'video') ? 'video/mp4' : 'audio/mp4';
    String safeFileName = fileName;

    if (type == 'video') {
      if (ext == '3gp' || ext == '3gpp') {
        contentType = 'video/3gpp';
      } else {
        contentType = 'video/mp4';
        if (ext != 'mp4') {
          safeFileName = '${fileName.replaceAll('.$ext', '')}.mp4';
        }
      }
    } else {
      if (ext == 'mp3') contentType = 'audio/mpeg';
      else if (ext == 'ogg') contentType = 'audio/ogg';
      else if (ext == 'amr') contentType = 'audio/amr';
      else if (ext == 'aac') contentType = 'audio/aac';
    }

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: safeFileName,
        contentType: MediaType.parse(contentType),
      ),
      'contact_uid': contactUid,
      'type': type,
    });
    return await _apiClient.post(
      ApiConstants.uploadTempMedia(type == 'video' ? 'whatsapp_video' : 'whatsapp_audio'),
      data: formData,
    );
  }

  Future<Response> sendTemplate({
    required String contactUid,
    required String templateName,
    required String languageCode,
  }) async {
    return await _apiClient.post(
      ApiConstants.sendTemplate,
      data: {
        'contact_uid': contactUid,
        'template_name': templateName,
        'language_code': languageCode,
      },
    );
  }

  Future<Response> createLabel({
    required String title,
    required String textColor,
    required String bgColor,
  }) async {
    return await _apiClient.post(
      ApiConstants.createLabel,
      data: {
        'title': title,
        'text_color': textColor,
        'bg_color': bgColor,
      },
    );
  }

  Future<Response> updateLabel({
    required String labelUid,
    required String title,
    required String textColor,
    required String bgColor,
  }) async {
    return await _apiClient.post(
      ApiConstants.updateLabel,
      data: {
        'label_uid': labelUid,
        'title': title,
        'text_color': textColor,
        'bg_color': bgColor,
      },
    );
  }

  Future<Response> deleteLabel(String labelUid) async {
    return await _apiClient.post(
      ApiConstants.deleteLabel(labelUid),
    );
  }

  Future<Response> assignLabels({
    required String contactUid,
    required List<String> labels,
  }) async {
    return await _apiClient.post(
      ApiConstants.assignLabels,
      data: {
        'contact_uid': contactUid,
        'labels': labels,
      },
      options: Options(
        extra: {'stateless': true},
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  // --- Contact Group Management ---

  Future<Response> getContactGroups({bool refresh = false}) async {
    return await _apiClient.get(
      ApiConstants.contactGroupsList,
      options: Options(
        extra: {
          'useCache': true,
          'refresh': refresh,
        },
      ),
    );
  }

  Future<Response> createContactGroup({
    required String title,
    String? description,
  }) async {
    return await _apiClient.post(
      ApiConstants.createContactGroup,
      data: {
        'title': title,
        if (description != null) 'description': description,
      },
    );
  }

  Future<Response> updateContactGroup(
    String groupUid, {
    required String title,
    String? description,
  }) async {
    return await _apiClient.post(
      ApiConstants.updateContactGroup(groupUid),
      data: {
        'title': title,
        if (description != null) 'description': description,
      },
    );
  }

  Future<Response> deleteContactGroup(String groupUid) async {
    return await _apiClient.post(
      ApiConstants.deleteContactGroup(groupUid),
    );
  }

  Future<Response> assignContactsToGroup({
    required List<String> contactUids,
    required List<String> groupUids,
  }) async {
    return await _apiClient.post(
      ApiConstants.assignContactsToGroup,
      data: {
        'contact_uids': contactUids,
        'group_uids': groupUids,
      },
    );
  }

  Future<Response> removeContactFromGroup({
    required String contactUid,
    required String groupUid,
  }) async {
    return await _apiClient.post(
      ApiConstants.removeContactFromGroup,
      data: {
        'contact_uid': contactUid,
        'group_uid': groupUid,
      },
    );
  }
}
