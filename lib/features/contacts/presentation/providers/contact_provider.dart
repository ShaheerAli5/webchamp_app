import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/contact_repository.dart';
import '../../../../core/utils/helpers.dart';

class ContactProvider extends ChangeNotifier {
  final ContactRepository _repository;

  ContactProvider(this._repository);

  CancelToken? _contactsCancelToken;
  CancelToken? _chatCancelToken;

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
  String? _activeRequestSessionId;

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

  String? _activeChatUid;
  String? get activeChatUid => _activeChatUid;

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

  @override
  void dispose() {
    _contactsCancelToken?.cancel("Provider disposed");
    _chatCancelToken?.cancel("Provider disposed");
    _globalUnreadTimer?.cancel();
    super.dispose();
  }

  void clearChat() {
    debugPrint('🧹 [CHAT] Clearing messages and resetting active UID');
    _messages = [];
    _activeChatUid = null;
    _errorMessage = null;
    _chatBoxRetryCount = 0;
    notifyListeners();
  }

  /// Loads locally cached data for instant startup
  Future<void> loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? contactsJson = prefs.getString('cached_contacts_${_activeUserId ?? 'anon'}');
      if (contactsJson != null) {
        final List<dynamic> decoded = jsonDecode(contactsJson);
        if (decoded.isNotEmpty) {
          _contacts = decoded;
          _contactsFullyLoaded = false;
          _hasMore = true;
          debugPrint('💾 [CACHE] Loaded ${_contacts.length} contacts from persistent storage');
          notifyListeners();
        }
      }
      
