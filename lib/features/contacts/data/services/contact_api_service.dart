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
    int page = 1,
    int? perPage,
  }) async {
    return await _apiClient.get(
      ApiConstants.contactsData,
      queryParameters: {
        if (search != null) 'search': search,
        'page': page,
        if (perPage != null) 'per_page': perPage,
      },
    );
  }

  // API 1.5 - Get Contact Create/Edit Metadata
  Future<Response> getContactMetadata() async {
    return await _apiClient.get('/vendor/contact/create');
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

  /**
   * BACKEND OPTIMIZATION NOTES (for Server-side):
   * 1. DB Indexes: Ensure 'phone_number', 'phone', 'vendor_id', and 'email' are indexed.
   * 2. Performance: Use DB transactions. Avoid N+1 queries by eager loading 'groups' and 'labels'.
   * 3. Response: Return 201 Created on success. Keep response payload minimal (only the new contact object).
   */

  // API 3 - Create Contact
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
    // Strict validation
    if (phoneNumber.isEmpty) throw Exception('Phone number is required');
    if (firstName.isEmpty) throw Exception('First name is required');

    final data = {
      'phone_number': phoneNumber,
      'phone': phoneNumber,
      'first_name': firstName,
      'name': '$firstName ${lastName ?? ''}'.trim(),
      if (lastName != null) 'last_name': lastName,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      'language_code': languageCode ?? 'en',
      'country': country,
      if (contactGroups != null) 'contact_groups': contactGroups,
      'whatsapp_opt_out': (whatsappOptOut == true) ? '1' : '0',
      'enable_ai_bot': (enableAiBot == true) ? '1' : '0',
      'enable_reply_bot': (enableReplyBot == true) ? '1' : '0',
      if (customInputFields != null) 'custom_input_fields': customInputFields,
    };

    debugPrint('🚀 Creating Contact with payload: $data');

    return await _apiClient.post(
      ApiConstants.createContact,
      data: data,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
  }

  // API 4 - Update Contact
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
    final data = {
      'first_name': firstName,
      'name': '$firstName ${lastName ?? ''}'.trim(),
      if (lastName != null) 'last_name': lastName,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      'language_code': languageCode ?? 'en',
      'country': country,
      if (contactGroups != null) 'contact_groups': contactGroups,
      'whatsapp_opt_out': (whatsappOptOut == true) ? '1' : '0',
      'enable_ai_bot': (enableAiBot == true) ? '1' : '0',
      'enable_reply_bot': (enableReplyBot == true) ? '1' : '0',
      if (customInputFields != null) 'custom_input_fields': customInputFields,
    };

    return await _apiClient.put(
      ApiConstants.updateContact(contactUid),
      data: data,
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
