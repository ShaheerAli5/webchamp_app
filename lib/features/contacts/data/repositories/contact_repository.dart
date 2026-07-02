import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/utils/helpers.dart';
import '../services/contact_api_service.dart';

class ContactRepository {
  final ContactApiService _apiService;

  ContactRepository(this._apiService);

  int get cacheCount => _apiService.cacheCount;

  void clear() {
    _apiService.clear();
  }

  Future<dynamic> getContacts({
    String? search,
    int page = 1,
    int? perPage,
    bool refresh = false,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _apiService.getContacts(
        search: search,
        page: page,
        perPage: perPage,
        refresh: refresh,
        cancelToken: cancelToken,
      );

      debugPrint('--- CONTACTS API DEBUG ---');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Base URL: ${ApiConstants.baseUrl}');
      debugPrint('Final URL: ${response.realUri}');
      
      // 🛡️ Safe logging: catch potential UTF-16 errors during debug printing
      try {
        String dataStr = response.data.toString();
        debugPrint('Response Data: ${dataStr.length > 2000 ? '${dataStr.substring(0, 2000)}...' : dataStr}');
      } catch (e) {
        debugPrint('Response Data: [Error stringifying data, likely malformed UTF-16]');
      }
      debugPrint('--------------------------');

      return Helpers.sanitizeData(response.data);
    } on DioException catch (e) {
      debugPrint('❌ CONTACTS API ERROR: ${e.message}');
      debugPrint('Error Type: ${e.type}');
      
      if (e.error is SocketException) {
        debugPrint('DNS/Network Error: Failed to resolve ${ApiConstants.baseUrl}. Please check device internet.');
        throw Exception('Network error: Cannot reach server. Please check your internet connection.');
      }

      debugPrint('Error Response: ${e.response?.data}');
      throw Exception(_extractError(e));
    }
  }

  Future<dynamic> getContactMetadata({bool refresh = false}) async {
    try {
      final response = await _apiService.getContactMetadata(refresh: refresh);
      debugPrint('--- METADATA API DEBUG ---');
      debugPrint('URL: ${response.realUri}');
      debugPrint('Status: ${response.statusCode}');
      return Helpers.sanitizeData(response.data);
    } on DioException catch (e) {
      debugPrint('❌ METADATA API ERROR: ${e.message}');
      throw Exception(_extractError(e));
    }
  }

