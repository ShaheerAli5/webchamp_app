import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/repositories/contact_repository.dart';

class ContactProvider extends ChangeNotifier {
  final ContactRepository _repository;

  ContactProvider(this._repository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // New flag to specifically guard getContacts from parallel execution
  bool _isFetchingContacts = false;

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
    // 🛡️ GUARD: Prevent concurrent contact fetching to avoid API spam
    if (_isFetchingContacts) return false;
    
    _isFetchingContacts = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('🚀 Fetching contacts: search=$search, page=${page ?? "all"}');
      final result = await _repository.getContacts(
        search: search,
        perPage: perPage ?? 100,
        page: page,
      );

      final parsedContacts = _parseContactsResponse(result);

      if (page == null) {
        // Initial page (usually 1) is already in result, avoid requesting it again in loop
        final int firstPage = _extractCurrentPage(result) ?? 1;
        await _loadRemainingContactPages(
          parsedContacts,
          result,
          currentPage: firstPage,
          search: search,
          perPage: perPage ?? 100,
        );
      }

      _contacts = parsedContacts.whereType<Map>().toList();
      debugPrint('✅ Final Parsed Contacts Count: ${_contacts.length}');

      _isFetchingContacts = false;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error in getContacts: $e');
      _errorMessage = e.toString();
      _isFetchingContacts = false;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  List<dynamic> _parseContactsResponse(dynamic result) {
    if (result is Map<String, dynamic>) {
      final clientModels = result['client_models'];

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
    required int currentPage,
    String? search,
    required int perPage,
  }) async {
    final visitedPages = <int>{currentPage};
    var nextPage = _extractNextContactsPage(firstResult);

    // Stop if we hit 20 pages to prevent hitting rate limits (Laravel limit is 60 req/min)
    while (nextPage != null && visitedPages.length < 20 && visitedPages.add(nextPage)) {
      debugPrint('📥 Loading extra contacts page: $nextPage');

      try {
        final result = await _repository.getContacts(
          search: search,
          perPage: perPage,
          page: nextPage,
        );

        _mergeContacts(parsedContacts, _parseContactsResponse(result));
        nextPage = _extractNextContactsPage(result);
      } catch (e) {
        debugPrint('⚠️ Failed to load page $nextPage: $e');
        break; // Stop pagination on error
      }
    }
  }

  int? _extractCurrentPage(dynamic result) {
    if (result is! Map<String, dynamic>) return null;
    final clientModels = result['client_models'];
    if (clientModels is! Map<String, dynamic>) return null;
    final paginatePage = clientModels['contactsPaginatePage'];
    if (paginatePage is Map) return paginatePage['current_page'];
    return null;
  }

  int? _extractNextContactsPage(dynamic result) {
    if (result is! Map<String, dynamic>) return null;

    final clientModels = result['client_models'];
    if (clientModels is! Map<String, dynamic>) return null;

    final paginatePage = clientModels['contactsPaginatePage'];

    if (paginatePage is Map) {
      final next = paginatePage['next_page'] ??
          paginatePage['next_page_url'] ??
          paginatePage['current_page'];
      
      if (next is int) {
        // If it's returning the current page as 'next', we need to increment it or stop
        // Some APIs use 'current_page' as the key even in pagination objects
        if (next == paginatePage['current_page']) {
          final lastPage = paginatePage['last_page'];
          if (lastPage is int && next < lastPage) return next + 1;
          return null;
        }
        return next > 0 ? next : null;
      }
      
      if (next is String) {
        // Try parsing numeric string
        final parsed = int.tryParse(next);
        if (parsed != null) return parsed;
        
        // Handle URL like "...?page=2"
        if (next.contains('page=')) {
          final uri = Uri.tryParse(next);
          final pageStr = uri?.queryParameters['page'];
          if (pageStr != null) return int.tryParse(pageStr);
        }
      }
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

      if (result['reaction'] == 0 || result['success'] == false) {
        throw Exception(
          result['message'] ??
              result['data']?['message'] ??
              result['incident'] ??
              'Failed to add contact',
        );
      }

      // Automatically refresh contacts list after creating a new one
      await getContacts(perPage: 100);
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
      await getContacts(perPage: 100);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteContact(String phoneNumber) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _repository.deleteContact(phoneNumber);

      if (result is Map &&
          (result['result'] == 'failed' || result['reaction'] == 0)) {
        throw Exception(result['message'] ?? 'Failed to delete contact');
      }

      await getContacts(perPage: 100);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
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

  Future<bool> getContactChatBoxData(String contactUid,
      {bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      _errorMessage = null;
      _messages = [];
      notifyListeners();
    }
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

      dynamic chatResult;
      try {
        chatResult = await _repository.getChatHistory(contactUid);
      } catch (e) {
        debugPrint('❌ Chat history failed: $e');
      }

      _messages = _extractLargestMessageList([result, chatResult]);

      if (_messages.isNotEmpty) {
        _messages.sort((a, b) {
          final aTime = (a['created_at'] ?? a['messaged_at'] ?? a['timestamp'] ?? '').toString();
          final bTime = (b['created_at'] ?? b['messaged_at'] ?? b['timestamp'] ?? '').toString();
          return bTime.compareTo(aTime);
        });
      }

      if (_messages.isEmpty) {
        _messages = _messagesFromLoadedContact(contactUid);
      }

      if (showLoading) _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (showLoading) {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
        notifyListeners();
      }
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
    if (value == null) return [];

    if (value is List) {
      return value.where(_looksLikeMessage).toList();
    }

    if (value is Map) {
      final keysToTry = [
        'whatsappMessageLogs',
        'messages',
        'chat_messages',
        'contactMessages',
        'messageData',
        'records',
      ];

      for (final key in keysToTry) {
        final nestedValue = value[key];
        if (nestedValue is List) {
          final messages = nestedValue.where(_looksLikeMessage).toList();
          if (messages.isNotEmpty) return messages;
        }
        if (nestedValue is Map) {
          final asList = nestedValue.values.where(_looksLikeMessage).toList();
          if (asList.isNotEmpty) return asList;
        }
      }

      if (value['data'] != null) {
        final fromData = _extractMessageList(value['data']);
        if (fromData.isNotEmpty) return fromData;
      }
      if (value['client_models'] != null) {
        final fromClientModels = _extractMessageList(value['client_models']);
        if (fromClientModels.isNotEmpty) return fromClientModels;
      }

      for (final val in value.values) {
        if (val is List) {
          final messages = val.where(_looksLikeMessage).toList();
          if (messages.isNotEmpty) return messages;
        }
      }
    }

    return [];
  }

  bool _looksLikeMessage(dynamic value) {
    if (value is! Map) return false;

    final hasContent = value.containsKey('message') ||
        value.containsKey('text') ||
        value.containsKey('body') ||
        value.containsKey('message_body') ||
        value.containsKey('wamid') ||
        value.containsKey('whatsapp_message_id') ||
        value.containsKey('uploaded_media_file_name') ||
        value.containsKey('media_url') ||
        value.containsKey('attachment_url') ||
        (value['__data'] is Map && value['__data']['media_values'] != null) ||
        value.containsKey('_uid') ||
        value.containsKey('uid');

    final hasMeta = value.containsKey('is_incoming_message') ||
        value.containsKey('status') ||
        value.containsKey('direction') ||
        value.containsKey('contacts__id') ||
        value.containsKey('created_at') ||
        value.containsKey('messaged_at') ||
        value.containsKey('timestamp');

    return hasContent && (hasMeta || value.containsKey('_uid'));
  }

  Future<bool> sendMessage({
    required String contactUid,
    required String message,
  }) async {
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.sendMessage(
        contactUid: contactUid,
        message: message,
      );
      await getContactChatBoxData(contactUid, showLoading: false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendTemplateMessage({
    required String contactUid,
    required String templateName,
    required String languageCode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _repository.sendTemplate(
        contactUid: contactUid,
        templateName: templateName,
        languageCode: languageCode,
      );

      if (result is Map &&
          (result['result'] == 'failed' || result['reaction'] == 0)) {
        throw Exception(result['message'] ?? 'Failed to send template');
      }

      await getContactChatBoxData(contactUid, showLoading: false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendVoiceMessage({
    required String contactUid,
    required String filePath,
  }) async {
    _errorMessage = null;
    notifyListeners();
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        _errorMessage = 'Audio file not found at: $filePath';
        notifyListeners();
        return false;
      }

      final uploadResult = await _repository.uploadMedia(filePath, contactUid: contactUid, type: 'audio');

      if (uploadResult is! Map) {
        _errorMessage = 'Upload failed — unexpected server response';
        notifyListeners();
        return false;
      }

      final fileName = uploadResult['data']?['fileName'] ?? 
                       uploadResult['fileName'] ?? 
                       uploadResult['data']?['file_name'];

      if (fileName == null || fileName.toString().isEmpty) {
        _errorMessage = 'Upload failed — server did not return filename.';
        notifyListeners();
        return false;
      }

      await _repository.sendMedia(
        contactUid: contactUid,
        fileName: fileName.toString(),
        mediaType: 'audio',
        isRecordedAudio: true,
      );

      await getContactChatBoxData(contactUid, showLoading: false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendImageMessage({
    required String contactUid,
    required String filePath,
  }) async {
    _errorMessage = null;
    notifyListeners();
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        _errorMessage = 'Image file not found at: $filePath';
        notifyListeners();
        return false;
      }

      final uploadResult = await _repository.uploadMedia(filePath, contactUid: contactUid, type: 'image');

      if (uploadResult is! Map) {
        _errorMessage = 'Upload failed — unexpected server response';
        notifyListeners();
        return false;
      }

      final fileName = uploadResult['data']?['fileName'] ?? 
                       uploadResult['fileName'] ?? 
                       uploadResult['data']?['file_name'];

      if (fileName == null || fileName.toString().isEmpty) {
        _errorMessage = 'Upload failed — server did not return filename.';
        notifyListeners();
        return false;
      }

      await _repository.sendMedia(
        contactUid: contactUid,
        fileName: fileName.toString(),
        mediaType: 'image',
      );

      await getContactChatBoxData(contactUid, showLoading: false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendVideoMessage({
    required String contactUid,
    required String filePath,
  }) async {
    _errorMessage = null;
    notifyListeners();
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        _errorMessage = 'Video file not found at: $filePath';
        notifyListeners();
        return false;
      }

      final uploadResult = await _repository.uploadMedia(filePath, contactUid: contactUid, type: 'video');

      if (uploadResult is! Map) {
        _errorMessage = 'Upload failed — unexpected server response';
        notifyListeners();
        return false;
      }

      final fileName = uploadResult['data']?['fileName'] ?? 
                       uploadResult['fileName'] ?? 
                       uploadResult['data']?['file_name'];

      if (fileName == null || fileName.toString().isEmpty) {
        _errorMessage = 'Upload failed — server did not return filename.';
        notifyListeners();
        return false;
      }

      await _repository.sendMedia(
        contactUid: contactUid,
        fileName: fileName.toString(),
        mediaType: 'video',
      );

      await getContactChatBoxData(contactUid, showLoading: false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendDocumentMessage({
    required String contactUid,
    required String filePath,
  }) async {
    _errorMessage = null;
    notifyListeners();
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        _errorMessage = 'Document not found at: $filePath';
        notifyListeners();
        return false;
      }

      final uploadResult = await _repository.uploadMedia(filePath, contactUid: contactUid, type: 'document');

      if (uploadResult is! Map) {
        _errorMessage = 'Upload failed — unexpected server response';
        notifyListeners();
        return false;
      }

      final fileName = uploadResult['data']?['fileName'] ?? 
                       uploadResult['fileName'] ?? 
                       uploadResult['data']?['file_name'];

      if (fileName == null || fileName.toString().isEmpty) {
        _errorMessage = 'Upload failed — server did not return filename.';
        notifyListeners();
        return false;
      }

      await _repository.sendMedia(
        contactUid: contactUid,
        fileName: fileName.toString(),
        mediaType: 'document',
      );

      await getContactChatBoxData(contactUid, showLoading: false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
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
