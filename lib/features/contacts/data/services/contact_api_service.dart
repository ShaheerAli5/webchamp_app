import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import 'package:flutter/foundation.dart';

class ContactApiService {
  final ApiClient _apiClient;

  ContactApiService(this._apiClient);

  String? _csrfToken;

  // Call this once after login or before first POST
  Future<void> fetchCsrfToken([String? contactUid]) async {
    try {
      // If no UID is provided, we try to use a default or first contact if available
      // but ideally we should always pass a context-relevant UID.
      if (contactUid == null) {
        debugPrint('⚠️ fetchCsrfToken called without contactUid');
        return;
      }

      final response = await _apiClient.get(
        ApiConstants.chatHistory(contactUid),
        options: Options(responseType: ResponseType.plain),
      );
      if (response.data is String) {
        final tokenRegex = RegExp(r'"csrf_token"\s*:\s*"([^"]+)"');
        final match = tokenRegex.firstMatch(response.data as String);
        if (match != null) {
          setCsrfToken(match.group(1)!);
        }
      }
    } catch (e) {
      debugPrint('❌ Failed to fetch CSRF token: $e');
    }
  }

  void setCsrfToken(String token) {
    _csrfToken = token;
    debugPrint('✅ CSRF token updated: $token');
  }

  // API 1 - Get All Contacts
  Future<Response> getContacts({
    String? search,
    int? perPage,
    int? page,
  }) async {
    return await _apiClient.get(
      ApiConstants.contactsData,
      queryParameters: {
        if (search != null) 'search': search,
        'per_page': perPage ?? 100,
        if (page != null) 'page': page,
      },
    );
  }

  // API 2 - Get Single Contact
  Future<Response> getContact({
    String? phoneNumber,
    String? email,
  }) async {
    return await _apiClient.get(
      ApiConstants.contact,
      queryParameters: {
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (email != null) 'email': email,
      },
    );
  }

  // API 3 - Create Contact
  Future<Response> createContact({
    required String phoneNumber,
    String? firstName,
    String? lastName,
    String? email,
    String? languageCode,
    String? country,
    bool? whatsappOptOut,
    bool? enableReplyBot,
    String? otherInfo,
  }) async {
    final data = {
      'phone_number': phoneNumber,
      if (firstName != null && firstName.isNotEmpty) 'first_name': firstName,
      if (lastName != null && lastName.isNotEmpty) 'last_name': lastName,
      if (email != null && email.isNotEmpty) 'email': email,
      if (languageCode != null && languageCode.isNotEmpty)
        'language_code': languageCode,
      if (country != null && country.isNotEmpty) 'country': country,
      if (whatsappOptOut != null) 'whatsapp_opt_out': whatsappOptOut ? '1' : '0',
      if (enableReplyBot != null) 'disable_reply_bot': enableReplyBot ? '0' : '1',
      if (otherInfo != null && otherInfo.isNotEmpty) 'other_info': otherInfo,
    };

    return await _apiClient.post(
      ApiConstants.createContact,
      data: data,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
  }

  // API 4 - Update Contact
  Future<Response> updateContact(
    String phoneNumber, {
    String? firstName,
    String? lastName,
    String? email,
    String? languageCode,
    String? country,
  }) async {
    return await _apiClient.post(
      ApiConstants.updateContact(phoneNumber),
      data: {
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (email != null) 'email': email,
        if (languageCode != null) 'language_code': languageCode,
        if (country != null) 'country': country,
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
  }

  // API 4.1 - Delete Contact
  Future<Response> deleteContact(String phoneNumber) async {
    return await _apiClient.get(
      ApiConstants.deleteContact(phoneNumber),
    );
  }

  // API 5 - Assign Team Member
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
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
  }

  // ✅ FIXED — fetches actual chat messages
  Future<Response> getChatHistory(String contactUid) async {
    return await _apiClient.get(
      ApiConstants.chatHistory(contactUid),
    );
  }

  // ✅ KEPT — still used for labels/team members only
  Future<Response> getContactChatBoxData(String contactUid) async {
    return await _apiClient.get(
      ApiConstants.contactChatBoxData(contactUid),
    );
  }

  // ✅ NEW — unread count for badge
  Future<Response> getUnreadCount() async {
    return await _apiClient.get(ApiConstants.unreadCount);
  }

  // ✅ NEW — clear chat history
  Future<Response> clearChatHistory(String contactUid) async {
    return await _apiClient.post(
      ApiConstants.clearChatHistory(contactUid),
    );
  }


  // API 7 - Create Label
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
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
  }

  // API 8 - Update Label
  Future<Response> updateLabel({
    required String labelUid,
    required String title,
    required String textColor,
    required String bgColor,
  }) async {
    return await _apiClient.post(
      ApiConstants.updateLabel,
      data: {
        'labelUid': labelUid,
        'title': title,
        'text_color': textColor,
        'bg_color': bgColor,
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
  }

  // API 9 - Delete Label
  Future<Response> deleteLabel(String labelUid) async {
    return await _apiClient.post(
      ApiConstants.deleteLabel(labelUid),
    );
  }

  // API 10 - Assign Labels to Contact
  Future<Response> assignLabels({
    required String contactUid,
    required List<String> contactLabels,
  }) async {
    return await _apiClient.post(
      ApiConstants.assignLabels,
      data: {
        'contactUid': contactUid,
        'contact_labels': contactLabels,
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
  }

  // API 11 - Send Message
  Future<Response> sendMessage({
    required String contactUid,
    required String message,
  }) async {
    if (_csrfToken == null) await fetchCsrfToken(contactUid);

    return await _apiClient.post(
      ApiConstants.sendMessage,
      data: {
        'contact_uid': contactUid,
        'message_body': message,
        if (_csrfToken != null) '_token': _csrfToken,
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
  }

  // API 12 - Send Template
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
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
  }

  // API 13 - Send Media
  Future<Response> sendMedia({
    required String contactUid,
    required String fileName,
    String mediaType = 'audio',
    bool isRecordedAudio = false,
  }) async {
    if (_csrfToken == null) await fetchCsrfToken(contactUid);

    return await _apiClient.post(
      ApiConstants.sendMedia,
      data: {
        'contact_uid': contactUid,
        'media_type': mediaType,
        'uploaded_media_file_name': fileName,
        if (mediaType == 'audio') 'is_recorded_audio': isRecordedAudio ? '1' : '0',
        if (_csrfToken != null) '_token': _csrfToken,
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
  }

  // API 14 - Upload Media
  Future<Response> uploadMedia(String filePath, {required String contactUid, String type = 'audio'}) async {
    if (_csrfToken == null) await fetchCsrfToken(contactUid);

    final file = await MultipartFile.fromFile(
      filePath,
      filename: filePath.split('/').last,
    );

    final formData = FormData.fromMap({
      'filepond': file,
      if (_csrfToken != null) '_token': _csrfToken,
    });

    String endpoint = ApiConstants.uploadAudio;
    if (type == 'image') {
      endpoint = '/media/upload-temp-media/whatsapp_image';
    } else if (type == 'video') {
      endpoint = '/media/upload-temp-media/whatsapp_video';
    } else if (type == 'document') {
      endpoint = '/media/upload-temp-media/whatsapp_document';
    }

    return await _apiClient.post(
      endpoint,
      data: formData,
    );
  }
}
