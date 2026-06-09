import 'package:flutter/material.dart';
import '../../data/repositories/contact_repository.dart';

class ContactProvider extends ChangeNotifier {
  final ContactRepository _repository;

  ContactProvider(this._repository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<dynamic> _contacts = [];
  List<dynamic> get contacts => _contacts;

  Map<String, dynamic>? _selectedContact;
  Map<String, dynamic>? get selectedContact => _selectedContact;

  List<dynamic> _labels = [];
  List<dynamic> get labels => _labels;

  List<dynamic> _teamMembers = [];
  List<dynamic> get teamMembers => _teamMembers;

  List<dynamic> _messages = [];
  List<dynamic> get messages => _messages;

  Future<bool> getContacts({
    String? search,
    int? perPage,
    int? page,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.getContacts(
        search: search,
        perPage: perPage ?? 100,
        page: page,
      );

      final parsedContacts = _parseContactsResponse(result);

      if (page == null) {
        await _loadRemainingContactPages(
          parsedContacts,
          result,
          search: search,
          perPage: perPage ?? 100,
        );
      }

      _contacts = parsedContacts;
      debugPrint('✅ Final Parsed Contacts Count: ${_contacts.length}');

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error in getContacts: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  List<dynamic> _parseContactsResponse(dynamic result) {
    debugPrint(
      'Contacts API Raw Response Keys: ${result is Map ? result.keys.toList() : "Not a Map"}',
    );

    if (result is Map<String, dynamic>) {
      final clientModels = result['client_models'];

      if (clientModels is Map<String, dynamic>) {
        debugPrint('Client Models Keys: ${clientModels.keys.toList()}');
        _logPaginationInfo(clientModels['contactsPaginatePage']);
      }

      return _extractLargestContactList([
        if (clientModels is Map<String, dynamic>) clientModels['contacts'],
        if (clientModels is Map<String, dynamic>) clientModels['contactsPaginatePage'],
        if (clientModels is Map<String, dynamic>)
          _mapValue(clientModels['contactsPaginatePage'], 'data'),
        result['data'],
        _mapValue(result['data'], 'contacts'),
        _mapValue(result['data'], 'data'),
        result['contacts'],
      ]);
    }

    if (result is List) {
      return result.where(_looksLikeContact).toList();
    }

    return [];
  }

  Future<void> _loadRemainingContactPages(
    List<dynamic> parsedContacts,
    dynamic firstResult, {
    String? search,
    required int perPage,
  }) async {
    final visitedPages = <int>{};
    var nextPage = _extractNextContactsPage(firstResult);

    while (nextPage != null && visitedPages.length < 20 && visitedPages.add(nextPage)) {
      debugPrint('Loading contacts page: $nextPage');

      final result = await _repository.getContacts(
        search: search,
        perPage: perPage,
        page: nextPage,
      );

      _mergeContacts(parsedContacts, _parseContactsResponse(result));
      nextPage = _extractNextContactsPage(result);
    }
  }

  int? _extractNextContactsPage(dynamic result) {
    if (result is! Map<String, dynamic>) return null;

    final clientModels = result['client_models'];
    if (clientModels is! Map<String, dynamic>) return null;

    final paginatePage = clientModels['contactsPaginatePage'];
    if (paginatePage is int && paginatePage > 0) return paginatePage;

    if (paginatePage is String) {
      return int.tryParse(paginatePage);
    }

    if (paginatePage is Map) {
      final nextPage = paginatePage['next_page'] ??
          paginatePage['next_page_url'] ??
          paginatePage['current_page'];
      if (nextPage is int && nextPage > 0) return nextPage;
      if (nextPage is String) return int.tryParse(nextPage);
    }

    return null;
  }

  void _mergeContacts(List<dynamic> contacts, List<dynamic> incomingContacts) {
    final existingIds = contacts.map(_contactIdentity).whereType<String>().toSet();

    for (final contact in incomingContacts) {
      final identity = _contactIdentity(contact);
      if (identity == null || existingIds.add(identity)) {
        contacts.add(contact);
      }
    }
  }

  String? _contactIdentity(dynamic contact) {
    if (contact is! Map) return null;

    return contact['_uid']?.toString() ??
        contact['uid']?.toString() ??
        contact['contacts__id']?.toString() ??
        contact['_id']?.toString() ??
        contact['wa_id']?.toString() ??
        contact['phone_number']?.toString();
  }

  List<dynamic> _extractLargestContactList(List<dynamic> candidates) {
    final contactLists = candidates
        .map(_extractContactList)
        .where((contacts) => contacts.isNotEmpty)
        .toList();

    if (contactLists.isEmpty) return [];

    contactLists.sort((a, b) => b.length.compareTo(a.length));
    return contactLists.first;
  }

  dynamic _mapValue(dynamic value, String key) {
    if (value is Map) return value[key];
    return null;
  }

  List<dynamic> _extractContactList(dynamic value) {
    if (value is List) {
      return value.where(_looksLikeContact).toList();
    }

    if (value is Map) {
      final data = value['data'];
      if (data is List || data is Map) {
        final contacts = _extractContactList(data);
        if (contacts.isNotEmpty) return contacts;
      }

      final contacts = value['contacts'];
      if (contacts is List || contacts is Map) {
        final extractedContacts = _extractContactList(contacts);
        if (extractedContacts.isNotEmpty) return extractedContacts;
      }

      final values = value.values.where(_looksLikeContact).toList();
      if (values.isNotEmpty) return values;
    }

    return [];
  }

  bool _looksLikeContact(dynamic value) {
    if (value is! Map) return false;

    return value.containsKey('_uid') ||
        value.containsKey('uid') ||
        value.containsKey('contacts__id') ||
        value.containsKey('phone_number') ||
        value.containsKey('wa_id') ||
        value.containsKey('mobile_number');
  }

  void _logPaginationInfo(dynamic paginatePage) {
    if (paginatePage is! Map) return;

    final currentPage = paginatePage['current_page'];
    final lastPage = paginatePage['last_page'];
    final perPage = paginatePage['per_page'];
    final total = paginatePage['total'];

    debugPrint(
      'Contacts pagination: page=$currentPage lastPage=$lastPage perPage=$perPage total=$total',
    );
  }

  Future<bool> getContact({
    String? phoneNumber,
    String? email,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _repository.getContact(
        phoneNumber: phoneNumber,
        email: email,
      );
      _selectedContact = result;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> createContact({
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _repository.createContact(
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

      debugPrint(
        'Create Contact API Response Keys: ${result.keys.toList()}',
      );

      if (result['reaction'] == 0 || result['success'] == false) {
        throw Exception(
          result['message'] ??
              result['data']?['message'] ??
              result['incident'] ??
              'Failed to add contact',
        );
      }

      final createdContacts = _extractLargestContactList([
        result,
        result['data'],
        result['contact'],
        result['data']?['contact'],
        result['client_models'],
        result['client_models']?['contacts'],
      ]);

      // Automatically refresh contacts list after creating a new one
      await getContacts(perPage: 100);

      if (_contacts.isEmpty && createdContacts.isNotEmpty) {
        _contacts = createdContacts;
        notifyListeners();
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateContact(
    String phoneNumber, {
    String? firstName,
    String? lastName,
    String? email,
    String? languageCode,
    String? country,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.updateContact(
        phoneNumber,
        firstName: firstName,
        lastName: lastName,
        email: email,
        languageCode: languageCode,
        country: country,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> assignTeamMember({
    required String phoneNumber,
    required String usernameOrEmail,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.assignTeamMember(
        phoneNumber: phoneNumber,
        usernameOrEmail: usernameOrEmail,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> getContactChatBoxData(String contactUid) async {
    _isLoading = true;
    _errorMessage = null;
    _messages = [];
    notifyListeners();
    try {
      final result = await _repository.getContactChatBoxData(contactUid);

      // Robust message extraction
      final clientModels = result['client_models'];
      final data = _mapValue(result, 'data');

      _labels = _extractLargestPlainList([
        _mapValue(result, 'labels'),
        _mapValue(data, 'labels'),
        _mapValue(data, 'listOfAllLabels'),
        _mapValue(clientModels, 'labels'),
        _mapValue(clientModels, 'listOfAllLabels'),
      ]);
      _teamMembers = _extractLargestPlainList([
        _mapValue(result, 'teamMembers'),
        _mapValue(result, 'vendorMessagingUsers'),
        _mapValue(data, 'teamMembers'),
        _mapValue(data, 'vendorMessagingUsers'),
        _mapValue(clientModels, 'teamMembers'),
        _mapValue(clientModels, 'vendorMessagingUsers'),
      ]);

      _messages = _extractLargestMessageList([
        result,
        data,
        clientModels,
        _mapValue(clientModels, 'chat_box_data'),
        _mapValue(data, 'chat_box_data'),
      ]);

      if (_messages.isEmpty) {
        try {
          final messagesResult = await _repository.getContactMessages(contactUid);
          _messages = _extractLargestMessageList([messagesResult]);
        } catch (e) {
          debugPrint('Messages history endpoint failed: $e');
        }
      }

      if (_messages.isEmpty) {
        _messages = _messagesFromLoadedContact(contactUid);
      }

      debugPrint('Final Parsed Messages Count: ${_messages.length}');

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  List<dynamic> _messagesFromLoadedContact(String contactUid) {
    for (final contact in _contacts) {
      if (contact is! Map) continue;

      final uid = contact['_uid']?.toString() ??
          contact['uid']?.toString() ??
          contact['id']?.toString();
      if (uid != contactUid) continue;

      final lastMessage = contact['last_message'];
      if (_looksLikeMessage(lastMessage)) return [lastMessage];

      final latestMessageText = contact['latest_message_text'] ??
          contact['message'] ??
          contact['last_message_text'];
      if (latestMessageText == null || latestMessageText.toString().trim().isEmpty) {
        return [];
      }

      return [
        {
          'message': latestMessageText.toString(),
          'status': contact['status'] ?? 'received',
          'is_incoming_message': 1,
          'created_at': contact['latest_message'] ?? contact['updated_at'],
        }
      ];
    }

    return [];
  }

  List<dynamic> _extractLargestPlainList(List<dynamic> candidates) {
    final lists = candidates.whereType<List>().toList();
    if (lists.isEmpty) return [];

    lists.sort((a, b) => b.length.compareTo(a.length));
    return lists.first;
  }

  List<dynamic> _extractLargestMessageList(List<dynamic> candidates) {
    final messageLists = candidates
        .map(_extractMessageList)
        .where((messages) => messages.isNotEmpty)
        .toList();

    if (messageLists.isEmpty) return [];

    messageLists.sort((a, b) => b.length.compareTo(a.length));
    return messageLists.first;
  }

  List<dynamic> _extractMessageList(dynamic value) {
    if (value is List) {
      return value.where(_looksLikeMessage).toList();
    }

    if (value is Map) {
      for (final key in [
        'messages',
        'chat_messages',
        'contactMessages',
        'messageData',
        'records',
        'data',
      ]) {
        final nestedValue = value[key];
        if (nestedValue is List || nestedValue is Map) {
          final messages = _extractMessageList(nestedValue);
          if (messages.isNotEmpty) return messages;
        }
      }

      final values = value.values.where(_looksLikeMessage).toList();
      if (values.isNotEmpty) return values;
    }

    return [];
  }

  bool _looksLikeMessage(dynamic value) {
    if (value is! Map) return false;

    final hasMessageText = value.containsKey('message') ||
        value.containsKey('text') ||
        value.containsKey('body') ||
        value.containsKey('message_body') ||
        value.containsKey('description') ||
        value.containsKey('__data');
    final hasMessageMeta = value.containsKey('is_incoming_message') ||
        value.containsKey('message_type') ||
        value.containsKey('status') ||
        value.containsKey('wamid') ||
        value.containsKey('messaging_contact_wa_id');

    return hasMessageText && hasMessageMeta;
  }

  Future<bool> sendMessage({
    required String contactUid,
    required String message,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.sendMessage(
        contactUid: contactUid,
        message: message,
      );
      // Refresh chat data after sending message
      await getContactChatBoxData(contactUid);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> createLabel({
    required String title,
    required String textColor,
    required String bgColor,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.createLabel(
        title: title,
        textColor: textColor,
        bgColor: bgColor,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateLabel({
    required String labelUid,
    required String title,
    required String textColor,
    required String bgColor,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.updateLabel(
        labelUid: labelUid,
        title: title,
        textColor: textColor,
        bgColor: bgColor,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteLabel(String labelUid) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.deleteLabel(labelUid);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> assignLabels({
    required String contactUid,
    required List<String> contactLabels,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.assignLabels(
        contactUid: contactUid,
        contactLabels: contactLabels,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
