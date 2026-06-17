import 'package:dio/dio.dart';
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
  }) async {
    // 🛡️ Create FormData
    final Map<String, dynamic> dataMap = {
      'contact_uid': contactUid,
      if (waId != null && waId.isNotEmpty) 'wa_id': waId,
      'media_type': mediaType,
      if (caption != null && caption.isNotEmpty) 'caption': caption,
      if (_csrfToken != null && _csrfToken!.isNotEmpty) '_token': _csrfToken,
    };

    if (uploadedFileName != null) {
      dataMap['uploaded_media_file_name'] = uploadedFileName;
    } else if (filePath != null) {
      final fileName = filePath.split('/').last;
      dataMap['uploaded_media_file_name'] = fileName;
      dataMap['file'] = await MultipartFile.fromFile(
        filePath,
        filename: fileName,
      );
    }

    final formData = FormData.fromMap(dataMap);

    return await _apiClient.post(
      ApiConstants.sendMedia,
      data: formData,
      options: Options(
        // 🛡️ Setting contentType to null allows Dio to automatically 
        // include the boundary from the FormData object.
        contentType: null,
        extra: {'stateless': true}, // 🛡️ Force stateless (no cookies)
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
        },
      ),
    );
  }

  Future<Response> uploadTempMedia(String filePath, String uploadItem) async {
    final fileName = filePath.split('/').last;
    
    // 🛡️ Determine MIME type based on extension with smart defaults
    String contentType = 'application/octet-stream';
    
    if (uploadItem.contains('audio')) {
      contentType = 'audio/aac';
    } else if (uploadItem.contains('image')) {
      contentType = 'image/jpeg';
    } else if (uploadItem.contains('video')) {
      contentType = 'video/mp4';
    }

    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg': case 'jpeg': contentType = 'image/jpeg'; break;
      case 'png': contentType = 'image/png'; break;
      case 'mp4': contentType = 'video/mp4'; break;
      case 'm4a': contentType = 'audio/mp4'; break;
      case 'mp3': contentType = 'audio/mpeg'; break;
      case 'ogg': contentType = 'audio/ogg'; break;
      case 'aac': contentType = 'audio/aac'; break;
      case 'amr': contentType = 'audio/amr'; break;
      case 'pdf': contentType = 'application/pdf'; break;
    }

    final formData = FormData.fromMap({
      'filepond': await MultipartFile.fromFile(
        filePath,
        filename: fileName,
        contentType: MediaType.parse(contentType),
      ),
      if (_csrfToken != null) '_token': _csrfToken,
    });
    return await _apiClient.post(
      ApiConstants.uploadTempMedia(uploadItem),
      data: formData,
      options: Options(
        contentType: null,
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
        },
      ),
    );
  }

  Future<Response> uploadMedia(String filePath, {required String contactUid, String type = 'audio'}) async {
    final fileName = filePath.split('/').last;
    final ext = fileName.split('.').last.toLowerCase();
    String contentType = 'audio/aac';
    if (ext == 'm4a' || ext == 'mp4') contentType = 'audio/mp4';
    if (ext == 'mp3') contentType = 'audio/mpeg';
    if (ext == 'ogg') contentType = 'audio/ogg';
    if (ext == 'amr') contentType = 'audio/amr';

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: fileName,
        contentType: MediaType.parse(contentType),
      ),
      'contact_uid': contactUid,
      'type': type,
      if (_csrfToken != null) '_token': _csrfToken,
    });
    return await _apiClient.post(
      ApiConstants.uploadAudio,
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
        if (_csrfToken != null) '_token': _csrfToken,
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
}
