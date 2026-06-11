import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_constants.dart';
import '../services/contact_api_service.dart';

class ContactRepository {
  final ContactApiService _apiService;

  ContactRepository(this._apiService);

  Future<dynamic> getContacts({
    String? search,
    int page = 1,
    int? perPage,
  }) async {
    try {
      final response = await _apiService.getContacts(
        search: search,
        page: page,
        perPage: perPage,
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

      return response.data;
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

  Future<dynamic> getContact({
    String? phoneNumber,
    String? email,
  }) async {
    try {
      final response = await _apiService.getContact(
        phoneNumber: phoneNumber,
        email: email,
      );
      return response.data;
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
      
      final data = response.data;
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
      
      final data = response.data;
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
      final data = response.data;
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
      return response.data;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<dynamic> getChatHistory(String contactUid) async {
    try {
      final response = await _apiService.getChatHistory(contactUid);

      // 1. If response is already a Map (Dio auto-parsed JSON)
      if (response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        // Automatically update CSRF token if present in JSON
        final token = data['csrf_token'] ?? data['data']?['csrf_token'];
        if (token != null) {
          _apiService.setCsrfToken(token.toString());
        }
        return data;
      }

      // 2. If response is a List (Dio auto-parsed JSON)
      if (response.data is List) {
        return response.data;
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
            return decoded;
          }
          if (decoded is List) return decoded;
        } catch (_) {
          // Not valid JSON, proceed to HTML extraction (legacy)
        }

        // Legacy support for web-view HTML extraction if endpoint still returns HTML
        final result = _extractMessagesFromHtml(dataStr);
        if (result['csrf_token'] != null) {
          _apiService.setCsrfToken(result['csrf_token']);
        }
        return result;
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

  Future<dynamic> getContactChatBoxData(String contactUid) async {
    try {
      final response = await _apiService.getContactChatBoxData(contactUid);
      return response.data;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<dynamic> sendMedia({
    required String contactUid,
    required String fileName,
    String mediaType = 'audio',
    bool isRecordedAudio = false,
  }) async {
    try {
      final response = await _apiService.sendMedia(
        contactUid: contactUid,
        fileName: fileName,
        mediaType: mediaType,
        isRecordedAudio: isRecordedAudio,
      );
      final data = response.data;
      if (data is Map && (data['result'] == 'failed' || data['reaction'] == 0)) {
        throw Exception(data['message'] ?? 'Failed to send media');
      }
      return data;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<dynamic> uploadMedia(String filePath, {required String contactUid, String type = 'audio'}) async {
    try {
      final response = await _apiService.uploadMedia(filePath, contactUid: contactUid, type: type);
      return response.data;
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
      return response.data;
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
      return response.data;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<dynamic> deleteLabel(String labelUid) async {
    try {
      final response = await _apiService.deleteLabel(labelUid);
      return response.data;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<dynamic> assignLabels({
    required String contactUid,
    required List<String> contactLabels,
  }) async {
    try {
      final response = await _apiService.assignLabels(
        contactUid: contactUid,
        contactLabels: contactLabels,
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<dynamic> sendMessage({
    required String contactUid,
    required String message,
  }) async {
    try {
      final response = await _apiService.sendMessage(
        contactUid: contactUid,
        message: message,
      );
      
      final data = response.data;
      if (data is Map && (data['result'] == 'failed' || data['reaction'] == 0)) {
        throw Exception(data['message'] ?? 'Failed to send message');
      }
      
      return data;
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
      final data = response.data;
      if (data is Map && data['result'] == 'failed') {
        throw Exception(data['message'] ?? 'Failed to send template');
      }
      return data;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  String _extractError(DioException e) {
    if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map) {
        return data['message'] ??
            data['incident'] ??
            data['error'] ??
            'An error occurred';
      }
      if (data is String && data.isNotEmpty) {
        if (data.contains('<!DOCTYPE html>')) {
          return 'Server error (404/500). Please check API URL.';
        }
        return data;
      }
    }
    return e.message ?? 'An error occurred';
  }
}
