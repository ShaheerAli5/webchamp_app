import 'package:dio/dio.dart';
import '../services/contact_api_service.dart';

class ContactRepository {
  final ContactApiService _apiService;

  ContactRepository(this._apiService);

  Future<dynamic> getContacts({
    String? search,
    int? perPage,
    int? page,
  }) async {
    try {
      final response = await _apiService.getContacts(
        search: search,
        perPage: perPage,
        page: page,
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<Map<String, dynamic>> getContact({
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

  Future<Map<String, dynamic>> createContact({
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
    try {
      final response = await _apiService.createContact(
        phoneNumber: phoneNumber,
        firstName: firstName,
        lastName: lastName,
        email: email,
        languageCode: languageCode,
        country: country,
        whatsappOptOut: whatsappOptOut,
        enableReplyBot: enableReplyBot,
        otherInfo: otherInfo,
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<Map<String, dynamic>> updateContact(
    String phoneNumber, {
    String? firstName,
    String? lastName,
    String? email,
    String? languageCode,
    String? country,
  }) async {
    try {
      final response = await _apiService.updateContact(
        phoneNumber,
        firstName: firstName,
        lastName: lastName,
        email: email,
        languageCode: languageCode,
        country: country,
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<Map<String, dynamic>> assignTeamMember({
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

  Future<Map<String, dynamic>> getContactChatBoxData(String contactUid) async {
    try {
      final response = await _apiService.getContactChatBoxData(contactUid);
      return response.data;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<dynamic> getContactMessages(String contactUid) async {
    try {
      final response = await _apiService.getContactMessages(contactUid);
      return response.data;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<Map<String, dynamic>> createLabel({
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

  Future<Map<String, dynamic>> updateLabel({
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

  Future<Map<String, dynamic>> deleteLabel(String labelUid) async {
    try {
      final response = await _apiService.deleteLabel(labelUid);
      return response.data;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<Map<String, dynamic>> assignLabels({
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

  Future<Map<String, dynamic>> sendMessage({
    required String contactUid,
    required String message,
  }) async {
    try {
      final response = await _apiService.sendMessage(
        contactUid: contactUid,
        message: message,
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  String _extractError(DioException e) {
    if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map) {
        return data['message'] ?? 'An error occurred';
      }
    }
    return 'An error occurred';
  }
}
