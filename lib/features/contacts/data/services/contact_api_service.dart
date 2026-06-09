import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';

class ContactApiService {
  final ApiClient _apiClient;

  ContactApiService(this._apiClient);

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
      queryParameters: {
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (email != null) 'email': email,
        if (languageCode != null) 'language_code': languageCode,
        if (country != null) 'country': country,
      },
    );
  }

  // API 5 - Assign Team Member
  Future<Response> assignTeamMember({
    required String phoneNumber,
    required String usernameOrEmail,
  }) async {
    return await _apiClient.post(
      ApiConstants.assignTeamMember,
      queryParameters: {
        'phone_number': phoneNumber,
        'username_or_email': usernameOrEmail,
      },
    );
  }

  // API 6 - Get Contact Chat Box Data
  Future<Response> getContactChatBoxData(String contactUid) async {
    return await _apiClient.get(
      ApiConstants.contactChatBoxData(contactUid),
    );
  }

  Future<Response> getContactMessages(String contactUid) async {
    DioException? lastError;

    for (final path in ApiConstants.contactMessages(contactUid)) {
      try {
        return await _apiClient.get(path);
      } on DioException catch (e) {
        lastError = e;
        final statusCode = e.response?.statusCode;
        if (statusCode != 404 && statusCode != 405) {
          rethrow;
        }
      }
    }

    for (final queryKey in ['contactUid', 'contact_uid']) {
      try {
        return await _apiClient.get(
          '/vendor/whatsapp/contact/chat/messages',
          queryParameters: {queryKey: contactUid},
        );
      } on DioException catch (e) {
        lastError = e;
        final statusCode = e.response?.statusCode;
        if (statusCode != 404 && statusCode != 405) {
          rethrow;
        }
      }
    }

    throw lastError ?? Exception('Unable to fetch contact messages');
  }

  // API 7 - Create Label
  Future<Response> createLabel({
    required String title,
    required String textColor,
    required String bgColor,
  }) async {
    return await _apiClient.post(
      ApiConstants.createLabel,
      queryParameters: {
        'title': title,
        'text_color': textColor,
        'bg_color': bgColor,
      },
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
      queryParameters: {
        'labelUid': labelUid,
        'title': title,
        'text_color': textColor,
        'bg_color': bgColor,
      },
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
      queryParameters: {
        'contactUid': contactUid,
        'contact_labels': contactLabels,
      },
    );
  }

  // API 11 - Send Message
  Future<Response> sendMessage({
    required String contactUid,
    required String message,
  }) async {
    return await _apiClient.post(
      ApiConstants.sendMessage,
      queryParameters: {
        'contactUid': contactUid,
        'message': message,
      },
    );
  }
}
