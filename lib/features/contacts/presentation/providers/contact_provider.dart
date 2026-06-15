import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../data/repositories/contact_repository.dart';
import '../../../../core/utils/helpers.dart';

class ContactProvider extends ChangeNotifier {
  final ContactRepository _repository;

  ContactProvider(this._repository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isFetchingContacts = false;
  bool _isFetchingChat = false;

  // Bug 6: Flag for contacts loading completion
  bool _contactsFullyLoaded = false;
  bool get contactsFullyLoaded => _contactsFullyLoaded;

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

  // Bug 3: Retry count for chat box data
  int _chatBoxRetryCount = 0;

  void clearChat() {
    _messages = [];
    _errorMessage = null;
    _chatBoxRetryCount = 0;
    notifyListeners();
  }

  // Bug 4: Sanitize text for UTF-16
  String _sanitizeText(String? text) {
    if (text == null) return '';
    return String.fromCharCodes(
      text.runes.where((r) => r <= 0x10FFFF)
    );
  }

  /// Fetches contacts with support for infinite pagination.
  /// If [autoLoadAll] is true, it will keep fetching pages until all are loaded.
  Future<bool> getContacts({
    String? search,
    bool loadMore = false,
    bool autoLoadAll = true,
  }) async {
    // 🛡️ GUARD: Prevent concurrent contact fetching
    if (_isFetchingContacts) return false;
    if (loadMore && !_hasMore) return false;

    if (!loadMore) {
      _currentPage = 1;
      _hasMore = true;
      _contacts.clear();
      _contactsFullyLoaded = false;
    } else {
      _currentPage++;
    }
    
    _isFetchingContacts = true;
    _isLoading = true;
    _errorMessage = null;
    _lastSearch = search;
    notifyListeners();

    try {
      debugPrint('🚀 [CONTACTS] FETCH START - Page: $_currentPage, Search: $search');
      
      // ✅ Exact params matching Postman
      var rawResult = await _repository.getContacts(
        search: search,
        page: _currentPage,
        perPage: 100, 
      );
      
      final result = Helpers.sanitizeData(rawResult);
      
      debugPrint('📦 [CONTACTS] RESPONSE RECEIVED for Page $_currentPage');

      List<dynamic> newContacts = _parseContactsResponse(result);
      debugPrint('✅ [CONTACTS] Parsed ${newContacts.length} contacts from Page $_currentPage');
      
      final existingUids = _contacts.map(_extractUid).toSet();
      for (var contact in newContacts) {
        // Bug 4: Sanitize contact names
        if (contact is Map) {
          contact['first_name'] = _sanitizeText(contact['first_name']?.toString());
          contact['last_name'] = _sanitizeText(contact['last_name']?.toString());
          contact['full_name'] = _sanitizeText(contact['full_name']?.toString());
          contact['name'] = _sanitizeText(contact['name']?.toString());
        }

        final uid = _extractUid(contact);
        if (uid == null || !existingUids.contains(uid)) {
          _contacts.add(contact);
          if (uid != null) existingUids.add(uid);
        }
      }
      
      _updatePaginationState(result, newContacts.length);
      
      debugPrint('📊 [CONTACTS] PAGE SUMMARY: Page $_currentPage, Total loaded: ${_contacts.length}, Has more: $_hasMore');

      _availableGroups = _extractGroupsFromResponse(result);
      _availableCountries = _extractCountriesFromResponse(result);
      
      _isFetchingContacts = false;
      _isLoading = false;
      
      if (!_hasMore) {
        _contactsFullyLoaded = true;
      }
      
      notifyListeners();

      // Bug 1: Add delay between pages and auto-load
      if (autoLoadAll && _hasMore) {
        debugPrint('⏳ [CONTACTS] Waiting 1200ms before next page...');
        await Future.delayed(const Duration(milliseconds: 1200));
        return await getContacts(search: search, loadMore: true, autoLoadAll: true);
      }

      return true;
    } catch (e, stack) {
      debugPrint('❌ [CONTACTS] ERROR: $e');
      
      // Bug 1: Handle rate limit 403
      if (e.toString().contains("Too many requests")) {
        debugPrint('🛑 [CONTACTS] Rate limit hit. Waiting 30s before retry...');
        _isLoading = true;
        notifyListeners();
        await Future.delayed(const Duration(seconds: 30));
        _isFetchingContacts = false;
        _currentPage--; // Reset page to retry the same one
        return await getContacts(search: search, loadMore: loadMore, autoLoadAll: autoLoadAll);
      }

      _errorMessage = e.toString();
      _isFetchingContacts = false;
      _isLoading = false;
      if (loadMore) _currentPage--; 
      notifyListeners();
      return false;
    }
  }

  void _updatePaginationState(dynamic result, int newCount) {
    if (result is! Map) return;

    final clientModels = result['client_models'];
    dynamic paginateInfo = clientModels?['contactsPaginatePage'] ?? 
                          result['pagination'] ?? 
                          result['data']?['pagination'];
    
    if (paginateInfo is Map) {
      _total = _toInt(paginateInfo['total']) ?? 
               _toInt(paginateInfo['total_records']) ?? 
               _toInt(paginateInfo['count']) ?? 
               _total;
      
      final lastPage = _toInt(paginateInfo['last_page']);
      final backendPage = _toInt(paginateInfo['current_page']);
      
      if (paginateInfo.containsKey('has_more_pages')) {
        _hasMore = paginateInfo['has_more_pages'] == true;
      } else if (backendPage != null && lastPage != null) {
        _hasMore = backendPage < lastPage;
      } else {
        _hasMore = _contacts.length < _total;
      }
    } else if (paginateInfo is int) {
      _hasMore = _currentPage < paginateInfo;
      if (_total == 0 || _total < _contacts.length) {
        _total = paginateInfo * 12; 
      }
    } else {
      int? foundTotal = _extractTotal(result);
      if (foundTotal != null) {
        _total = foundTotal;
        _hasMore = _contacts.length < _total;
      } else {
        _hasMore = newCount >= 12;
      }
    }
  }

  String? _extractUid(dynamic contact) {
    if (contact is! Map) return null;
    return (contact['_uid'] ?? contact['uid'] ?? contact['id'] ?? contact['wa_id'])?.toString();
  }

  List<dynamic> _parseContactsResponse(dynamic result) {
    if (result == null) return [];
    if (result is List) return result;

    if (result is Map) {
      final clientModels = result['client_models'];
      if (clientModels is Map) {
        final contactsRaw = clientModels['contacts'];
        if (contactsRaw is Map) {
          return contactsRaw.values.toList();
        } else if (contactsRaw is List) {
          return contactsRaw;
        }
      }

      final data = result['data'];
      if (data is Map) {
        if (data['data'] is List) return data['data'];
        if (data['contacts'] is Map) return (data['contacts'] as Map).values.toList();
        if (data['contacts'] is List) return data['contacts'];
      }
      
      if (result['contacts'] is List) return result['contacts'];
      if (result['contacts'] is Map) return (result['contacts'] as Map).values.toList();
    }
    return [];
  }

  int? _extractTotal(dynamic result) {
    if (result is! Map) return null;
    final keys = ['total', 'total_records', 'all_contacts_count', 'count', 'contacts_count', 'total_count'];
    final sources = [result, result['data'], result['client_models'], result['client_models']?['contactsPaginatePage']];
    for (final source in sources) {
      if (source is Map) {
        for (final key in keys) {
          if (source[key] != null) return _toInt(source[key]);
        }
      }
    }
    return null;
  }

  int? _toInt(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    if (val is double) return val.toInt();
    return int.tryParse(val.toString());
  }

  Future<void> getContactMetadata() async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _repository.getContactMetadata();
      final data = Helpers.sanitizeData(result);
      _availableGroups = _extractGroupsFromResponse(data);
      _availableCountries = _extractCountriesFromResponse(data);
    } catch (e) {
      debugPrint('❌ Metadata error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> getContact({String? phoneNumber, String? email}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _repository.getContact(phoneNumber: phoneNumber, email: email);
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

      final isSuccessful = result['reaction'] == 1 || result['success'] == true || 
                           result['status'] == 'success' || result['result'] == 'success';

      if (!isSuccessful) throw Exception(result['message'] ?? 'Failed to add contact');

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
      await getContacts();
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
      if (result is Map && (result['result'] == 'failed' || result['reaction'] == 0)) {
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

  Future<bool> assignTeamMember({required String phoneNumber, required String usernameOrEmail}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.assignTeamMember(phoneNumber: phoneNumber, usernameOrEmail: usernameOrEmail);
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

  Future<bool> getContactChatBoxData(String contactUid, {bool showLoading = true}) async {
    // 🛡️ GUARD: Prevent overlapping requests
    if (_isFetchingChat) {
      debugPrint('⏳ [CHAT] Skipping overlapping request for $contactUid');
      return false;
    }
    
    _isFetchingChat = true;
    if (showLoading) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      // 1. Get Sidebar Data (Labels/Team)
      final result = await _repository.getContactChatBoxData(contactUid);
      
      // Bug 2: Type cast crash in client_models parser
      final clientModels = result['client_models'];
      final data = result['data'];

      // If clientModels is a List (e.g. []), skip it as per Bug 2
      final dynamic safeClientModels = (clientModels is Map) ? clientModels : null;

      _labels = _extractLargestList([result['labels'], data?['labels'], safeClientModels?['labels']]);
      _teamMembers = _extractLargestList([result['teamMembers'], result['vendorMessagingUsers'], data?['teamMembers']]);

      // 2. Get Chat History
      dynamic chatResult;
      try {
        chatResult = await _repository.getChatHistory(contactUid);
      } catch (e) {
        debugPrint('❌ [CHAT] History fetch failed: $e');
      }

      // 3. Extract and Merge Messages
      final List<dynamic> rawNewMessages = _extractMessagesFromResponse([result, chatResult]);
      debugPrint('✅ [CHAT] Parsed messages: ${rawNewMessages.length}');

      List<dynamic> dedupedList = [];
      bool hasNewData = false;

      // 🛡️ DEDUPLICATE
      if (rawNewMessages.isNotEmpty) {
        final Map<String, dynamic> uniqueMap = {};
        for (var msg in rawNewMessages) {
          final id = msg['whatsapp_message_id'] ?? msg['wamid'] ?? msg['_uid'] ?? msg['uid'] ?? msg['timestamp'] ?? msg['created_at'];
          if (id != null) {
            uniqueMap[id.toString()] = msg;
          } else {
            uniqueMap[msg.hashCode.toString()] = msg;
          }
        }
        dedupedList = uniqueMap.values.toList();
        dedupedList.sort((a, b) => _getDateTime(a).compareTo(_getDateTime(b)));
      } else if (_messages.isEmpty) {
        dedupedList = _messagesFromLoadedContact(contactUid);
      }

      if (!_isSameMessageList(_messages, dedupedList)) {
        _messages = dedupedList;
        hasNewData = true;
      }
      
      // Re-extracting with safety for comparison
      final extractedLabels = _extractLargestList([result['labels'], data?['labels'], safeClientModels?['labels']]);
      if (!listEquals(_labels, extractedLabels)) {
        _labels = extractedLabels;
        hasNewData = true;
      }

      final extractedTeam = _extractLargestList([result['teamMembers'], result['vendorMessagingUsers'], data?['teamMembers']]);
      if (!listEquals(_teamMembers, extractedTeam)) {
        _teamMembers = extractedTeam;
        hasNewData = true;
      }

      _isFetchingChat = false;
      _isLoading = false;
      _chatBoxRetryCount = 0; // Reset retry count on success

      if (hasNewData || showLoading) {
        notifyListeners();
        debugPrint('✅ [CHAT] UI notified of changes');
      } else {
        debugPrint('ℹ️ [CHAT] No changes detected, skipping notifyListeners');
      }

      return true;
    } catch (e) {
      debugPrint('❌ [CHAT] getContactChatBoxData Error: $e');
      _isFetchingChat = false;
      
      // Bug 3: Retry logic with backoff
      if (e.toString().contains("Too many requests") && _chatBoxRetryCount < 3) {
        _chatBoxRetryCount++;
        int backoff = 5; 
        if (_chatBoxRetryCount == 2) backoff = 10;
        if (_chatBoxRetryCount == 3) backoff = 20;
        
        debugPrint('🔄 [CHAT] Retry $_chatBoxRetryCount/3 in ${backoff}s...');
        await Future.delayed(Duration(seconds: backoff));
        return await getContactChatBoxData(contactUid, showLoading: showLoading);
      }

      if (showLoading) {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
        notifyListeners();
      }
      return false;
    }
  }

  DateTime _getDateTime(dynamic msg) {
    if (msg is! Map) return DateTime(1970);
    final timeStr = (msg['messaged_at'] ?? msg['created_at'] ?? msg['timestamp'] ?? msg['updated_at'])?.toString();
    if (timeStr == null) return DateTime(1970);
    return DateTime.tryParse(timeStr) ?? DateTime(1970);
  }

  bool _isSameMessageList(List<dynamic> list1, List<dynamic> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      final m1 = list1[i];
      final m2 = list2[i];
      if (m1 is Map && m2 is Map) {
        final id1 = m1['whatsapp_message_id'] ?? m1['wamid'] ?? m1['_uid'] ?? m1['uid'];
        final id2 = m2['whatsapp_message_id'] ?? m2['wamid'] ?? m2['_uid'] ?? m2['uid'];
        if (id1 != id2) return false;
        if (m1['message'] != m2['message']) return false;
        if (m1['status'] != m2['status']) return false;
      } else if (m1 != m2) {
        return false;
      }
    }
    return true;
  }

  List<dynamic> _extractLargestList(List<dynamic> candidates) {
    final lists = candidates.whereType<List>().toList();
    if (lists.isEmpty) return [];
    lists.sort((a, b) => b.length.compareTo(a.length));
    return lists.first;
  }

  List<dynamic> _extractMessagesFromResponse(List<dynamic> results) {
    for (final result in results) {
      if (result == null) continue;
      if (result is List && result.isNotEmpty) return result;
      if (result is Map) {
        // Priority order
        final keys = ['whatsappMessageLogs', 'messages', 'chat_messages', 'contactMessages', 'data', 'records'];
        for (final key in keys) {
          final val = result[key];
          if (val is List && val.isNotEmpty) {
            debugPrint('🎯 [CHAT] Used key "$key" (List) with ${val.length} messages');
            return val;
          }
          if (val is Map && val.isNotEmpty) {
            debugPrint('🎯 [CHAT] Used key "$key" (Map) with ${val.length} messages');
            return val.values.toList();
          }
        }
      }
    }
    return [];
  }

  List<dynamic> _messagesFromLoadedContact(String contactUid) {
    for (final contact in _contacts) {
      if (contact is! Map) continue;
      final uid = (contact['_uid'] ?? contact['uid'] ?? contact['id'])?.toString();
      if (uid != contactUid) continue;

      final lastMessage = contact['last_message'];
      if (_looksLikeMessage(lastMessage)) return [lastMessage];

      final latestMessageText = contact['latest_message_text'] ?? contact['message'] ?? contact['last_message_text'];
      if (latestMessageText == null || latestMessageText.toString().trim().isEmpty) return [];

      return [{
          'message': latestMessageText.toString(),
          'status': contact['status'] ?? 'received',
          'is_incoming_message': 1,
          'created_at': contact['latest_message'] ?? contact['updated_at'],
      }];
    }
    return [];
  }

  bool _looksLikeMessage(dynamic value) {
    if (value is! Map) return false;
    return value.containsKey('message') || value.containsKey('text') || value.containsKey('body') ||
           value.containsKey('wamid') || value.containsKey('uid');
  }

  Future<bool> sendMessage({required String contactUid, required String message}) async {
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.sendMessage(contactUid: contactUid, message: message);
      await getContactChatBoxData(contactUid, showLoading: false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendTemplateMessage({required String contactUid, required String templateName, required String languageCode}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _repository.sendTemplate(contactUid: contactUid, templateName: templateName, languageCode: languageCode);
      if (result is Map && (result['result'] == 'failed' || result['reaction'] == 0)) throw Exception(result['message'] ?? 'Failed to send template');
      await getContactChatBoxData(contactUid, showLoading: false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendVoiceMessage({required String contactUid, required String filePath}) async {
    _errorMessage = null;
    notifyListeners();
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        _errorMessage = 'Audio file not found';
        notifyListeners();
        return false;
      }
      final uploadResult = await _repository.uploadMedia(filePath, contactUid: contactUid, type: 'audio');
      final fileName = uploadResult['data']?['fileName'] ?? uploadResult['fileName'] ?? uploadResult['data']?['file_name'];
      if (fileName == null) {
        _errorMessage = 'Upload failed';
        notifyListeners();
        return false;
      }
      await _repository.sendMedia(contactUid: contactUid, fileName: fileName.toString(), mediaType: 'audio', isRecordedAudio: true);
      await getContactChatBoxData(contactUid, showLoading: false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendImageMessage({required String contactUid, required String filePath}) async {
    _errorMessage = null;
    notifyListeners();
    try {
      final uploadResult = await _repository.uploadMedia(filePath, contactUid: contactUid, type: 'image');
      final fileName = uploadResult['data']?['fileName'] ?? uploadResult['fileName'];
      if (fileName == null) return false;
      await _repository.sendMedia(contactUid: contactUid, fileName: fileName.toString(), mediaType: 'image');
      await getContactChatBoxData(contactUid, showLoading: false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendVideoMessage({required String contactUid, required String filePath}) async {
    _errorMessage = null;
    notifyListeners();
    try {
      final uploadResult = await _repository.uploadMedia(filePath, contactUid: contactUid, type: 'video');
      final fileName = uploadResult['data']?['fileName'] ?? uploadResult['fileName'];
      if (fileName == null) return false;
      await _repository.sendMedia(contactUid: contactUid, fileName: fileName.toString(), mediaType: 'video');
      await getContactChatBoxData(contactUid, showLoading: false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendDocumentMessage({required String contactUid, required String filePath}) async {
    _errorMessage = null;
    notifyListeners();
    try {
      final uploadResult = await _repository.uploadMedia(filePath, contactUid: contactUid, type: 'document');
      final fileName = uploadResult['data']?['fileName'] ?? uploadResult['fileName'];
      if (fileName == null) return false;
      await _repository.sendMedia(contactUid: contactUid, fileName: fileName.toString(), mediaType: 'document');
      await getContactChatBoxData(contactUid, showLoading: false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> createLabel({required String title, required String textColor, required String bgColor}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.createLabel(title: title, textColor: textColor, bgColor: bgColor);
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

  Future<bool> updateLabel({required String labelUid, required String title, required String textColor, required String bgColor}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.updateLabel(labelUid: labelUid, title: title, textColor: textColor, bgColor: bgColor);
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

  Future<bool> assignLabels({required String contactUid, required List<String> contactLabels}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.assignLabels(contactUid: contactUid, contactLabels: contactLabels);
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
    if (result is! Map) return [];
    final clientModels = result['client_models'];
    final data = result['data'];
    return (clientModels?['contactGroups'] ?? clientModels?['groups'] ?? data?['contactGroups'] ?? data?['groups'] ?? []) as List<dynamic>;
  }

  List<dynamic> _extractCountriesFromResponse(dynamic result) {
    if (result is! Map) return [];
    final clientModels = result['client_models'];
    final data = result['data'] ?? result;
    dynamic found = clientModels?['countries'] ?? clientModels?['all_countries'] ?? data['countries'] ?? data['all_countries'];
    if (found is List) return found;
    if (found is Map) return found.values.toList();
    return [];
  }
}
