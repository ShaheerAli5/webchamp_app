import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/repositories/contact_repository.dart';
import '../../../../core/utils/helpers.dart';

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

  List<dynamic> _availableGroups = [];
  List<dynamic> get availableGroups => _availableGroups;

  List<dynamic> _availableCountries = [];
  List<dynamic> get availableCountries => _availableCountries;

  int _total = 0;
  int get total => _total;

  int _currentPage = 1;
  bool _hasMore = true;
  bool get hasMore => _hasMore;
  String? _lastSearch;

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
    bool loadMore = false,
  }) async {
    // 🛡️ GUARD: Prevent concurrent contact fetching
    if (_isFetchingContacts) return false;
    if (loadMore && !_hasMore) return false;

    if (!loadMore) {
      _currentPage = 1;
      _hasMore = true;
    } else {
      _currentPage++;
    }
    
    _isFetchingContacts = true;
    _isLoading = true;
    _errorMessage = null;
    _lastSearch = search;
    notifyListeners();

    try {
      print('Loading Page: $_currentPage');
      var rawResult = await _repository.getContacts(
        search: search,
        page: _currentPage,
        perPage: 100,
      );
      
      final result = Helpers.sanitizeData(rawResult);
      
      // Extract contacts list using a robust parser
      List<dynamic> newContacts = _parseContactsResponse(result);
      
      if (!loadMore) {
        // Clear only on initial load or pull-to-refresh
        _contacts.clear();
      }
      
      // 🛡️ Defensive: Filter duplicates if any
      final existingUids = _contacts.map(_extractUid).toSet();
      for (var contact in newContacts) {
        final uid = _extractUid(contact);
        if (uid == null || !existingUids.contains(uid)) {
          _contacts.add(contact);
          if (uid != null) existingUids.add(uid);
        }
      }

      // Handle pagination object - Priority to root response['pagination']
      dynamic pagination = result['pagination'];
      if (pagination == null && result['data'] is Map) {
        pagination = result['data']['pagination'];
      }
      if (pagination == null && result['client_models'] is Map) {
        pagination = result['client_models']['contactsPaginatePage'];
      }
      
      if (pagination is Map) {
        _total = _toInt(pagination['total']) ?? _toInt(pagination['count']) ?? _contacts.length;
        
        final backendCurrentPage = _toInt(pagination['current_page']);
        final backendLastPage = _toInt(pagination['last_page']);
        
        if (pagination.containsKey('has_more_pages')) {
          _hasMore = pagination['has_more_pages'] == true;
        } else if (backendCurrentPage != null && backendLastPage != null) {
          _hasMore = backendCurrentPage < backendLastPage;
        } else {
          _hasMore = _contacts.length < _total;
        }

        if (backendCurrentPage != null) {
          _currentPage = backendCurrentPage;
        }
        
        debugPrint('Backend Pagination: total=$_total, hasMore=$_hasMore, currentPage=$_currentPage');
      } else {
        _total = _extractTotal(result) ?? _contacts.length;
        _hasMore = _contacts.length < _total;
        debugPrint('Fallback Pagination: total=$_total, hasMore=$_hasMore');
      }
      
      // User requested specific logs
      print('Current Page: $_currentPage');
      print('New Contacts: ${newContacts.length}');
      print('Total Contacts: ${_contacts.length}');
      print('Has More Pages: $_hasMore');

      // Extract metadata
      _availableGroups = _extractGroupsFromResponse(result);
      _availableCountries = _extractCountriesFromResponse(result);

      _isFetchingContacts = false;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, stack) {
      debugPrint('❌ Error in getContacts: $e');
      debugPrint('Stacktrace: $stack');
      _errorMessage = e.toString();
      _isFetchingContacts = false;
      _isLoading = false;
      if (loadMore) {
        _currentPage--; // Rollback page on failure
      }
      notifyListeners();
      return false;
    }
  }

  String? _extractUid(dynamic contact) {
    if (contact is! Map) return null;
    return (contact['_uid'] ?? contact['uid'] ?? contact['id'] ?? contact['wa_id'])?.toString();
  }

  bool _determineHasMore(dynamic result, int currentLoaded, int totalAvailable) {
    if (result is Map) {
      final clientModels = result['client_models'];
      final data = result['data'];
      final paginate = (clientModels is Map ? clientModels['contactsPaginatePage'] : null) ??
                       (data is Map ? data['contactsPaginatePage'] : null) ??
                       result['contactsPaginatePage'];

      if (paginate is Map) {
        final lastPage = _toInt(paginate['last_page']);
        final currentPage = _toInt(paginate['current_page']);
        if (lastPage != null && currentPage != null) {
          return currentPage < lastPage;
        }
      } else if (paginate is int) {
        // If the backend returns just a number for contactsPaginatePage, 
        // it might represent the last page or current page. 
        // Based on user prompt "Use this value to determine whether more pages exist",
        // if it's total pages:
        return _currentPage < paginate;
      }
    }
    
    // Fallback: compare loaded count with total
    return currentLoaded < totalAvailable;
  }

  List<dynamic> _parseContactsResponse(dynamic result) {
    if (result == null || result is! Map) {
      return result is List ? result : [];
    }

    // Use the exact backend path: response.data['client_models']['contacts']
    final clientModels = result['client_models'];
    if (clientModels is Map) {
      final contacts = clientModels['contacts'];
      if (contacts is Map) {
        final contactsList = contacts.values.toList();
        debugPrint('Contacts Map Count: ${contacts.length}');
        return contactsList;
      } else if (contacts is List) {
        debugPrint('Contacts List Count: ${contacts.length}');
        return contacts;
      }
    }

    // Fallback for different API response structures
    final rootContacts = result['contacts'];
    if (rootContacts is Map) {
      final contactsList = rootContacts.values.toList();
      debugPrint('Contacts Map Count (root): ${rootContacts.length}');
      return contactsList;
    } else if (rootContacts is List) {
      debugPrint('Contacts List Count (root): ${rootContacts.length}');
      return rootContacts;
    }

    debugPrint('⚠️ No contacts found in client_models.contacts or contacts field.');
    return [];
  }

  int? _extractTotal(dynamic result) {
    if (result is! Map) return null;
    final data = result['data'] ?? result;
    final clientModels = result['client_models'];
    
    // Check various common total keys
    final paginate = (clientModels is Map ? clientModels['contactsPaginatePage'] : null) ?? 
                     (data is Map ? data['contactsPaginatePage'] : null);
    
    if (paginate is Map) {
      final total = paginate['total'] ?? paginate['total_records'] ?? paginate['count'];
      if (total != null) return _toInt(total);
    }

    final keys = ['total', 'total_records', 'all_contacts_count', 'count', 'contacts_count'];
    for (var key in keys) {
      final val = result[key] ?? (clientModels is Map ? clientModels[key] : null) ?? (data is Map ? data[key] : null);
      if (val != null) return _toInt(val);
    }

    return null;
  }

  int? _toInt(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    if (val is double) return val.toInt();
    return int.tryParse(val.toString());
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
        value.containsKey('mobile_number') ||
        value.containsKey('first_name') ||
        value.containsKey('fname');
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _repository.createContact(
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

      if (result['reaction'] == 0 || result['success'] == false) {
        throw Exception(
          result['message'] ??
              result['data']?['message'] ??
              result['incident'] ??
              'Failed to add contact',
        );
      }

      // Automatically refresh contacts list after creating a new one
      await getContacts();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateContact(
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.updateContact(
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
      
      // Refresh current page to see updates
      await getContacts();
      
      // If we are editing a selected contact, refresh its data too
      if (_selectedContact != null) {
        final uid = _selectedContact!['_uid']?.toString() ?? _selectedContact!['uid']?.toString();
        if (uid == contactUid) {
          // Re-fetch or update local map
          // Since getContact uses phoneNumber/email, we might need a getContactByUid if it exists
          // For now, refreshing list is the primary requirement
        }
      }

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

      await getContacts();
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

  List<dynamic> _extractGroupsFromResponse(dynamic result) {
    if (result is! Map) return _availableGroups;
    final clientModels = result['client_models'];
    if (clientModels is Map) {
      final groups = clientModels['contactGroups'] ?? clientModels['groups'];
      if (groups is List) return groups;
    }
    final data = result['data'];
    if (data is Map) {
      final groups = data['contactGroups'] ?? data['groups'];
      if (groups is List) return groups;
    }
    return _availableGroups;
  }

  List<dynamic> _extractCountriesFromResponse(dynamic result) {
    if (result is! Map) return _availableCountries;
    final clientModels = result['client_models'];
    if (clientModels is Map) {
      final countries = clientModels['countries'];
      if (countries is List) return countries;
    }
    final data = result['data'];
    if (data is Map) {
      final countries = data['countries'];
      if (countries is List) return countries;
    }
    return _availableCountries;
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
