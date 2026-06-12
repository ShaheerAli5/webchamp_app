import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/repositories/contact_repository.dart';
import '../../../../core/utils/helpers.dart';

class ContactProvider extends ChangeNotifier {
  final ContactRepository _repository;

  ContactProvider(this._repository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

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
      
      // We pass perPage=1000 but the backend seems to force 12.
      var rawResult = await _repository.getContacts(
        search: search,
        page: _currentPage,
        perPage: 1000, 
      );
      
      final result = Helpers.sanitizeData(rawResult);
      
      // ✅ REQUIREMENT 8: Log Full API Response Structure
      debugPrint('📦 [CONTACTS] RESPONSE RECEIVED for Page $_currentPage');
      debugPrint('🔑 Keys found in root: ${result.keys.toList()}');
      if (result['client_models'] != null) {
        debugPrint('🔑 Keys found in client_models: ${result['client_models'].keys.toList()}');
      }

      // ✅ REQUIREMENT 9: Precise parsing of Map-keyed contacts
      List<dynamic> newContacts = _parseContactsResponse(result);
      debugPrint('✅ [CONTACTS] Parsed ${newContacts.length} contacts from Page $_currentPage');
      
      // Deduplicate and add
      final existingUids = _contacts.map(_extractUid).toSet();
      int addedThisPage = 0;
      for (var contact in newContacts) {
        final uid = _extractUid(contact);
        if (uid == null || !existingUids.contains(uid)) {
          _contacts.add(contact);
          if (uid != null) existingUids.add(uid);
          addedThisPage++;
        }
      }
      
      // ✅ REQUIREMENT 8: Specific metadata prints
      _updatePaginationState(result, newContacts.length);
      
      debugPrint('📊 [CONTACTS] PAGE SUMMARY:');
      debugPrint('   - Current Page: $_currentPage');
      debugPrint('   - Contacts on this page: ${newContacts.length}');
      debugPrint('   - Total loaded so far: ${_contacts.length}');
      debugPrint('   - Total on server (extracted): $_total');
      debugPrint('   - Has more pages: $_hasMore');

      // Extract metadata (countries/groups)
      _availableGroups = _extractGroupsFromResponse(result);
      _availableCountries = _extractCountriesFromResponse(result);
      
      _isFetchingContacts = false;
      _isLoading = false;
      notifyListeners();

      // ✅ REQUIREMENT 4: Automatically load all pages
      if (autoLoadAll && _hasMore) {
        debugPrint('🔄 [CONTACTS] Auto-loading next page...');
        return await getContacts(search: search, loadMore: true, autoLoadAll: true);
      }

      return true;
    } catch (e, stack) {
      debugPrint('❌ [CONTACTS] ERROR: $e');
      debugPrint('StackTrace: $stack');
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

    // Check client_models.contactsPaginatePage (User log showed 3 here)
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
      // ✅ If it's just an integer (Total Pages)
      debugPrint('ℹ️ [CONTACTS] Pagination info found as integer (Total Pages): $paginateInfo');
      _hasMore = _currentPage < paginateInfo;
      // If we don't have a total, estimate it for the UI counter
      if (_total == 0 || _total < _contacts.length) {
        _total = paginateInfo * 12; // 12 seems to be the server's hardcoded page size
      }
    } else {
      // Fallback: Use total keys from everywhere
      int? foundTotal = _extractTotal(result);
      if (foundTotal != null) {
        _total = foundTotal;
        _hasMore = _contacts.length < _total;
      } else {
        // If we received a "full" page of 12, assume there's more
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
    if (showLoading) {
      _isLoading = true;
      _errorMessage = null;
      _messages = [];
      notifyListeners();
    }
    try {
      final result = await _repository.getContactChatBoxData(contactUid);
      final clientModels = result['client_models'];
      final data = result['data'];

      _labels = _extractLargestList([result['labels'], data?['labels'], clientModels?['labels']]);
      _teamMembers = _extractLargestList([result['teamMembers'], result['vendorMessagingUsers'], data?['teamMembers']]);

      dynamic chatResult;
      try {
        chatResult = await _repository.getChatHistory(contactUid);
      } catch (e) {
        debugPrint('❌ Chat history failed: $e');
      }

      _messages = _extractMessagesFromResponse([result, chatResult]);

      if (_messages.isNotEmpty) {
        _messages.sort((a, b) {
          final aTime = (a['created_at'] ?? a['messaged_at'] ?? a['timestamp'] ?? '').toString();
          final bTime = (b['created_at'] ?? b['messaged_at'] ?? b['timestamp'] ?? '').toString();
          return bTime.compareTo(aTime);
        });
      } else {
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
        final keys = ['whatsappMessageLogs', 'messages', 'chat_messages', 'data', 'records'];
        for (final key in keys) {
          final val = result[key];
          if (val is List && val.isNotEmpty) return val;
          if (val is Map && val.isNotEmpty) return val.values.toList();
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