      final int cachedUnread = prefs.getInt('cached_unread_${_activeUserId ?? 'anon'}') ?? 0;
      if (cachedUnread > 0) {
        _globalUnreadCount = cachedUnread;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ [CACHE] Failed to load persistent cache: $e');
    }
  }

  Future<void> _saveToPersistentCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Cache all contacts for a truly "no restriction" experience
      await prefs.setString('cached_contacts_${_activeUserId ?? 'anon'}', jsonEncode(_contacts));
      await prefs.setInt('cached_unread_${_activeUserId ?? 'anon'}', _globalUnreadCount);
    } catch (e) {
      debugPrint('⚠️ [CACHE] Failed to save persistent cache: $e');
    }
  }

  /// Clears all contact-related data (e.g. on logout/user switch)
  void clearAllData() async {
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
    _activeChatUid = null;
    _globalUnreadCount = 0;
    _contactsFullyLoaded = false;
    _errorMessage = null;
    _activeUserId = null;
    
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('cached_contacts_'); // Partial match would be better but let's be simple

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
    final bool isSearching = search != null && search.isNotEmpty;

    // 🛡️ GUARD: Allow new searches to interrupt current ones, but prevent multiple 
    // loadMore requests from overlapping.
    if (_isFetchingContacts && loadMore && !isRecursiveCall) {
      debugPrint('⏳ [CONTACTS] LoadMore already in progress, skipping.');
      return false;
    }
    
    // 🛡️ Cancel previous contact fetch if a new sequence is starting
    if (!loadMore && !isRecursiveCall) {
      _contactsCancelToken?.cancel("New search/refresh started");
      _contactsCancelToken = CancelToken();

      _activeRequestSessionId = DateTime.now().millisecondsSinceEpoch.toString();
      debugPrint('🆔 [CONTACTS] NEW SESSION: $_activeRequestSessionId (Search: $search)');
    }
    
    final String currentSessionId = _activeRequestSessionId ?? '';
    
    if (loadMore && !_hasMore) return false;
    
    // If not loading more, we are starting a new fetch
    if (!loadMore) {
      _currentPage = 1;
      _hasMore = true;
      
      // 🛡️ CRITICAL FIX: Only clear if search changed or explicitly requested.
      // For background refresh, we keep the list to show cached data.
      bool searchChanged = search != _lastSearch;
      
      if (searchChanged || (isSearching && refresh)) {
        debugPrint('🧹 [CONTACTS] Clearing list for NEW search results');
        _contacts.clear();
        _total = 0;
      } else {
        debugPrint('⏳ [CONTACTS] Refreshing existing list in background...');
      }
      _contactsFullyLoaded = false;
    } else {
      _currentPage++;
    }
    
    _isFetchingContacts = true;
    // Only show full-screen loading if list is empty
    if (_contacts.isEmpty) _isLoading = true;
    _errorMessage = null;
    _lastSearch = search;
    notifyListeners();

    try {
      debugPrint('🚀 [CONTACTS] FETCH START - Page: $_currentPage, Search: $search');
      
      // Use larger perPage when auto-loading all for efficiency
      int effectivePerPage = perPage ?? (autoLoadAll ? 100 : 50);

      var rawResult = await _repository.getContacts(
        search: search,
        page: _currentPage,
        perPage: effectivePerPage,
        refresh: refresh || !loadMore, 
        cancelToken: _contactsCancelToken,
      );
      
      // 🛑 SESSION CHECK: If a new request sequence started, discard this one.
      if (currentSessionId != _activeRequestSessionId) {
        debugPrint('🛑 [CONTACTS] Session mismatch. Discarding Page $_currentPage.');
        return false;
      }
      
      final result = Helpers.sanitizeData(rawResult);
      
      debugPrint('📦 [CONTACTS] RESPONSE RECEIVED for Page $_currentPage');

      List<dynamic> newContacts = _parseContactsResponse(result);
      
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
        } else if (uid != null && existingUids.contains(uid)) {
          // Update existing contact data in-place if found
          final index = _contacts.indexWhere((c) => _extractUid(c) == uid);
          if (index != -1) {
            _contacts[index] = contact;
          }
        }
      }

      // Update pagination state AFTER merging so we know how many were NEW
      _updatePaginationState(result, newContacts.length, addedInThisPage, effectivePerPage);

      // If Page 1 refresh returned fewer items than we had, it might be a user switch or data change
      // In a real app we'd handle this more complexly, but for now we trust the backend Page 1
      if (_currentPage == 1 && !loadMore && newContacts.isNotEmpty && !isSearching) {
        _saveToPersistentCache();
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
      if (autoLoadAll && _hasMore && newContacts.isNotEmpty && _currentPage < 30) {
        debugPrint('⏳ [CONTACTS] Auto-loading next page ($_currentPage + 1)...');
        // 🛡️ Stop if we got a very small page, likely reached the end regardless of has_more
        if (newContacts.length < 5) {
          debugPrint('🛑 [CONTACTS] Small page received, stopping recursion.');
          _hasMore = false;
        } else {
          // 🛡️ Increased delay to respect rate limits during massive background loads
          await Future.delayed(const Duration(milliseconds: 2000));
          return await getContacts(
            search: search, 
            loadMore: true, 
            autoLoadAll: true,
            perPage: effectivePerPage,
            isRecursiveCall: true,
          );
        }
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

  void _updatePaginationState(dynamic result, int newCount, int addedCount, int requestedPerPage) {
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
        // Trust the backend: if we got any contacts, try the next page
        // until we get an empty response.
        _hasMore = newCount > 0;
      }
    } else {
      int? foundTotal = _extractTotal(result);
      if (foundTotal != null) {
        _total = foundTotal;
      }
      
      // 🛡️ GUARD: If we got contacts but none were new, stop to avoid infinite loops
      // especially when cache is returning the same results.
      if (newCount > 0 && addedCount == 0) {
        debugPrint('⚠️ [PAGINATION] No new contacts found in page result. Stopping fetch.');
        _hasMore = false;
      } else {
        _hasMore = newCount > 0;
      }
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
        _globalUnreadCount = _toInt(result['unread_count'] ?? result['data']?['unread_count'] ?? result['client_models']?['unreadMessagesCount']) ?? 0;
        _saveToPersistentCache();
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

  Future<bool> getContactChatBoxData(String contactUid, {bool showLoading = true, bool refresh = false, bool force = false}) async {
    // 🛡️ GUARD: If this is a background polling request for an INACTIVE chat, discard it early
    if (!showLoading && !refresh && !force && _activeChatUid != null && _activeChatUid != contactUid) {
      debugPrint('⏳ [CHAT] Ignoring background polling for inactive chat: $contactUid (Active: $_activeChatUid)');
      return false;
    }

    // 🛡️ GUARD: Only cancel if switching to a DIFFERENT contact
    if (_activeChatUid != contactUid) {
      debugPrint('🔀 [CHAT] Switching from $_activeChatUid to $contactUid. Clearing old messages.');
      _chatCancelToken?.cancel("Switching contact");
      _chatCancelToken = CancelToken();
      _messages = []; // Clear for new contact
      _activeChatUid = contactUid;
      // Notify immediately to show empty/loading state for the new contact
      notifyListeners();
    } else if (refresh || force) {
      debugPrint('🔄 [CHAT] Refreshing data for SAME contact: $contactUid');
    }

    // 🛡️ GUARD: Only prevent overlapping requests for the SAME contact if NOT forced
    if (_isFetchingChat && _selectedContact?['uid'] == contactUid && !force && !refresh) {
      debugPrint('⏳ [CHAT] Skipping overlapping request for $contactUid');
      return false;
    }
    
    _isFetchingChat = true;

    if (showLoading && _messages.isEmpty) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      // 1. Fetch Sidebar and Chat History in parallel
      final results = await Future.wait([
        _repository.getContactChatBoxData(contactUid, refresh: refresh, cancelToken: _chatCancelToken),
        _repository.getChatHistory(contactUid, refresh: refresh, cancelToken: _chatCancelToken).catchError((e) {
          debugPrint('❌ [CHAT] History fetch failed: $e');
          return <String, dynamic>{};
        }),
      ]);

      // 🛑 UID CHECK: If the user switched chats while this request was in flight, discard it.
      if (contactUid != _activeChatUid) {
        debugPrint('🛑 [CHAT] UID mismatch after fetch. Discarding results for $contactUid (Active: $_activeChatUid)');
        _isFetchingChat = false;
        _isLoading = false;
        return false;
      }

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

      // 🛡️ DEDUPLICATE & MERGE MESSAGES
      final Map<String, dynamic> uniqueMap = {};
      debugPrint('🔄 [MERGE] Starting merge. Local messages: ${_messages.length}');
      
      // 1. Start with ALL current local messages to prevent disappearance
      for (var msg in _messages) {
        final id = msg['whatsapp_message_id'] ?? msg['wamid'] ?? msg['_uid'] ?? msg['uid'] ?? msg['timestamp'] ?? msg['created_at'];
        if (id != null) {
          uniqueMap[id.toString()] = msg;
        }
      }

      // 2. Process backend messages and merge/update
      if (rawNewMessages.isNotEmpty) {
        debugPrint('📡 [SYNC] Backend messages received: ${rawNewMessages.length}');
        for (var msg in rawNewMessages) {
          final id = msg['whatsapp_message_id'] ?? msg['wamid'] ?? msg['_uid'] ?? msg['uid'] ?? msg['timestamp'] ?? msg['created_at'];
          if (id != null) {
            final idStr = id.toString();
            
            // If it's an outgoing message, try to match and remove its temp/sent version
            if (msg['is_incoming_message'] == 0 || msg['is_incoming_message'] == '0' || msg['is_incoming_message'] == false) {
              final initialSize = uniqueMap.length;
              uniqueMap.removeWhere((key, m) {
                if (!key.startsWith('temp_') && m['status'] != 'sending' && m['status'] != 'sent') return false;
                
                // Match by text content
                final bool textMatch = (m['message'] == msg['message'] || m['message_body'] == msg['message_body'] || m['text'] == msg['text']);
                if (textMatch && (m['message']?.toString().isNotEmpty ?? false)) {
                  // 🛡️ Added time-window check (2 minutes) to prevent matching wrong messages with same text
                  final mTime = _getDateTime(m);
                  final msgTime = _getDateTime(msg);
                  if (mTime.difference(msgTime).abs().inMinutes < 2) return true;
                }
                
                // Match by media type if both are media
                final String? mType = m['message_type'] ?? m['type'];
                final String? msgType = msg['message_type'] ?? msg['type'];
                if (mType != null && mType == msgType) {
                   // 🛡️ For media, check filename or use a strict time window
                   final mLink = m['__data']?['media_values']?['link']?.toString() ?? '';
                   final msgLink = msg['__data']?['media_values']?['link']?.toString() ?? '';
                   if (mLink.isNotEmpty && msgLink.isNotEmpty && mLink.split('/').last == msgLink.split('/').last) return true;
                   
                   final mTime = _getDateTime(m);
                   final msgTime = _getDateTime(msg);
                   if (mTime.difference(msgTime).abs().inMinutes < 2) return true;
                }
                
                return false;
              });

              if (uniqueMap.length < initialSize) {
                debugPrint('✂️ [MERGE] Deduplicated optimistic message with backend ID: $idStr');
              }
            }
            
            uniqueMap[idStr] = msg;
          } else {
            uniqueMap[msg.hashCode.toString()] = msg;
          }
        }
      }

      // 3. Sort by time (newest first for reversed ListView)
      dedupedList = uniqueMap.values.toList();
      dedupedList.sort((a, b) => _getDateTime(b).compareTo(_getDateTime(a)));
      debugPrint('📊 [MERGE] Final list size: ${dedupedList.length}');

      if (!_isSameMessageList(_messages, dedupedList)) {
        _messages = List.from(dedupedList); // Use a fresh list instance
        hasNewData = true;
        debugPrint('🔔 [UI] Messages updated, triggering rebuild');
        
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

      if (hasNewData || showLoading || force) {
        notifyListeners();
        debugPrint('✅ [CHAT] UI notified of changes (Forced: $force, NewData: $hasNewData)');
        
        // 🛡️ Automatically mark as read if we have messages and it's a selected contact
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
      final errStr = e.toString();
      if ((errStr.contains("Too many requests") || errStr.contains("Too Many Attempts")) && _chatBoxRetryCount < 3) {
        _chatBoxRetryCount++;
        int backoff = 5; 
        if (_chatBoxRetryCount == 2) backoff = 10;
        if (_chatBoxRetryCount == 3) backoff = 20;
        
        debugPrint('🔄 [CHAT] Rate limited. Retry $_chatBoxRetryCount/3 in ${backoff}s...');
        await Future.delayed(Duration(seconds: backoff));
        return await getContactChatBoxData(contactUid, showLoading: showLoading, force: force, refresh: refresh);
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
    if (msg is! Map) return DateTime.now();
    final timeStr = (msg['messaged_at'] ?? msg['created_at'] ?? msg['timestamp'] ?? msg['updated_at'])?.toString();
    if (timeStr == null || timeStr.isEmpty || timeStr == 'null') {
      return DateTime.now();
    }
    return DateTime.tryParse(timeStr) ?? DateTime.now();
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
    final Map<String, dynamic> allMessagesMap = {};
    
    for (final result in results) {
      if (result == null) continue;
      
      List<dynamic> currentResultMessages = [];
      
      if (result is List) {
        currentResultMessages = result;
      } else if (result is Map) {
        final clientModels = result['client_models'];
        if (clientModels is Map) {
          final logs = clientModels['whatsappMessageLogs'];
          if (logs is Map && logs.isNotEmpty) {
            currentResultMessages = logs.values.toList();
          } else if (clientModels['messages'] != null) {
            final msgs = clientModels['messages'];
            currentResultMessages = msgs is Map ? msgs.values.toList() : (msgs is List ? msgs : []);
          }
        }

        if (currentResultMessages.isEmpty) {
          final keys = ['messages', 'chat_messages', 'contactMessages', 'records'];
          for (final key in keys) {
            final val = result[key];
            if (val is List && val.isNotEmpty) {
              currentResultMessages = val;
              break;
            } else if (val is Map && val.isNotEmpty) {
              currentResultMessages = val.values.toList();
              break;
            }
          }
        }
      }
      
      // Add messages from this result to the global map for deduplication
      for (var msg in currentResultMessages) {
        if (msg is Map) {
          final id = msg['whatsapp_message_id'] ?? msg['wamid'] ?? msg['_uid'] ?? msg['uid'] ?? msg['id'];
          if (id != null) {
            allMessagesMap[id.toString()] = msg;
          } else {
            allMessagesMap[msg.hashCode.toString()] = msg;
          }
        }
      }
    }
    
    return allMessagesMap.values.toList();
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
    debugPrint('✅ [SEND] Message inserted locally. Temp ID: $tempId');
    
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
          'created_at': result['created_at'] ?? _messages[index]['created_at'] ?? DateTime.now().toIso8601String(),
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
      getContactChatBoxData(contactUid, showLoading: false, force: true, refresh: true);
      
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

  Future<void> deleteMessage({
    required String contactUid,
    required String messageId,
    required bool forEveryone,
  }) async {
    debugPrint('🗑️ [DELETE] Message ID: $messageId, ForEveryone: $forEveryone');
    
    // 🛡️ Find the message index
    final index = _messages.indexWhere((m) {
      final id = (m['whatsapp_message_id'] ?? m['wamid'] ?? m['_uid'] ?? m['uid']).toString();
      return id == messageId;
    });

    if (index != -1) {
      if (forEveryone) {
        // WhatsApp style: replace content instead of removing
        _messages[index] = {
          ..._messages[index],
          'message': '🚫 This message was deleted',
          'message_body': '🚫 This message was deleted',
          'message_type': 'text',
          'is_deleted': true,
          '__data': null,
          'media_url': null,
        };
        debugPrint('✅ [DELETE] Message replaced with "deleted" status');
      } else {
        _messages.removeAt(index);
        debugPrint('✅ [DELETE] Message removed from local list');
      }
      
      _messages = List.from(_messages);
      notifyListeners();
    }
    
    // Note: single message deletion API not yet available in current repository.
    // Local update provides instant UI feedback as requested.
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
      mediaType: 'voice',
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
        
        // 🛡️ Deep merge __data to preserve optimistic duration/local links
        Map<String, dynamic> mergedData = Map.from(_messages[index]['__data'] ?? {});
        if (result['__data'] is Map) {
          mergedData.addAll(result['__data']);
          
          // Specifically ensure duration is preserved if missing in result
          final oldDuration = _messages[index]['__data']?['media_values']?['duration'];
          if (oldDuration != null && (mergedData['media_values']?['duration'] == null)) {
             mergedData['media_values'] = {
               ...(mergedData['media_values'] ?? {}),
               'duration': oldDuration,
             };
          }
        }

        final Map<String, dynamic> updatedMsg = {
          ..._messages[index],
          ...result,
          if (mergedData.isNotEmpty) '__data': mergedData,
          'status': 'sent',
          'created_at': result['created_at'] ?? _messages[index]['created_at'] ?? DateTime.now().toIso8601String(),
        };
        _messages[index] = updatedMsg;
        _updateContactLatestMessage(contactUid, updatedMsg);
        
        _messages = List.from(_messages); // Force reference change
        notifyListeners();
        debugPrint('🔔 [SEND MEDIA] notifyListeners() for API confirmation');
      }
      
      // Wait a moment for server to process media before refresh
      await Future.delayed(const Duration(seconds: 1));
      debugPrint('🔄 [SEND MEDIA] Triggering background sync (getContactChatBoxData)');
      
      // 🛡️ Manually invalidate cache in the repository if possible
      // (Bypassing via refresh: true for now)
      getContactChatBoxData(contactUid, showLoading: false, force: true, refresh: true);
      return true;
    } catch (e) {
      debugPrint('❌ [SEND MEDIA] Error: $e');
      
      // If we have a specific error message from the backend, show it
      String errorMsg = e.toString().replaceAll('Exception: ', '');
      if (errorMsg.contains('24 hours')) {
        errorMsg = "Cannot send message: 24h window closed. Use a template.";
      }
      
      _messages.removeWhere((m) => m['whatsapp_message_id'] == tempId);
      _messages = List.from(_messages);
      _errorMessage = errorMsg;
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