  Future<dynamic> getContact({
    String? phoneNumber,
    String? email,
    bool refresh = false,
  }) async {
    try {
      final response = await _apiService.getContact(
        phoneNumber: phoneNumber,
        email: email,
        refresh: refresh,
      );
      return Helpers.sanitizeData(response.data);
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<dynamic> createContact({
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
    try {
      final response = await _apiService.createContact(
        phoneNumber: phoneNumber,
        firstName: firstName,
        lastName: lastName,
        email: email,
        address: address,
        languageCode: languageCode,
        country: country,
        contactGroups: contactGroups,
        whatsappOptOut: whatsappOptOut,
        enableAiBot: enableAiBot,
        enableReplyBot: enableReplyBot,
        customInputFields: customInputFields,
      );
      
      final data = Helpers.sanitizeData(response.data);
      if (data is Map && data['result'] == 'failed') {
        throw Exception(data['message'] ?? 'Failed to create contact');
      }
      
      return data;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<dynamic> updateContact(
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
    try {
      final response = await _apiService.updateContact(
        contactUid,
        firstName: firstName,
        lastName: lastName,
        email: email,
        address: address,
        languageCode: languageCode,
        country: country,
        contactGroups: contactGroups,
        whatsappOptOut: whatsappOptOut,
        enableAiBot: enableAiBot,
        enableReplyBot: enableReplyBot,
        customInputFields: customInputFields,
      );
      
      final data = Helpers.sanitizeData(response.data);
      if (data is Map && data['result'] == 'failed') {
        throw Exception(data['message'] ?? 'Failed to update contact');
      }
      
      return data;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<dynamic> deleteContact(String phoneNumber) async {
    try {
      final response = await _apiService.deleteContact(phoneNumber);
      final data = Helpers.sanitizeData(response.data);
      if (data is Map && data['result'] == 'failed') {
        throw Exception(data['message'] ?? 'Failed to delete contact');
      }
      return data;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<dynamic> assignTeamMember({
    required String phoneNumber,
    required String usernameOrEmail,
  }) async {
    try {
      final response = await _apiService.assignTeamMember(
        phoneNumber: phoneNumber,
        usernameOrEmail: usernameOrEmail,
      );
      return Helpers.sanitizeData(response.data);
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<dynamic> getChatHistory(String contactUid, {int page = 1, bool refresh = false, CancelToken? cancelToken}) async {
    try {
      final response = await _apiService.getChatHistory(contactUid, page: page, refresh: refresh, cancelToken: cancelToken);

      // 1. If response is already a Map (Dio auto-parsed JSON)
      if (response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        // Automatically update CSRF token if present in JSON
        final token = data['csrf_token'] ?? data['data']?['csrf_token'];
        if (token != null) {
          _apiService.setCsrfToken(token.toString());
        }
        return Helpers.sanitizeData(data);
      }

      // 2. If response is a List (Dio auto-parsed JSON)
      if (response.data is List) {
        return Helpers.sanitizeData(response.data);
      }

      // 3. Fallback: If response is a String (could be JSON string or legacy HTML)
      if (response.data is String) {
        final dataStr = response.data as String;

        // Try parsing as JSON first
        try {
          final decoded = jsonDecode(dataStr);
          if (decoded is Map) {
            final token = decoded['csrf_token'] ?? decoded['data']?['csrf_token'];
            if (token != null) {
              _apiService.setCsrfToken(token.toString());
            }
            return Helpers.sanitizeData(decoded);
          }
          if (decoded is List) return Helpers.sanitizeData(decoded);
        } catch (_) {
          // Not valid JSON, proceed to HTML extraction (legacy)
        }

        // Legacy support for web-view HTML extraction if endpoint still returns HTML
        final result = _extractMessagesFromHtml(dataStr);
        if (result['csrf_token'] != null) {
          _apiService.setCsrfToken(result['csrf_token']);
        }
        return Helpers.sanitizeData(result);
      }

      return {};
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Map<String, dynamic> _extractMessagesFromHtml(String html) {
    try {
      // 1. Look for the JSON block in comments or JS variables
      // We look for the pattern and capture everything until the end of that specific line
      final pattern = RegExp(
        r'whatsappMessageLogs:\s*(\{.*\})',
        multiLine: true,
      );

      final match = pattern.firstMatch(html);
      String? rawJson = match?.group(1);

      // Clean up if it captured a trailing comma or semicolon from the JS
      if (rawJson != null) {
        rawJson = rawJson.trim();
        if (rawJson.endsWith(',') || rawJson.endsWith(';')) {
          rawJson = rawJson.substring(0, rawJson.length - 1).trim();
        }
      }

      String? csrfToken;
      final csrfRegex = RegExp(r'''csrf_token["\s:]+(["'])([a-zA-Z0-9]+)\1''');
      final csrfMatch = csrfRegex.firstMatch(html);
      csrfToken = csrfMatch?.group(2);

      if (csrfToken != null) {
        debugPrint('✅ CSRF token from chat HTML: $csrfToken');
      }

      if (rawJson != null) {
        try {
          final decoded = jsonDecode(rawJson);
          if (decoded is Map) {
            final messageList = decoded.values.whereType<Map>().toList();
            messageList.sort((a, b) {
              final aTime = (a['created_at'] ?? a['messaged_at'] ?? '').toString();
              final bTime = (b['created_at'] ?? b['messaged_at'] ?? '').toString();
              return bTime.compareTo(aTime);
            });
            debugPrint('✅ Extracted ${messageList.length} messages from HTML');
            return {
              'messages': messageList,
              if (csrfToken != null) 'csrf_token': csrfToken
            };
          }
        } catch (e) {
          debugPrint('❌ Failed to decode extracted JSON: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Error during HTML extraction: $e');
    }
    return {'messages': []};
  }

  Future<dynamic> getContactChatBoxData(String contactUid, {bool refresh = false, CancelToken? cancelToken}) async {
    try {
      final response = await _apiService.getContactChatBoxData(contactUid, refresh: refresh, cancelToken: cancelToken);
      return Helpers.sanitizeData(response.data);
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<dynamic> getUnreadCount() async {
    try {
      final response = await _apiService.getUnreadCount();
      return Helpers.sanitizeData(response.data);
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<dynamic> markAsRead({required String contactUid, String? messageId}) async {
    try {
      final response = await _apiService.markAsRead(contactUid: contactUid, messageId: messageId);
      return Helpers.sanitizeData(response.data);
    } on DioException catch (e) {
      // 🛡️ Special handling: if mark-as-read fails, we don't want to break the whole flow
      debugPrint('⚠️ [REPO] markAsRead failed: ${e.message}');
      return {'result': 'failed', 'message': e.message};
    }
  }

  Future<dynamic> sendMedia({
    required String contactUid,
    required String filePath,
    required String mediaType,
    String? waId,
    String? caption,
    ProgressCallback? onSendProgress,
  }) async {
    debugPrint('🚀 [REPO] sendMedia called for $mediaType');
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('❌ [REPO] File NOT found at path: $filePath');
        throw Exception('File not found: $filePath');
      }

      // Step 1: Upload to temporary storage
      String uploadItem;
      switch (mediaType.toLowerCase()) {
        case 'image': uploadItem = 'whatsapp_image'; break;
        case 'sticker': uploadItem = 'whatsapp_sticker'; break;
        case 'audio':
        case 'voice': uploadItem = 'whatsapp_audio'; break;
        case 'video': uploadItem = 'whatsapp_video'; break;
        case 'document':
        default: uploadItem = 'whatsapp_document';
      }

      debugPrint('📤 [REPO] Step 1: Uploading temp media ($uploadItem)...');
      final startTime = DateTime.now();
      final uploadResponse = await _apiService.uploadTempMedia(
        filePath, 
        uploadItem, 
        onSendProgress: onSendProgress
      );
      final uploadDuration = DateTime.now().difference(startTime).inMilliseconds;
      
      debugPrint('📥 [REPO] Step 1 Response: ${uploadResponse.statusCode} in ${uploadDuration}ms');
      debugPrint('📥 [REPO] Step 1 Data: ${uploadResponse.data}');

      // Extract uploaded file name from response
      String? uploadedFileName;
      if (uploadResponse.data is String) {
        uploadedFileName = uploadResponse.data;
      } else if (uploadResponse.data is Map) {
        final Map resMap = uploadResponse.data;
        final dynamic nested = resMap['data'];
        
        if (nested is Map) {
           uploadedFileName = nested['fileName']?.toString() ?? 
                              nested['file_name']?.toString();
        }
        
        uploadedFileName ??= resMap['fileName']?.toString() ?? 
                             resMap['file_name']?.toString() ?? 
                             resMap['id']?.toString();
      }

      if (uploadedFileName == null || uploadedFileName.isEmpty) {
        debugPrint('❌ [REPO] Failed to get temp filename. Response: ${uploadResponse.data}');
        throw Exception('Failed to get temporary filename from upload response');
      }

      debugPrint('✅ [REPO] Step 1 Success. Filename: $uploadedFileName');

      // Step 2: Send message referencing the uploaded file name
      debugPrint('📤 [REPO] Step 2: Finalizing media send...');
      final response = await _apiService.sendMedia(
        contactUid: contactUid,
        mediaType: mediaType.toLowerCase() == 'voice' ? 'audio' : mediaType,
        uploadedFileName: uploadedFileName,
        waId: waId,
        caption: caption,
        isRecordedAudio: mediaType.toLowerCase() == 'voice',
      );

      debugPrint('📥 [REPO] Step 2 Response: ${response.statusCode}');

      if (response.data is Map && (response.data['result'] == 'failed' || response.data['reaction'] == 0)) {
        throw Exception(response.data['message'] ?? 'Failed to send media in step 2');
      }

      final sanitizedData = Helpers.sanitizeData(response.data);
      debugPrint('✅ [REPO] sendMedia flow completed successfully');
      return sanitizedData;
    } catch (e) {
      debugPrint('❌ [REPO] sendMedia Error: $e');
      rethrow;
    }
  }

  Future<dynamic> uploadMedia(String filePath, {required String contactUid, String type = 'audio'}) async {
    try {
      final response = await _apiService.uploadMedia(filePath, contactUid: contactUid, type: type);
      return Helpers.sanitizeData(response.data);
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<dynamic> createLabel({
    required String title,
    required String textColor,
    required String bgColor,
  }) async {
    try {
      final response = await _apiService.createLabel(
        title: title,
        textColor: textColor,
        bgColor: bgColor,
      );
      return Helpers.sanitizeData(response.data);
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<dynamic> updateLabel({
    required String labelUid,
    required String title,
    required String textColor,
    required String bgColor,
  }) async {
    try {
      final response = await _apiService.updateLabel(
        labelUid: labelUid,
        title: title,
        textColor: textColor,
        bgColor: bgColor,
      );
      return Helpers.sanitizeData(response.data);
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<dynamic> deleteLabel(String labelUid) async {
    try {
      final response = await _apiService.deleteLabel(labelUid);
      return Helpers.sanitizeData(response.data);
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<dynamic> assignLabels({
    required String contactUid,
    required List<String> labels,
  }) async {
    try {
      final response = await _apiService.assignLabels(
        contactUid: contactUid,
        labels: labels,
      );
      return Helpers.sanitizeData(response.data);
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<dynamic> sendMessage({
    required String contactUid,
    required String message,
    String? waId,
    String? replyToMessageId,
  }) async {
    try {
      final response = await _apiService.sendMessage(
        contactUid: contactUid,
        message: message,
        waId: waId,
        replyToMessageId: replyToMessageId,
      );
      
      final data = response.data;

      // 🛡️ Guard against HTML responses (redirects to home/login)
      if (data is String && data.contains('<!DOCTYPE html>')) {
        debugPrint('⚠️ sendMessage returned HTML instead of JSON. Possible session/auth issue.');
        throw Exception('Server returned an unexpected page. Please try logging out and in again.');
      }

      if (data is Map) {
        if (data['result'] == 'failed' || data['reaction'] == 0 || data['status'] == 'error') {
          throw Exception(data['message'] ?? 'Failed to send message');
        }
        return Helpers.sanitizeData(data);
      }
      
      return Helpers.sanitizeData(data);
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<dynamic> sendTemplate({
    required String contactUid,
    required String templateName,
    required String languageCode,
  }) async {
    try {
      final response = await _apiService.sendTemplate(
        contactUid: contactUid,
        templateName: templateName,
        languageCode: languageCode,
      );
      final data = Helpers.sanitizeData(response.data);
      if (data is Map && data['result'] == 'failed') {
        throw Exception(data['message'] ?? 'Failed to send template');
      }
      return data;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  // --- Contact Group Management ---

  Future<dynamic> getContactGroups({bool refresh = false}) async {
    try {
      final response = await _apiService.getContactGroups(refresh: refresh);
      return Helpers.sanitizeData(response.data);
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<dynamic> createContactGroup({
    required String title,
    String? description,
  }) async {
    try {
      final response = await _apiService.createContactGroup(
        title: title,
        description: description,
      );
      final data = Helpers.sanitizeData(response.data);
      if (data is Map && data['result'] == 'failed') {
        throw Exception(data['message'] ?? 'Failed to create group');
      }
      return data;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<dynamic> updateContactGroup(
    String groupUid, {
    required String title,
    String? description,
  }) async {
    try {
      final response = await _apiService.updateContactGroup(
        groupUid,
        title: title,
        description: description,
      );
      final data = Helpers.sanitizeData(response.data);
      if (data is Map && data['result'] == 'failed') {
        throw Exception(data['message'] ?? 'Failed to update group');
      }
      return data;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<dynamic> deleteContactGroup(String groupUid) async {
    try {
      final response = await _apiService.deleteContactGroup(groupUid);
      final data = Helpers.sanitizeData(response.data);
      if (data is Map && data['result'] == 'failed') {
        throw Exception(data['message'] ?? 'Failed to delete group');
      }
      return data;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<dynamic> assignContactsToGroup({
    required List<String> contactUids,
    required List<String> groupUids,
  }) async {
    try {
      final response = await _apiService.assignContactsToGroup(
        contactUids: contactUids,
        groupUids: groupUids,
      );
      return Helpers.sanitizeData(response.data);
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<dynamic> removeContactFromGroup({
    required String contactUid,
    required String groupUid,
  }) async {
    try {
      final response = await _apiService.removeContactFromGroup(
        contactUid: contactUid,
        groupUid: groupUid,
      );
      return Helpers.sanitizeData(response.data);
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  String _extractError(DioException e) {
    if (e.response != null) {
      final status = e.response!.statusCode;
      if (status == 403) return "Too many requests. Please wait a moment.";
      if (status == 404) return "currently not working.";
      if (status == 413) return "Video file is too large for the server. Please try a shorter or lower quality video.";
      if (status != null && status >= 500) return "Server error. Please try again later.";

      final data = e.response!.data;
      if (data is Map) {
        String msg = (data['message'] ?? data['incident'] ?? data['error'] ?? 'An error occurred').toString();
        // 🛡️ WhatsApp specific error conversion
        if (msg.contains('24 hours')) return "24_hour_policy_error";
        return msg;
      }
      if (data is String && data.isNotEmpty) {
        if (data.contains('<!DOCTYPE html>')) {
          return 'Server error ($status). Please check API URL.';
        }
        return data;
      }
    }
    return e.message ?? 'An error occurred';
  }
}
