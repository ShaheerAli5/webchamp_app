import 'dart:io';
import 'dart:async';
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

  String? _activeUserId;

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

  List<dynamic> _allAvailableLabels = [];
  List<dynamic> get allAvailableLabels => _allAvailableLabels;

  List<dynamic> _messages = [];
  List<dynamic> get messages => _messages;

  String? _selectedLabel;
  String? get selectedLabel => _selectedLabel;

  void setSelectedLabel(String? label) {
    _selectedLabel = label;
    debugPrint('🏷️ [LABELS] Selected filter label: $label');
    notifyListeners();
  }

  /// Filters contacts based on selected label
  List<dynamic> get filteredContacts {
    if (_selectedLabel == null || _selectedLabel == 'all' || _selectedLabel!.isEmpty) {
      return _contacts;
    }
    
    final filtered = _contacts.where((contact) {
      final contactLabels = contact['labels'];
      if (contactLabels is List) {
        return contactLabels.any((label) {
          final title = (label is Map ? label['title'] : label.toString()).toLowerCase();
          return title == _selectedLabel!.toLowerCase();
        });
      }
      return false;
    }).toList();
    
    debugPrint('🏷️ [LABELS] Filtered contacts count: ${filtered.length} for label: $_selectedLabel');
    return filtered;
  }

  int _globalUnreadCount = 0;
  int get globalUnreadCount => _globalUnreadCount;

  Timer? _globalUnreadTimer;

  // Bug 3: Retry count for chat box data
  int _chatBoxRetryCount = 0;

  void startGlobalUnreadPolling() {
    _globalUnreadTimer?.cancel();
    _globalUnreadTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      getGlobalUnreadCount();
    });
  }

  void stopGlobalUnreadPolling() {
    _globalUnreadTimer?.cancel();
    _globalUnreadTimer = null;
  }

  void clearChat() {
    _messages = [];
    _errorMessage = null;
    _chatBoxRetryCount = 0;
    notifyListeners();
  }

  /// Clears all contact-related data (e.g. on logout/user switch)
  void clearAllData() {
    debugPrint('🧹 [CONTACTS] Clearing all provider data');
    _repository.clear();
    _contacts = [];
    _availableGroups = [];
    _availableCountries = [];
    _total = 0;
    _currentPage = 1;
    _hasMore = true;
    _lastSearch = null;
    _selectedContact = null;
    _labels = [];
    _teamMembers = [];
    _allAvailableLabels = [];
    _messages = [];
    _globalUnreadCount = 0;
    _contactsFullyLoaded = false;
    _errorMessage = null;
    _activeUserId = null;
    debugPrint('📊 After User Switch: ${_contacts.length} contacts remaining');
    notifyListeners();
  }

  void setActiveUser(String? userId) {
    _activeUserId = userId;
  }

  // Bug 4: Sanitize text for UTF-16
  String _sanitizeText(String? text) {
    return Helpers.sanitizeString(text);
  }

  /// Fetches contacts with support for infinite pagination.
  /// If [autoLoadAll] is true, it will keep fetching pages until all are loaded.
  Future<bool> getContacts({
    String? search,
    bool loadMore = false,
    bool autoLoadAll = true,
    bool refresh = false,
    int? perPage,
    bool isRecursiveCall = false, // Internal flag to bypass guard
  }) async {
    // 🛡️ GUARD: Prevent concurrent contact fetching unless it's a recursive call
    if (_isFetchingContacts && !isRecursiveCall) {
      debugPrint('⏳ [CONTACTS] Fetch already in progress, skipping start.');
      return false;
    }
    
    if (loadMore && !_hasMore) return false;
    
    // If not loading more, we are starting a new fetch
    if (!loadMore) {
      _currentPage = 1;
      _hasMore = true;
      if (refresh) {
        _contacts.clear();
      }
      _contactsFullyLoaded = false;
    } else {
      _currentPage++;
    }
    
    _isFetchingContacts = true;
    if (_contacts.isEmpty) _isLoading = true;
    _errorMessage = null;
    _lastSearch = search;
    notifyListeners();

    try {
      debugPrint('🚀 [CONTACTS] FETCH START - Page: $_currentPage, Search: $search');
      
      var rawResult = await _repository.getContacts(
        search: search,
        page: _currentPage,
        perPage: perPage ?? 50, // Use 50 as default to reduce API pressure
        refresh: refresh || !loadMore, 
      );
      
      final result = Helpers.sanitizeData(rawResult);
      
      debugPrint('📦 [CONTACTS] RESPONSE RECEIVED for Page $_currentPage');

      List<dynamic> newContacts = _parseContactsResponse(result);
      
      // 🏷️ [LABELS] Extract global labels from the contacts response if available
      final dynamic clientModels = result['client_models'];
      final dynamic data = result['data'];
      final dynamic safeClientModels = (clientModels is Map) ? clientModels : null;
      
      final globalLabels = _extractLargestList([
        result['listOfAllLabels'], 
        data?['listOfAllLabels'], 
        result['allLabels'],
        safeClientModels?['listOfAllLabels'],
        safeClientModels?['allLabels'],
      ]);
      
      if (globalLabels.isNotEmpty) {
        _allAvailableLabels = globalLabels;
        debugPrint('🏷️ [LABELS] Loaded ${_allAvailableLabels.length} global labels');
      }
      
      // Update pagination state BEFORE merging to get correct _total and _hasMore from backend
      _updatePaginationState(result, newContacts.length);

      final existingUids = _contacts.map(_extractUid).whereType<String>().toSet();
      int addedInThisPage = 0;

      for (var contact in newContacts) {
        if (contact is Map) {
          contact['first_name'] = _sanitizeText(contact['first_name']?.toString());
          contact['last_name'] = _sanitizeText(contact['last_name']?.toString());
          contact['full_name'] = _sanitizeText(contact['full_name']?.toString());
          contact['name'] = _sanitizeText(contact['name']?.toString());
        }

        final uid = _extractUid(contact);
        if (uid != null && !existingUids.contains(uid)) {
          _contacts.add(contact);
          addedInThisPage++;
          existingUids.add(uid);
        }
      }
      
      // ✅ VERIFICATION LOGS
      debugPrint('----------------------------------------');
      debugPrint('📊 [CONTACTS VERIFICATION]');
      debugPrint('Logged User ID: ${_activeUserId ?? 'Unknown'}');
      debugPrint('Backend Contact Count (Total): $_total');
      debugPrint('Parsed Contact Count (Page): ${newContacts.length}');
      debugPrint('UI Contact Count (Current List): ${_contacts.length}');
      debugPrint('Cache Contact Count: ${_repository.cacheCount}');
      debugPrint('New contacts added (deduplicated): $addedInThisPage');
      debugPrint('Has More (from Backend): $_hasMore');
      debugPrint('----------------------------------------');

      _availableGroups = _extractGroupsFromResponse(result);
      _availableCountries = _extractCountriesFromResponse(result);
      
      // ✅ AUTOMATIC RECURSIVE FETCHING - Only if backend says there is more
      if (autoLoadAll && _hasMore && newContacts.isNotEmpty && addedInThisPage > 0) {
        debugPrint('⏳ [CONTACTS] Auto-loading next page ($_currentPage + 1)...');
        await Future.delayed(const Duration(milliseconds: 200));
        return await getContacts(
          search: search, 
          loadMore: true, 
          autoLoadAll: true,
          perPage: perPage,
          isRecursiveCall: true,
        );
      }

      // Finalize loading
      _isFetchingContacts = false;
      _isLoading = false;
      
      if (!_hasMore) {
        _contactsFullyLoaded = true;
      }
      
      // Only poll global unread when the entire load sequence finishes to save API calls
      if (!isRecursiveCall) {
        getGlobalUnreadCount();
      }
      
      notifyListeners();
      return true;
    } catch (e, stack) {
      debugPrint('❌ [CONTACTS] ERROR: $e');
      
      // Handle rate limit 429
      if (e.toString().contains("Too Many Attempts") || e.toString().contains("429")) {
        debugPrint('🛑 [CONTACTS] Rate limit hit. Waiting 30s before retry...');
        _isLoading = true;
        notifyListeners();
        await Future.delayed(const Duration(seconds: 30));
        _isFetchingContacts = false;
        _currentPage--; // Reset page to retry the same one
        return await getContacts(
          search: search, 
          loadMore: loadMore, 
          autoLoadAll: autoLoadAll,
          isRecursiveCall: true,
        );
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
        _hasMore = newCount > 0;
      }
    } else {
      int? foundTotal = _extractTotal(result);
      if (foundTotal != null) {
        _total = foundTotal;
      }
      // Always base hasMore on whether we actually got contacts
      _hasMore = newCount > 0;
    }

    // 🛡️ Debug Verification
    debugPrint('📊 [PAGINATION DEBUG]');
    debugPrint('   - Backend Total: $_total');
    debugPrint('   - Parsed Count (This page): $newCount');
    debugPrint('   - Total in List: ${_contacts.length}');
    debugPrint('   - Has More: $_hasMore');
  }

  String? _extractUid(dynamic contact) {
    if (contact is! Map) return null;
    // 🛡️ [UID EXTRACTION] Try multiple keys to find a unique identifier
    final uid = contact['_uid'] ?? 
                contact['uid'] ?? 
                contact['id'] ?? 
                contact['wa_id'] ?? 
                contact['phone_number'] ?? 
                contact['mobile_number'];
    return uid?.toString();
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
    final keys = [
      'total', 'total_records', 'totalRecords', 'all_contacts_count', 
      'count', 'contacts_count', 'total_count', 'totalCount'
    ];
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

  Future<void> getGlobalUnreadCount() async {
    try {
      final result = await _repository.getUnreadCount();
      if (result is Map) {
        _globalUnreadCount = _toInt(result['unread_count'] ?? result['data']?['unread_count']) ?? 0;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Global unread count error: $e');
    }
  }

  Future<void> markContactAsRead(String contactUid) async {
    // 🛡️ Guard: Only mark as read if it actually has unread messages locally
    bool hasUnread = false;
    for (var contact in _contacts) {
      if (contact is Map && (contact['_uid'] ?? contact['uid']) == contactUid) {
        hasUnread = (contact['unread_messages_count'] ?? 0) > 0;
        break;
      }
    }
    
    if (!hasUnread) return;

    debugPrint('📩 [MARK READ] Local clear for Contact: $contactUid');
    
    // 1. Update local state immediately for UI responsiveness
    for (var contact in _contacts) {
      if (contact is Map && (contact['_uid'] ?? contact['uid']) == contactUid) {
        contact['unread_messages_count'] = 0;
      }
    }
    notifyListeners();

    // 2. Refresh global unread count
    await getGlobalUnreadCount();
    
    // Note: Removed mark-as-read API call as it returned 404.
    // Backend likely handles this automatically or via a different endpoint.
  }

  Future<bool> getContactChatBoxData(String contactUid, {bool showLoading = true, bool refresh = false}) async {
    // 🛡️ GUARD: Only prevent overlapping requests for the SAME contact
    // If it's a new contact, allow it.
    if (_isFetchingChat && _selectedContact?['uid'] == contactUid) {
      debugPrint('⏳ [CHAT] Skipping overlapping request for $contactUid');
      return false;
    }
    
    _isFetchingChat = true;
    
    // Clear messages if switching contacts to avoid flickering
    if (_selectedContact != null && (_selectedContact!['_uid'] ?? _selectedContact!['uid'])?.toString() != contactUid) {
      _messages = [];
    }

    if (showLoading && _messages.isEmpty) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      // 1. Fetch Sidebar and Chat History in parallel
      final results = await Future.wait([
        _repository.getContactChatBoxData(contactUid, refresh: refresh),
        _repository.getChatHistory(contactUid, refresh: refresh).catchError((e) {
          debugPrint('❌ [CHAT] History fetch failed: $e');
          return <String, dynamic>{};
        }),
      ]);

      final result = results[0];
      final chatResult = results[1];
      
      // Bug 2: Type cast crash in client_models parser
      final clientModels = result['client_models'];
      final data = result['data'];

      // If clientModels is a List (e.g. []), skip it as per Bug 2
      final dynamic safeClientModels = (clientModels is Map) ? clientModels : null;

      _labels = _extractLargestList([result['labels'], data?['labels'], safeClientModels?['labels']]);
      _teamMembers = _extractLargestList([result['teamMembers'], result['vendorMessagingUsers'], data?['teamMembers']]);
      
      _allAvailableLabels = _extractLargestList([
        result['listOfAllLabels'], 
        data?['listOfAllLabels'], 
        result['allLabels'],
        safeClientModels?['listOfAllLabels'],
        safeClientModels?['allLabels'],
      ]);

      // 3. Extract and Merge Messages
      final List<dynamic> rawNewMessages = _extractMessagesFromResponse([result, chatResult]);
      debugPrint('✅ [CHAT] Parsed messages: ${rawNewMessages.length}');
      
      // 🛡️ Log incoming message status for debugging read/unread
      if (rawNewMessages.isNotEmpty) {
        final firstMsg = rawNewMessages.first;
        if (firstMsg is Map) {
          debugPrint('ℹ️ [CHAT] Latest message status: ${firstMsg['status']}, is_incoming: ${firstMsg['is_incoming_message']}');
        }
      }

      List<dynamic> dedupedList = [];
      bool hasNewData = false;

      // 🛡️ DEDUPLICATE & MERGE OPTIMISTIC MESSAGES
      final Map<String, dynamic> uniqueMap = {};
      
      // 1. Keep any local messages in 'sending' or 'uploading' status
      for (var msg in _messages) {
        if (msg is Map && (msg['status'] == 'sending' || msg['status'] == 'uploading')) {
          final id = msg['whatsapp_message_id'] ?? msg['wamid'] ?? msg['_uid'] ?? msg['uid'];
          if (id != null) {
            uniqueMap[id.toString()] = msg;
          }
        }
      }

      // 2. Process backend messages
      if (rawNewMessages.isNotEmpty) {
        for (var msg in rawNewMessages) {
          final id = msg['whatsapp_message_id'] ?? msg['wamid'] ?? msg['_uid'] ?? msg['uid'] ?? msg['timestamp'] ?? msg['created_at'];
          if (id != null) {
            final idStr = id.toString();
            // deduplication by content for recent outgoing messages
            if (msg['is_incoming_message'] == 0 || msg['is_incoming_message'] == '0' || msg['is_incoming_message'] == false) {
              uniqueMap.removeWhere((key, m) => 
                key.startsWith('temp_') && 
                m['status'] == 'sending' && 
                (m['message'] == msg['message'] || m['message_body'] == msg['message_body'])
              );
            }
            uniqueMap[idStr] = msg;
          } else {
            uniqueMap[msg.hashCode.toString()] = msg;
          }
        }
        dedupedList = uniqueMap.values.toList();
        dedupedList.sort((a, b) => _getDateTime(b).compareTo(_getDateTime(a)));
      } else if (_messages.isNotEmpty && uniqueMap.isNotEmpty) {
        // If API returned nothing (maybe error), but we have local messages, keep what we have
        dedupedList = List.from(_messages);
      } else if (_messages.isEmpty) {
        dedupedList = _messagesFromLoadedContact(contactUid);
      } else {
        // Fallback: keep current messages if API returned empty
        dedupedList = List.from(_messages);
      }

      if (!_isSameMessageList(_messages, dedupedList)) {
        _messages = List.from(dedupedList); // Use a fresh list instance
        hasNewData = true;
        
        // 🛡️ Update contact's latest message in the list for sorting
        if (_messages.isNotEmpty) {
          _updateContactLatestMessage(contactUid, _messages.first);
        }
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
        
        // 🛡️ Automatically mark as read if we have messages and it's a selected contact
        // We do this after notification to ensure UI shows the latest state.
        if (_messages.isNotEmpty) {
          markContactAsRead(contactUid);
        }
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
        // Priority 1: client_models > whatsappMessageLogs (WabChamp chat-data endpoint)
        final clientModels = result['client_models'];
        if (clientModels is Map) {
          final logs = clientModels['whatsappMessageLogs'];
          if (logs is Map && logs.isNotEmpty) {
            debugPrint('🎯 [CHAT] Used whatsappMessageLogs with ${logs.length} messages');
            return logs.values.toList();
          }
          final msgs = clientModels['messages'];
          if (msgs is List && msgs.isNotEmpty) return msgs;
          if (msgs is Map && msgs.isNotEmpty) return msgs.values.toList();
        }

        // Priority 2: Standard keys
        final keys = ['messages', 'chat_messages', 'contactMessages', 'records'];
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

  Future<bool> sendMessage({
    required String contactUid, 
    required String message,
    String? replyToMessageId,
  }) async {
    _errorMessage = null;
    debugPrint('🚀 [SEND] Starting sendMessage. Provider: ${hashCode}');
    debugPrint('📊 [SEND] Messages before: ${_messages.length}');
    
    // 🛡️ OPTIMISTIC UPDATE: Add message to UI immediately
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMessage = {
      'whatsapp_message_id': tempId,
      'message': message,
      'message_body': message,
      'status': 'sending',
      'is_incoming_message': 0,
      'created_at': DateTime.now().toIso8601String(),
      if (replyToMessageId != null) 'reply_to_message_id': replyToMessageId,
    };
    
    // Create a fresh list for the UI to detect change
    _messages = [optimisticMessage, ..._messages];
    debugPrint('📊 [SEND] Messages after optimistic insert: ${_messages.length}');
    
    // Update contact's latest message locally for sorting
    _updateContactLatestMessage(contactUid, optimisticMessage);
    
    notifyListeners();
    debugPrint('🔔 [SEND] notifyListeners() called for optimistic update');

    try {
      // Find contact to get wa_id
      String? waId;
      try {
        final contact = _contacts.firstWhere(
          (c) => (c['_uid'] ?? c['uid'] ?? c['id'])?.toString() == contactUid,
        );
        waId = (contact['wa_id'] ?? contact['phone_number'])?.toString();
      } catch (_) {}

      debugPrint('📡 [SEND] Calling API repository.sendMessage...');
      final result = await _repository.sendMessage(
        contactUid: contactUid, 
        message: message,
        waId: waId,
        replyToMessageId: replyToMessageId,
      );
      
      debugPrint('✅ [SEND] API Success. Response: $result');
      
      // Update the temp message with real data from response if available
      final index = _messages.indexWhere((m) => m['whatsapp_message_id'] == tempId);
      if (index != -1 && result is Map) {
        debugPrint('🔄 [SEND] Updating temp message at index $index');
        final Map<String, dynamic> updatedMsg = {
          ..._messages[index],
          ...result,
          'status': 'sent',
        };
        _messages[index] = updatedMsg;
        _updateContactLatestMessage(contactUid, updatedMsg);
        
        // Re-assign to force list reference change
        _messages = List.from(_messages);
        notifyListeners();
        debugPrint('🔔 [SEND] notifyListeners() called for API confirmation');
      } else {
        debugPrint('⚠️ [SEND] Could not find temp message to update or result is not Map');
      }
      
      // Full background refresh to stay in sync with server state
      debugPrint('🔄 [SEND] Triggering background sync (getContactChatBoxData)');
      getContactChatBoxData(contactUid, showLoading: false);
      
      return true;
    } catch (e) {
      debugPrint('❌ [SEND] Error: $e');
      _messages.removeWhere((m) => m['whatsapp_message_id'] == tempId);
      _messages = List.from(_messages); // Force rebuild on error cleanup
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void _updateContactLatestMessage(String contactUid, Map<String, dynamic> message) {
    final contactIndex = _contacts.indexWhere(
      (c) => (c['_uid'] ?? c['uid'] ?? c['id'])?.toString() == contactUid,
    );
    
    if (contactIndex != -1) {
      final contact = Map<String, dynamic>.from(_contacts[contactIndex]);
      contact['last_message'] = message;
      contact['latest_message'] = message['created_at'];
      _contacts[contactIndex] = contact;
      
      // Sort contacts by latest message
      _contacts.sort((a, b) {
        final timeA = Helpers.toPKT(a['latest_message']);
        final timeB = Helpers.toPKT(b['latest_message']);
        return timeB.compareTo(timeA);
      });
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

  Future<bool> sendVoiceMessage({
    required String contactUid, 
    required String filePath,
    int? duration,
  }) async {
    return _sendMediaOptimistic(
      contactUid: contactUid,
      filePath: filePath,
      mediaType: 'audio',
      duration: duration,
    );
  }

  Future<bool> sendImageMessage({required String contactUid, required String filePath}) async {
    return _sendMediaOptimistic(
      contactUid: contactUid,
      filePath: filePath,
      mediaType: 'image',
    );
  }

  Future<bool> sendVideoMessage({required String contactUid, required String filePath}) async {
    return _sendMediaOptimistic(
      contactUid: contactUid,
      filePath: filePath,
      mediaType: 'video',
    );
  }

  Future<bool> sendDocumentMessage({required String contactUid, required String filePath}) async {
    return _sendMediaOptimistic(
      contactUid: contactUid,
      filePath: filePath,
      mediaType: 'document',
    );
  }

  Future<bool> _sendMediaOptimistic({
    required String contactUid,
    required String filePath,
    required String mediaType,
    int? duration,
  }) async {
    _errorMessage = null;
    debugPrint('🚀 [SEND MEDIA] Starting media send. Provider: ${hashCode}');
    
    final tempId = 'temp_media_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMessage = {
      'whatsapp_message_id': tempId,
      'message': 'Media',
      'message_body': 'Media',
      'status': 'sending',
      'is_incoming_message': 0,
      'created_at': DateTime.now().toIso8601String(),
      'message_type': mediaType,
      '__data': {
        'media_values': {
          'link': filePath, // Use local path for preview
          'type': mediaType,
          if (duration != null) 'duration': duration,
        }
      }
    };
    
    _messages = [optimisticMessage, ..._messages];
    _updateContactLatestMessage(contactUid, optimisticMessage);
    notifyListeners();
    debugPrint('🔔 [SEND MEDIA] notifyListeners() for optimistic update. Count: ${_messages.length}');

    try {
      String? waId;
      try {
        final contact = _contacts.firstWhere(
          (c) => (c['_uid'] ?? c['uid'] ?? c['id'])?.toString() == contactUid,
        );
        waId = (contact['wa_id'] ?? contact['phone_number'])?.toString();
      } catch (_) {}

      debugPrint('📡 [SEND MEDIA] Calling API repository.sendMedia...');
      final result = await _repository.sendMedia(
        contactUid: contactUid,
        filePath: filePath,
        mediaType: mediaType,
        waId: waId,
      );
      
      debugPrint('✅ [SEND MEDIA] API Success. Response: $result');
      
      final index = _messages.indexWhere((m) => m['whatsapp_message_id'] == tempId);
      if (index != -1 && result is Map) {
        debugPrint('🔄 [SEND MEDIA] Updating temp message at index $index');
        final Map<String, dynamic> updatedMsg = {
          ..._messages[index],
          ...result,
          'status': 'sent',
        };
        _messages[index] = updatedMsg;
        _updateContactLatestMessage(contactUid, updatedMsg);
        
        _messages = List.from(_messages); // Force reference change
        notifyListeners();
        debugPrint('🔔 [SEND MEDIA] notifyListeners() for API confirmation');
      }
      
      // Wait a moment for server to process media before refresh
      await Future.delayed(const Duration(seconds: 2));
      debugPrint('🔄 [SEND MEDIA] Triggering background sync (getContactChatBoxData)');
      getContactChatBoxData(contactUid, showLoading: false);
      return true;
    } catch (e) {
      debugPrint('❌ [SEND MEDIA] Error: $e');
      _messages.removeWhere((m) => m['whatsapp_message_id'] == tempId);
      _messages = List.from(_messages);
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> createLabel({required String title, required String textColor, required String bgColor}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      debugPrint('🏷️ [LABELS] Creating new label: $title');
      await _repository.createLabel(title: title, textColor: textColor, bgColor: bgColor);
      
      // Refresh labels list - we use the currently selected contact to refresh available labels
      if (_selectedContact != null) {
        final uid = (_selectedContact!['_uid'] ?? _selectedContact!['uid'])?.toString();
        if (uid != null) {
          await getContactChatBoxData(uid, showLoading: false);
        }
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
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

  Future<bool> assignLabels({required String contactUid, required List<String> labels}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    debugPrint('🏷️ [LABELS] Selected Contact UID: $contactUid');
    debugPrint('🏷️ [LABELS] Selected Labels: $labels');

    try {
      final result = await _repository.assignLabels(contactUid: contactUid, labels: labels);
      
      final isSuccessful = result['reaction'] == 1 || result['success'] == true || 
                           result['status'] == 'success' || result['result'] == 'success';

      if (!isSuccessful) throw Exception(result['message'] ?? 'Failed to assign labels');

      // Refresh assigned labels for the current contact
      await getContactChatBoxData(contactUid, showLoading: false);
      
      // Update the contact in the main list immediately for filtering/UI
      final index = _contacts.indexWhere((c) => _extractUid(c) == contactUid);
      if (index != -1) {
        final updatedContact = Map<String, dynamic>.from(_contacts[index]);
        updatedContact['labels'] = List.from(_labels);
        _contacts[index] = updatedContact;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
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
