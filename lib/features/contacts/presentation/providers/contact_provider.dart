import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/utils/helpers.dart';
import '../../data/repositories/contact_repository.dart';
import 'package:video_compress/video_compress.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ContactProvider extends ChangeNotifier {
  final ContactRepository _repository;

  ContactProvider(this._repository);

  CancelToken? _contactsCancelToken;
  CancelToken? _chatCancelToken;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isFetchingContacts = false;
  bool get isFetchingContacts => _isFetchingContacts;
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

  int _chatPage = 1;
  bool _hasMoreChat = true;
  bool get hasMoreChat => _hasMoreChat;
  bool _isLoadingMoreChat = false;
  bool get isLoadingMoreChat => _isLoadingMoreChat;

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
  Timer? _unreadSyncTimer;

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
    _unreadSyncTimer?.cancel();
  }

  void _debouncedGlobalUnreadSync() {
    _unreadSyncTimer?.cancel();
    _unreadSyncTimer = Timer(const Duration(seconds: 2), () {
      getGlobalUnreadCount();
    });
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
      // Optimization: jsonEncode can be heavy for large lists, but isolate overhead
      // might be more for smaller ones. Contacts list can be huge.
      final String encoded = await compute(jsonEncode, _contacts);
      await prefs.setString('cached_contacts_${_activeUserId ?? 'anon'}', encoded);
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
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (String key in keys) {
        if (key.startsWith('cached_contacts_') || key.startsWith('cached_unread_')) {
          prefs.remove(key);
        }
      }
    } catch (e) {
      debugPrint('⚠️ [CACHE] Failed to clear persistent cache: $e');
    }

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

    // 🛡️ OPTIMIZATION: If already fully loaded and not a refresh/search, 
    // just do a quick page 1 refresh instead of auto-loading thousands again.
    if (autoLoadAll && _contactsFullyLoaded && !refresh && !isSearching && !loadMore) {
      debugPrint('ℹ️ [CONTACTS] Already fully loaded. Switching to background page 1 sync.');
      autoLoadAll = false; 
    }

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
      int effectivePerPage = perPage ?? (autoLoadAll ? 100 : 50);

      // 🚀 OPTIMIZATION (Fix 1 & 2): Parallel Batch Loading
      // Use parallel fetching only for initial background load (not searching, not manual loadMore)
      if (autoLoadAll && !loadMore && !isSearching) {
        return await _fetchAllContactsParallel(search, effectivePerPage, refresh, currentSessionId);
      }

      var rawResult = await _repository.getContacts(
        search: search,
        page: _currentPage,
        perPage: effectivePerPage,
        refresh: refresh || !loadMore, 
        cancelToken: _contactsCancelToken,
      );
      
      // 🛡️ SESSION CHECK: If a new request sequence started, discard this one.
      if (currentSessionId != _activeRequestSessionId) {
        debugPrint('🛑 [CONTACTS] Session mismatch. Discarding Page $_currentPage.');
        return false;
      }
      
      final result = Helpers.sanitizeData(rawResult);
      List<dynamic> newContacts = _parseContactsResponse(result);
      _updatePaginationState(result, newContacts.length, effectivePerPage);

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
        if (uid != null && (contact is Map)) {
          // 🛡️ Preserve local read status for active chat to prevent "jumping" counts
          if (uid == _activeChatUid) {
            contact['unread_messages_count'] = 0;
            contact['unread_count'] = 0;
          }
        }

        if (uid != null && !existingUids.contains(uid)) {
          _contacts.add(contact);
          addedInThisPage++;
          existingUids.add(uid);
        } else if (uid != null && existingUids.contains(uid)) {
          final index = _contacts.indexWhere((c) => _extractUid(c) == uid);
          if (index != -1) _contacts[index] = contact;
        }
      }

      if (_currentPage == 1 && !loadMore && newContacts.isNotEmpty && !isSearching) {
        _saveToPersistentCache();
      }
      
      _availableGroups = _extractGroupsFromResponse(result);
      _availableCountries = _extractCountriesFromResponse(result);
      
      if (newContacts.isEmpty) {
        debugPrint('🛑 [CONTACTS] Page is empty. Stopping recursion.');
        _hasMore = false;
      } else {
        // Optimized Sort contacts by latest message time
        final List<MapEntry<dynamic, DateTime>> timedContacts = _contacts
            .map((c) => MapEntry(c, Helpers.toUtc(c['latest_message'] ?? c['updated_at'])))
            .toList();
        timedContacts.sort((a, b) => b.value.compareTo(a.value));
        _contacts = timedContacts.map((e) => e.key).toList();
        
        if (autoLoadAll && _hasMore) {
          debugPrint('⏳ [CONTACTS] Auto-loading next page ($_currentPage + 1)...');
          await Future.delayed(const Duration(milliseconds: 2000));
          return await getContacts(
            search: search, 
            loadMore: true, 
            autoLoadAll: true,
            perPage: effectivePerPage,
            isRecursiveCall: true,
          );
        } else {
           if (addedInThisPage == 0 && loadMore) {
             debugPrint('🛑 [CONTACTS] No new unique contacts added in this page, stopping recursion.');
             _hasMore = false;
           }
        }
      }

      _isFetchingContacts = false;
      _isLoading = false;
      if (!_hasMore) _contactsFullyLoaded = true;
      if (!isRecursiveCall) getGlobalUnreadCount();
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ [CONTACTS] ERROR: $e');
      if (e.toString().contains("Too Many Attempts") || e.toString().contains("429")) {
        debugPrint('🛑 [CONTACTS] Rate limit hit. Waiting 30s before retry...');
        _isLoading = true;
        notifyListeners();
        await Future.delayed(const Duration(seconds: 30));
        _isFetchingContacts = false;
        if (!loadMore) _currentPage--; 
        return await getContacts(search: search, loadMore: loadMore, autoLoadAll: autoLoadAll, isRecursiveCall: true);
      }
      _errorMessage = e.toString();
      _isFetchingContacts = false;
      _isLoading = false;
      if (loadMore) _currentPage--; 
      notifyListeners();
      return false;
    }
  }

  /// Optimized parallel batch fetching for massive contact lists (Fix 1, 2, 4)
  Future<bool> _fetchAllContactsParallel(String? search, int perPage, bool refresh, String sessionId) async {
    const int concurrency = 5; // Fetch 5 pages at once
    const int uiUpdateBatch = 10; // Notify UI every 10 pages
    List<dynamic> buffer = [];
    bool endReached = false;
    int pagesFetchedInCurrentBatch = 0;

    try {
      while (!endReached && sessionId == _activeRequestSessionId) {
        debugPrint('🚀 [BATCH] Fetching pages $_currentPage to ${_currentPage + concurrency - 1}');
        
        List<Future<dynamic>> batch = [];
        for (int i = 0; i < concurrency; i++) {
          final page = _currentPage + i;
          batch.add(_repository.getContacts(
            search: search,
            page: page,
            perPage: perPage,
            refresh: refresh || (page == 1),
            cancelToken: _contactsCancelToken,
          ).catchError((e) {
            debugPrint('⚠ [BATCH] Page $page failed: $e');
            return null;
          }));
        }

        final List<dynamic> batchResults = await Future.wait(batch);
        int successfulInBatch = 0;
        
        for (var rawResult in batchResults) {
          if (rawResult == null) {
            // Even if it failed, we must increment currentPage to avoid infinite loop
            // on the same failing pages.
            if (!endReached) _currentPage++;
            continue;
          }
          
          successfulInBatch++;
          final result = Helpers.sanitizeData(rawResult);
          List<dynamic> newContacts = _parseContactsResponse(result);
          
          if (newContacts.isEmpty) {
            endReached = true;
            _hasMore = false;
            break;
          }
          
          _updatePaginationState(result, newContacts.length, perPage);

          final existingUids = _contacts.map(_extractUid).whereType<String>().toSet();
          final bufferUids = buffer.map(_extractUid).whereType<String>().toSet();

          for (var contact in newContacts) {
            if (contact is Map) {
              contact['first_name'] = _sanitizeText(contact['first_name']?.toString());
              contact['last_name'] = _sanitizeText(contact['last_name']?.toString());
              contact['full_name'] = _sanitizeText(contact['full_name']?.toString());
              contact['name'] = _sanitizeText(contact['name']?.toString());
            }
            final uid = _extractUid(contact);
            if (uid != null && !existingUids.contains(uid) && !bufferUids.contains(uid)) {
              buffer.add(contact);
              bufferUids.add(uid);
            }
          }
          
          pagesFetchedInCurrentBatch++;
          if (!endReached) _currentPage++;
        }

        // If the whole batch failed, we might want to stop or slow down
        if (successfulInBatch == 0) {
          debugPrint('🛑 [BATCH] Entire batch failed. Stopping parallel fetch.');
          endReached = true;
        }

        // Fix 2: Batch UI Updates - avoid rebuilding 242 times
        if (buffer.length >= 120 || endReached || pagesFetchedInCurrentBatch >= uiUpdateBatch) {
          debugPrint(' [UI] Batch Update: Adding ${buffer.length} contacts (Total: ${_contacts.length + buffer.length})');
          _contacts.addAll(buffer);
          
          // Optimization: Sort only when batch is added
          final List<MapEntry<dynamic, DateTime>> timedContacts = _contacts
              .map((c) => MapEntry(c, Helpers.toUtc(c['latest_message'] ?? c['updated_at'])))
              .toList();
          timedContacts.sort((a, b) => b.value.compareTo(a.value));
          _contacts = timedContacts.map((e) => e.key).toList();

          buffer.clear();
          pagesFetchedInCurrentBatch = 0;
          _saveToPersistentCache(); // Fix 4: Save progress to local storage
          notifyListeners();
        }

        if (endReached || !_hasMore) {
          endReached = true;
        } else {
          // Fix 1: Parallel batches with small delay to respect rate limits
          await Future.delayed(const Duration(milliseconds: 1200));
        }
      }

      _isFetchingContacts = false;
      _isLoading = false;
      if (endReached) _contactsFullyLoaded = true;
      getGlobalUnreadCount();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ [BATCH] Error: $e');
      _errorMessage = e.toString();
      _isFetchingContacts = false;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void _updatePaginationState(dynamic result, int newCount, int requestedPerPage) {
    if (result is! Map) return;

    // 🛡️ BUG FIX: Rely on newCount instead of unreliable backend flags.
    // If we got 0 contacts, we definitely reached the end.
    _hasMore = newCount > 0;

    final clientModels = result['client_models'];
    dynamic paginateInfo = clientModels?['contactsPaginatePage'] ?? 
                          result['pagination'] ?? 
                          result['data']?['pagination'];
    
    if (paginateInfo is Map) {
      _total = _toInt(paginateInfo['total']) ?? 
               _toInt(paginateInfo['total_records']) ?? 
               _toInt(paginateInfo['count']) ?? 
               _total;
    } else {
      int? foundTotal = _extractTotal(result);
      if (foundTotal != null) {
        _total = foundTotal;
      }
    }

    // 🛡️ Debug Verification
    debugPrint('[PAGINATION DEBUG]');
    debugPrint('   - Backend Total: ${_total == 0 ? "Unknown" : _total}');
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
      'allContactsCount', 'count', 'contacts_count', 'total_count', 'totalCount'
    ];
    final sources = [
      result, 
      result['data'], 
      result['client_models'], 
      result['client_models']?['contactsPaginatePage'],
      result['client_models']?['contacts_paginate_page'],
    ];
    for (final source in sources) {
      if (source is Map) {
        for (final key in keys) {
          if (source[key] != null) {
            final val = _toInt(source[key]);
            if (val != null && val > 0) return val;
          }
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

  Future<bool> loadContactByUid(String uid) async {
    debugPrint('🔍 [CONTACT] loadContactByUid starting for: $uid');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      // 1. Check if already in local list
      final existingIndex = _contacts.indexWhere((c) => _extractUid(c) == uid);
      if (existingIndex != -1) {
        debugPrint('✅ [CONTACT] Found $uid in local list');
        _selectedContact = _contacts[existingIndex];
        _isLoading = false;
        notifyListeners();
        return true;
      }

      // 2. Fetch from backend via chat box data (which often contains the contact object)
      debugPrint('📡 [CONTACT] Fetching $uid from backend...');
      final result = await _repository.getContactChatBoxData(uid);
      
      if (result != null && result is Map) {
        final clientModels = result['client_models'];
        final data = result['data'];
        
        // Try various common paths for the contact object
        final contactData = (clientModels is Map ? clientModels['contact'] : null) ?? 
                           (data is Map ? data['contact'] : null) ?? 
                           result['contact'];

        if (contactData != null && contactData is Map) {
          debugPrint('✅ [CONTACT] Successfully fetched details for $uid');
          _selectedContact = Helpers.sanitizeData(contactData);
          
          // 3. Add to local list so it appears in the chat list immediately
          _contacts.insert(0, _selectedContact);
          _saveToPersistentCache();
        } else {
          debugPrint('⚠️ [CONTACT] Fetched chat box data but no contact object found for $uid');
        }
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ [CONTACT] loadContactByUid Error: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> getContact({String? phoneNumber, String? email}) async {
    debugPrint('🔍 [CONTACT] getContact: phone=$phoneNumber, email=$email');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _repository.getContact(phoneNumber: phoneNumber, email: email);
      if (result != null) {
        _selectedContact = Helpers.sanitizeData(result);
        
        // Add to main list if not present
        final fetchedUid = _extractUid(_selectedContact);
        if (fetchedUid != null) {
          final index = _contacts.indexWhere((c) => _extractUid(c) == fetchedUid);
          if (index == -1) {
            _contacts.insert(0, _selectedContact);
            debugPrint('📥 [CONTACT] Added new contact to list: $fetchedUid');
          } else {
            _contacts[index] = _selectedContact;
            debugPrint('🔄 [CONTACT] Updated existing contact: $fetchedUid');
          }
          _saveToPersistentCache();
        }
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ [CONTACT] getContact Error: $e');
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
      debugPrint('📥 [UNREAD] API Response: $result');
      if (result is Map) {
        final int newCount = _toInt(result['unread_count'] ?? result['data']?['unread_count'] ?? result['client_models']?['unreadMessagesCount']) ?? 0;
        if (_globalUnreadCount != newCount) {
          debugPrint('📊 [UNREAD] Syncing: $_globalUnreadCount -> $newCount');
          _globalUnreadCount = newCount;
          _saveToPersistentCache();
          notifyListeners();
        } else {
          debugPrint('📊 [UNREAD] No change: $newCount');
        }
      }
    } catch (e) {
      debugPrint('❌ Global unread count error: $e');
    }
  }

  Future<void> markContactAsRead(String contactUid, {String? messageId}) async {
    // 🛡️ Guard: Only mark as read if it actually has unread messages locally
    int previousCount = 0;
    int contactIndex = -1;
    for (int i = 0; i < _contacts.length; i++) {
      final contact = _contacts[i];
      if (contact is Map && (contact['_uid'] ?? contact['uid']) == contactUid) {
        previousCount = Helpers.toInt(contact['unread_messages_count'] ?? contact['unread_count']) ?? 0;
        contactIndex = i;
        break;
      }
    }
    
    if (messageId == null && previousCount <= 0) {
      debugPrint('ℹ️ [MARK READ] Contact $contactUid already has 0 unread. Skipping.');
      return;
    }

    final int previousGlobalCount = _globalUnreadCount;
    debugPrint('📩 [MARK READ] START - Contact: $contactUid, MessageID: $messageId, Prev Contact Unread: $previousCount, Prev Global: $previousGlobalCount');
    
    // 1. Update local state immediately for UI responsiveness
    if (contactIndex != -1) {
      final updatedContact = Map<String, dynamic>.from(_contacts[contactIndex]);
      if (messageId == null) {
        updatedContact['unread_messages_count'] = 0;
        updatedContact['unread_count'] = 0;
        _globalUnreadCount = (_globalUnreadCount - previousCount).clamp(0, 999999);
      } else {
        int currentUnread = Helpers.toInt(updatedContact['unread_messages_count'] ?? updatedContact['unread_count']) ?? 0;
        if (currentUnread > 0) {
          updatedContact['unread_messages_count'] = currentUnread - 1;
          updatedContact['unread_count'] = currentUnread - 1;
          _globalUnreadCount = (_globalUnreadCount - 1).clamp(0, 999999);
        }
      }
      _contacts[contactIndex] = updatedContact;
    }
    
    // Update individual message status in current chat if active
    if (_activeChatUid == contactUid) {
      bool changed = false;
      for (int i = 0; i < _messages.length; i++) {
        final msg = _messages[i];
        if (msg is Map) {
          final id = (msg['whatsapp_message_id'] ?? msg['wamid'] ?? msg['_uid'] ?? msg['uid']).toString();
          final isIncoming = msg['is_incoming_message'] == 1 || msg['is_incoming_message'] == true || msg['is_incoming_message'] == '1';
          
          if (messageId != null) {
            if (id == messageId && msg['status'] != 'read') {
              debugPrint('📝 [MARK READ] Updating Message $id: ${msg['status']} -> read');
              final updatedMsg = Map<String, dynamic>.from(msg);
              updatedMsg['status'] = 'read';
              _messages[i] = updatedMsg;
              changed = true;
              break;
            }
          } else if (isIncoming) {
            if (msg['status'] != 'read') {
              debugPrint('📝 [MARK READ] Updating Incoming Message $id: ${msg['status']} -> read');
              final updatedMsg = Map<String, dynamic>.from(msg);
              updatedMsg['status'] = 'read';
              _messages[i] = updatedMsg;
              changed = true;
            }
          }
        }
      }
      if (changed) _messages = List.from(_messages);
    }
    
    debugPrint('🔔 [MARK READ] Local state updated. New Global: $_globalUnreadCount');
    notifyListeners();
    _saveToPersistentCache();

    // 2. Call API to notify backend
    try {
      debugPrint('📡 [MARK READ] API Request: contact_uid=$contactUid, message_id=$messageId');
      final result = await _repository.markAsRead(contactUid: contactUid, messageId: messageId);
      debugPrint('📥 [MARK READ] API Response: $result');
      
      // 🛡️ [SYNC] Update global count from response if available, otherwise debounce a fresh fetch
      // This prevents "count jumping" during multiple rapid read events
      if (result is Map && (result['unread_count'] != null || result['data']?['unread_count'] != null)) {
        final serverCount = Helpers.toInt(result['unread_count'] ?? result['data']?['unread_count']);
        if (serverCount != null) {
          debugPrint('🎯 [MARK READ] Syncing from API response: $serverCount');
          _globalUnreadCount = serverCount;
          notifyListeners();
          _saveToPersistentCache();
        }
      } else {
        _debouncedGlobalUnreadSync();
      }
      
      debugPrint('✅ [MARK READ] Completed. Global: $_globalUnreadCount');
    } catch (e) {
      debugPrint('⚠️ [MARK READ] API Error: $e');
    }
  }

  Future<bool> getContactChatBoxData(String contactUid, {bool showLoading = true, bool refresh = false, bool force = false}) async {
    debugPrint('🚀 [CHAT] getContactChatBoxData START: $contactUid (Force: $force, Refresh: $refresh)');
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
      _chatPage = 1;
      _hasMoreChat = true;
      _isLoadingMoreChat = false;
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
      
      // 🛡️ [PAGINATION LOGGING]
      _logChatPagination(contactUid, _chatPage, rawNewMessages, chatResult);

      // 🛡️ Update Chat Pagination State
      if (chatResult is Map) {
        final clientModels = chatResult['client_models'];
        final paginate = clientModels?['whatsappMessageLogsPaginatePage'] ?? 
                          chatResult['pagination'] ?? 
                          chatResult['data']?['pagination'] ??
                          chatResult['meta']?['pagination'];
        
        if (paginate is Map) {
          final lastPage = Helpers.toInt(paginate['last_page']);
          final current = Helpers.toInt(paginate['current_page']);
          if (lastPage != null) {
            _hasMoreChat = _chatPage < lastPage;
          } else {
            _hasMoreChat = rawNewMessages.isNotEmpty; 
          }
          if (current != null) _chatPage = current;
        } else {
          // 🛡️ FIX: Do not assume beginning if metadata is missing. 
          // If we got messages, there might be more. The "Load More" button 
          // will handle fetching page 2 to confirm if history exists.
          _hasMoreChat = rawNewMessages.isNotEmpty;
        }
      } else {
        _hasMoreChat = rawNewMessages.length >= 15;
      }
      
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
      
      for (var msg in _messages) {
        final id = msg['whatsapp_message_id'] ?? msg['wamid'] ?? msg['_uid'] ?? msg['uid'] ?? msg['local_id'] ?? msg['timestamp'] ?? msg['created_at'] ?? msg.hashCode;
        if (id != null) {
          uniqueMap[id.toString()] = msg;
        }
      }

      // 2. Process backend messages and merge/update
      if (rawNewMessages.isNotEmpty) {
        debugPrint('📡 [SYNC] Backend messages received: ${rawNewMessages.length}');
        for (var msg in rawNewMessages) {
          final id = msg['whatsapp_message_id'] ?? msg['wamid'] ?? msg['_uid'] ?? msg['uid'] ?? msg['local_id'] ?? msg['timestamp'] ?? msg['created_at'] ?? msg['id'];
          if (id != null) {
            final idStr = id.toString();
            
            // If it's an outgoing message, try to match and remove its temp/sent version
            if (msg['is_incoming_message'] == 0 || msg['is_incoming_message'] == '0' || msg['is_incoming_message'] == false) {
              final initialSize = uniqueMap.length;
              uniqueMap.removeWhere((key, m) {
                // Match by ID directly first
                if (key == idStr) return true;

                // Match by local_id if available (backend might echo it back in some cases)
                if (m['local_id'] != null && msg['local_id'] == m['local_id']) return true;

                // Match optimistic/sending messages by content
                final bool isOptimistic = key.startsWith('temp_') || m['status'] == 'sending' || m['status'] == 'failed' || m['status'] == 'uploading';
                if (!isOptimistic) return false;
                
                // Match by text content
                final bool textMatch = (m['message'] == msg['message'] || m['message_body'] == msg['message_body'] || m['text'] == msg['text']);
                if (textMatch && (m['message']?.toString().isNotEmpty ?? false) && m['message'] != 'Media') {
                  final mTime = _getDateTime(m);
                  final msgTime = _getDateTime(msg);
                  // Strict 5-minute window for text matches
                  if (mTime.difference(msgTime).abs().inMinutes < 5) return true;
                }
                
                // Match by media type if both are media
                final String? mType = m['message_type'] ?? m['type'];
                final String? msgType = msg['message_type'] ?? msg['type'];
                if (mType != null && mType == msgType && mType != 'text') {
                   // For media, check filename or use a strict time window
                   final mLink = m['__data']?['media_values']?['link']?.toString() ?? '';
                   final msgLink = msg['__data']?['media_values']?['link']?.toString() ?? msg['media_url']?.toString() ?? '';
                   
                   bool linkMatch = false;
                   if (mLink.isNotEmpty && msgLink.isNotEmpty) {
                      final mFile = mLink.split('/').last.split('?').first;
                      final msgFile = msgLink.split('/').last.split('?').first;
                      if (mFile == msgFile) linkMatch = true;
                   }

                   final mTime = _getDateTime(m);
                   final msgTime = _getDateTime(msg);
                   
                   // If filenames match and they are within 10 minutes, it's definitely the same
                   if (linkMatch && mTime.difference(msgTime).abs().inMinutes < 10) return true;
                   
                   // If it's a very close time match (2 min) even without link match (server might rename)
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

      // 🛡️ PRESERVE LOCAL READ STATUS
      // If a message was marked as read locally, don't let a stale backend poll revert it.
      for (var entry in uniqueMap.entries) {
        final id = entry.key;
        final msg = entry.value;
        final existingMsg = _messages.firstWhere(
          (m) => (m['whatsapp_message_id'] ?? m['wamid'] ?? m['_uid'] ?? m['uid'] ?? m['local_id'])?.toString() == id,
          orElse: () => null,
        );
        
        if (existingMsg != null && existingMsg['status'] == 'read' && msg['status'] != 'read') {
          debugPrint('🛡️ [MERGE] Preserving local "read" status for message $id');
          if (msg is Map) {
            uniqueMap[id] = {...msg, 'status': 'read'};
          }
        }
      }

      // 3. Sort by time (newest first for reversed ListView)
      // Optimization: Pre-calculate date times for sorting to avoid repeated parsing
      final List<MapEntry<dynamic, DateTime>> timedMessages = uniqueMap.values
          .map((m) => MapEntry(m, _getDateTime(m)))
          .toList();
      
      timedMessages.sort((a, b) => b.value.compareTo(a.value));
      dedupedList = timedMessages.map((e) => e.key).toList();

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

      _isFetchingChat = false;
      _isLoading = false;
      _chatBoxRetryCount = 0; // Reset retry count on success
      
      notifyListeners(); // Always notify after data fetch to update timer/state
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

  Future<void> loadMoreChatMessages(String contactUid) async {
    if (_isLoadingMoreChat || !_hasMoreChat) {
      debugPrint('⏳ [CHAT] Skipping load more: loading=$_isLoadingMoreChat, hasMore=$_hasMoreChat');
      return;
    }

    _isLoadingMoreChat = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final nextPage = _chatPage + 1;
      final chatResult = await _repository.getChatHistory(contactUid, page: nextPage);

      // 🛡️ UID CHECK: If the user switched chats while this request was in flight, discard it.
      if (contactUid != _activeChatUid) {
        debugPrint('🛑 [CHAT] UID mismatch in loadMore. Discarding results for $contactUid (Active: $_activeChatUid)');
        return;
      }

      final List<dynamic> newMessages = _extractMessagesFromResponse([chatResult]);
      
      // 🛡️ [PAGINATION LOGGING]
      _logChatPagination(contactUid, nextPage, newMessages, chatResult);

      if (newMessages.isEmpty) {
        _hasMoreChat = false;
      } else {
        _chatPage = nextPage;
        
        // 🛡️ DEDUPLICATE & MERGE
        final Map<String, dynamic> uniqueMap = {};
        for (var msg in _messages) {
          final id = msg['whatsapp_message_id'] ?? msg['wamid'] ?? msg['_uid'] ?? msg['uid'] ?? msg['local_id'] ?? msg['timestamp'] ?? msg['created_at'] ?? msg.hashCode;
          if (id != null) uniqueMap[id.toString()] = msg;
        }

        bool addedAny = false;
        for (var msg in newMessages) {
          final id = msg['whatsapp_message_id'] ?? msg['wamid'] ?? msg['_uid'] ?? msg['uid'] ?? msg['id'];
          if (id != null) {
            final idStr = id.toString();
            if (!uniqueMap.containsKey(idStr)) {
              _messages.add(msg);
              uniqueMap[idStr] = msg;
              addedAny = true;
            }
          } else {
            final hash = msg.hashCode.toString();
            if (!uniqueMap.containsKey(hash)) {
              _messages.add(msg);
              uniqueMap[hash] = msg;
              addedAny = true;
            }
          }
        }

        if (!addedAny && newMessages.isNotEmpty) {
           // We got messages but all were duplicates. Try one more page?
           // For now, let's just mark hasMore if the page was full.
           _hasMoreChat = newMessages.length >= 15;
        }

        // Optimized Sort messages by time (Latest first)
        final List<MapEntry<dynamic, DateTime>> timedMessages = _messages
            .map((m) => MapEntry(m, _getDateTime(m)))
            .toList();
        timedMessages.sort((a, b) => b.value.compareTo(a.value));
        _messages = timedMessages.map((e) => e.key).toList();
        
        // Update pagination info if available in response
        if (chatResult is Map) {
          final clientModels = chatResult['client_models'];
          final paginate = clientModels?['whatsappMessageLogsPaginatePage'] ?? 
                            chatResult['pagination'] ?? 
                            chatResult['data']?['pagination'] ??
                            chatResult['meta']?['pagination'];
          if (paginate is Map) {
            final lastPage = Helpers.toInt(paginate['last_page']);
            if (lastPage != null) {
              _hasMoreChat = _chatPage < lastPage;
            } else {
              _hasMoreChat = newMessages.isNotEmpty;
            }
          } else {
            _hasMoreChat = newMessages.isNotEmpty;
          }
        }
      }
    } catch (e) {
      debugPrint('❌ [CHAT] loadMoreChatMessages Error: $e');
      _errorMessage = "Failed to load previous messages. Tap to retry.";
    } finally {
      _isLoadingMoreChat = false;
      notifyListeners();
    }
  }

  void _logChatPagination(String contactUid, int page, List<dynamic> messages, dynamic rawResponse) {
    String oldest = 'N/A';
    String newest = 'N/A';
    
    if (messages.isNotEmpty) {
      final sorted = List.from(messages)..sort((a, b) => _getDateTime(a).compareTo(_getDateTime(b)));
      oldest = _getDateTime(sorted.first).toIso8601String();
      newest = _getDateTime(sorted.last).toIso8601String();
    }

    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🔍 [CHAT PAGINATION DEBUG]');
    debugPrint('📱 Conversation ID: $contactUid');
    debugPrint('📄 Current Page: $page');
    debugPrint('📥 Messages Received: ${messages.length}');
    debugPrint('🔄 Has More (calculated): $_hasMoreChat');
    debugPrint('🕒 Oldest Msg: $oldest');
    debugPrint('🕒 Newest Msg: $newest');
    
    if (rawResponse is Map) {
      final paginate = rawResponse['client_models']?['whatsappMessageLogsPaginatePage'] ?? 
                        rawResponse['pagination'] ?? 
                        rawResponse['data']?['pagination'] ??
                        rawResponse['meta']?['pagination'];
      debugPrint('📦 Raw Pagination Meta: $paginate');
    }
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  DateTime _getDateTime(dynamic msg) {
    if (msg is! Map) return Helpers.toUtc(null);
    final timeStr = (msg['messaged_at'] ?? msg['created_at'] ?? msg['timestamp'] ?? msg['updated_at'])?.toString();
    return Helpers.toUtc(timeStr);
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
    final Map<String, Map<String, dynamic>> allMessagesMap = {};
    
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
      
      // Process messages from this result
      for (var msg in currentResultMessages) {
        if (msg is Map) {
          final Map<String, dynamic> msgMap = Map<String, dynamic>.from(msg);
          final id = msgMap['whatsapp_message_id'] ?? msgMap['wamid'] ?? msgMap['_uid'] ?? msgMap['uid'] ?? msgMap['id'];
          final idStr = id?.toString() ?? msgMap.hashCode.toString();
          
          // 🛡️ DEDUPLICATION: If we already have this ID, or a very similar message by content/time
          bool foundDuplicate = false;
          if (allMessagesMap.containsKey(idStr)) {
            foundDuplicate = true;
          } else {
            // Check for logical duplicates (same content, same sender, same time)
            final msgBody = (msgMap['message'] ?? msgMap['message_body'] ?? msgMap['text'] ?? '').toString();
            final msgTime = _getDateTime(msgMap);
            final isIncoming = msgMap['is_incoming_message'];

            for (final existing in allMessagesMap.values) {
              final existingBody = (existing['message'] ?? existing['message_body'] ?? existing['text'] ?? '').toString();
              final existingTime = _getDateTime(existing);
              final existingIncoming = existing['is_incoming_message'];

              if (isIncoming == existingIncoming && 
                  msgBody == existingBody && 
                  msgBody.isNotEmpty && 
                  msgBody != 'Media' &&
                  msgTime.difference(existingTime).abs().inSeconds < 10) {
                foundDuplicate = true;
                break;
              }
            }
          }

          if (!foundDuplicate) {
            allMessagesMap[idStr] = msgMap;
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

  DateTime? getLastIncomingMessageTime() {
    for (var msg in _messages) {
      if (msg is Map) {
        final isIncoming = msg['is_incoming_message'] == 1 || 
                           msg['is_incoming_message'] == true || 
                           msg['is_incoming_message'] == '1';
        if (isIncoming) {
          return _getDateTime(msg);
        }
      }
    }
    return null;
  }

  Future<bool> sendMessage({
    required String contactUid, 
    required String message,
    String? replyToMessageId,
  }) async {
    _errorMessage = null;
    debugPrint('🚀 [SEND] Starting sendMessage. UID: $contactUid');
    
    // 🛡️ 24-HOUR POLICY CHECK (Client-side)
    final lastIncoming = getLastIncomingMessageTime();
    bool isExpired = false;
    if (lastIncoming != null) {
      final now = Helpers.toUtc(null);
      if (now.difference(lastIncoming).inHours >= 24) {
        isExpired = true;
      }
    }

    if (isExpired) {
      debugPrint('🛑 [SEND] Blocked by 24h policy locally');
      final tempId = 'temp_policy_${DateTime.now().millisecondsSinceEpoch}';
      final failedMessage = {
        'whatsapp_message_id': tempId,
        'local_id': tempId,
        'message': message,
        'message_body': message,
        'status': 'failed',
        'error': '24_hour_policy_error',
        'is_incoming_message': 0,
        'created_at': Helpers.toUtc(null).toIso8601String(),
        if (replyToMessageId != null) 'reply_to_message_id': replyToMessageId,
      };
      _messages = [failedMessage, ..._messages];
      notifyListeners();
      return false;
    }
    
    // 🛡️ OPTIMISTIC UPDATE: Add message to UI immediately
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMessage = {
      'whatsapp_message_id': tempId,
      'local_id': tempId,
      'message': message,
      'message_body': message,
      'status': 'sending',
      'is_incoming_message': 0,
      'created_at': Helpers.toUtc(null).toIso8601String(),
      if (replyToMessageId != null) 'reply_to_message_id': replyToMessageId,
    };
    
    // Create a fresh list for the UI to detect change
    _messages = [optimisticMessage, ..._messages];
    debugPrint('✅ [SEND] Local message inserted. ID: $tempId');
    _updateContactLatestMessage(contactUid, optimisticMessage);
    notifyListeners();

    try {
      // Find contact to get wa_id
      String? waId;
      try {
        final contact = _contacts.firstWhere(
          (c) => (c['_uid'] ?? c['uid'] ?? c['id'])?.toString() == contactUid,
        );
        waId = (contact['wa_id'] ?? contact['phone_number'])?.toString();
      } catch (_) {}

      debugPrint('📡 [SEND] API Call Started...');
      final result = await _repository.sendMessage(
        contactUid: contactUid, 
        message: message,
        waId: waId,
        replyToMessageId: replyToMessageId,
      );
      
      debugPrint('✅ [SEND] API Success. Response: $result');
      
      // Update the temp message with real data from response if available
      final index = _messages.indexWhere((m) => m['whatsapp_message_id'] == tempId || m['local_id'] == tempId);
      if (index != -1 && result is Map) {
        debugPrint('🔄 [SEND] Updating optimistic message with server data');
        
        // 🛡️ Extract actual message log from response
        final List<dynamic> sentMessages = _extractMessagesFromResponse([result]);
        final Map<String, dynamic>? serverMsg = (sentMessages.isNotEmpty && sentMessages.first is Map) 
            ? Map<String, dynamic>.from(sentMessages.first) 
            : null;

        if (serverMsg != null) {
          // 🛡️ Ensure ID is unified to prevent duplicates on next sync
          final serverId = serverMsg['whatsapp_message_id'] ?? serverMsg['wamid'] ?? serverMsg['_uid'] ?? serverMsg['uid'];
          
          final Map<String, dynamic> updatedMsg = {
            ..._messages[index],
            ...serverMsg,
            if (serverId != null) 'whatsapp_message_id': serverId.toString(),
            'status': 'sent',
          };
          _messages[index] = updatedMsg;
          _updateContactLatestMessage(contactUid, updatedMsg);
        } else {
          // Fallback if extraction failed but result is Map
          _messages[index] = {
            ..._messages[index],
            ...result,
            'status': 'sent',
          };
        }
        
        _messages = List.from(_messages);
        notifyListeners();
      }
      
      // Background sync to stay in sync with server state
      debugPrint('🔄 [SEND] Triggering background sync');
      getContactChatBoxData(contactUid, showLoading: false, force: true, refresh: true);
      
      return true;
    } catch (e) {
      debugPrint('❌ [SEND] Error: $e');
      
      String displayError = e.toString().replaceAll('Exception: ', '');
      if (displayError.toLowerCase().contains('24 hour') || displayError.toLowerCase().contains('24hour')) {
        displayError = "24_hour_policy_error";
      }

      final index = _messages.indexWhere((m) => m['whatsapp_message_id'] == tempId || m['local_id'] == tempId);
      if (index != -1) {
        _messages[index] = {
          ..._messages[index],
          'status': 'failed',
          'error': displayError,
        };
        _messages = List.from(_messages);
      }
      _errorMessage = displayError == "24_hour_policy_error" 
          ? "Failed due to 24 hour policy" 
          : displayError;
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
      
      // Optimized Sort contacts by latest message
      final List<MapEntry<dynamic, DateTime>> timedContacts = _contacts
          .map((c) => MapEntry(c, Helpers.toPKT(c['latest_message'] ?? c['updated_at'])))
          .toList();
      timedContacts.sort((a, b) => b.value.compareTo(a.value));
      _contacts = timedContacts.map((e) => e.key).toList();
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

  Future<bool> sendStickerMessage({required String contactUid, required String filePath}) async {
    return _sendMediaOptimistic(
      contactUid: contactUid,
      filePath: filePath,
      mediaType: 'sticker',
    );
  }

  Future<bool> _sendMediaOptimistic({
    required String contactUid,
    required String filePath,
    required String mediaType,
    int? duration,
  }) async {
    _errorMessage = null;
    
    // 🛡️ 24-HOUR POLICY CHECK (Client-side)
    final lastIncoming = getLastIncomingMessageTime();
    if (lastIncoming != null && Helpers.toUtc(null).difference(lastIncoming).inHours >= 24) {
       debugPrint('🛑 [SEND MEDIA] Blocked by 24h policy locally');
       final tempId = 'temp_media_policy_${DateTime.now().millisecondsSinceEpoch}';
       final failedMessage = {
          'whatsapp_message_id': tempId,
          'local_id': tempId,
          'message': 'Media',
          'message_body': 'Media',
          'status': 'failed',
          'error': '24_hour_policy_error',
          'is_incoming_message': 0,
          'created_at': Helpers.toUtc(null).toIso8601String(),
          'message_type': mediaType,
          '__data': {
            'media_values': {
              'link': filePath,
              'type': mediaType,
              if (duration != null) 'duration': duration,
            }
          }
       };
       _messages = [failedMessage, ..._messages];
       notifyListeners();
       return false;
    }

    final file = File(filePath);
    final originalSize = await file.length();
    debugPrint('🚀 [SEND MEDIA] Starting flow: $mediaType');
    debugPrint('📁 [SEND MEDIA] File: $filePath');
    debugPrint('📊 [SEND MEDIA] Original Size: ${Helpers.formatFileSize(originalSize)}');
    
    final tempId = 'temp_media_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMessage = {
      'whatsapp_message_id': tempId,
      'local_id': tempId,
      'message': 'Media',
      'message_body': 'Media',
      'status': 'uploading',
      'is_incoming_message': 0,
      'created_at': Helpers.toUtc(null).toIso8601String(),
      'message_type': mediaType,
      '__data': {
        'progress': 0.0,
        'media_values': {
          'link': filePath, // Use local path for preview
          'type': mediaType,
          if (duration != null) 'duration': duration,
        }
      }
    };
    
    _messages = [optimisticMessage, ..._messages];
    debugPrint('✅ [SEND MEDIA] Local message inserted. ID: $tempId');
    _updateContactLatestMessage(contactUid, optimisticMessage);
    notifyListeners();

    try {
      String? waId;
      try {
        final contact = _contacts.firstWhere(
          (c) => (c['_uid'] ?? c['uid'] ?? c['id'])?.toString() == contactUid,
        );
        waId = (contact['wa_id'] ?? contact['phone_number'])?.toString();
      } catch (_) {}

      // 🛡️ COMPRESSION
      String uploadPath = filePath;
      if (mediaType == 'video') {
        debugPrint('📹 [COMPRESS] Video compression started...');
        final startTime = DateTime.now();
        
        // Check duration and info before proceeding
        try {
          final info = await VideoCompress.getMediaInfo(filePath);
          final durationMs = info.duration ?? 0;
          final durationSec = durationMs / 1000;
          
          debugPrint('📹 [COMPRESS] Video Info: ${durationSec}s, ${info.width}x${info.height}, ${Helpers.formatFileSize(info.filesize ?? 0)}');
          
          if (durationSec > 365) { // 6 minute limit + 5s buffer
            debugPrint('🛑 [SEND MEDIA] Video too long: ${durationSec}s');
            throw Exception('Video is too long. Maximum duration allowed is 6 minutes.');
          }
        } catch (e) {
          debugPrint('⚠️ [COMPRESS] Could not get media info or limit exceeded: $e');
          if (e.toString().contains('6 minutes')) rethrow;
        }

        // Clear cache to avoid storage issues
        try {
          await VideoCompress.deleteAllCache();
        } catch (e) {
          debugPrint('⚠️ [COMPRESS] Could not clear cache: $e');
        }

        // Always compress videos to stay under server limits (often 5-10MB)
        // Skip compression only if file is extremely small (< 1MB)
        if (originalSize < 1 * 1024 * 1024) {
          debugPrint('📹 [COMPRESS] File is very small (${Helpers.formatFileSize(originalSize)}), skipping compression.');
        } else {
          final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
            filePath,
            quality: VideoQuality.LowQuality, // Switched to LowQuality for maximum compatibility
            deleteOrigin: false,
            includeAudio: true,
          );
          
          final endTime = DateTime.now();
          final compressionDuration = endTime.difference(startTime).inSeconds;
          
          if (mediaInfo?.path != null) {
            uploadPath = mediaInfo!.path!;
            final compressedSize = await File(uploadPath).length();
            debugPrint('📹 [COMPRESS] Success in ${compressionDuration}s');
            debugPrint('📹 [COMPRESS] New Size: ${Helpers.formatFileSize(compressedSize)} (${((1 - compressedSize / originalSize) * 100).toStringAsFixed(1)}% reduction)');
          } else {
            debugPrint('⚠️ [COMPRESS] Compression returned null path, using original file');
          }
        }
      } else if (mediaType == 'image') {
        debugPrint('🖼️ [COMPRESS] Compressing image...');
        final String targetPath = '${filePath}_compressed.jpg';
        final XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
          filePath,
          targetPath,
          quality: 70,
        );
        if (compressedFile != null) {
          uploadPath = compressedFile.path;
        }
      }

      debugPrint('📡 [SEND MEDIA] Repository call started...');
      final result = await _repository.sendMedia(
        contactUid: contactUid,
        filePath: uploadPath,
        mediaType: mediaType,
        waId: waId,
        onSendProgress: (sent, total) {
          if (total <= 0) return;
          final progress = sent / total;
          final index = _messages.indexWhere((m) => m['whatsapp_message_id'] == tempId);
          if (index != -1) {
            final Map<String, dynamic> msg = Map.from(_messages[index]);
            final Map<String, dynamic> data = Map.from(msg['__data'] ?? {});
            // Only notify if progress changed significantly (> 2%)
            if ((progress - (data['progress'] ?? 0.0)).abs() > 0.02) {
              data['progress'] = progress;
              msg['__data'] = data;
              _messages[index] = msg;
              _messages = List.from(_messages); // Ensure list reference changes for UI
              notifyListeners();
            }
          }
        },
      );
      
      debugPrint('✅ [SEND MEDIA] Repository Success. Result keys: ${result is Map ? result.keys : 'not map'}');
      
      final index = _messages.indexWhere((m) => m['whatsapp_message_id'] == tempId || m['local_id'] == tempId);
      if (index != -1 && result is Map) {
        debugPrint('🔄 [SEND MEDIA] Updating optimistic message with server response');
        
        // 🛡️ Extract actual message log from response
        final List<dynamic> sentMessages = _extractMessagesFromResponse([result]);
        final Map<String, dynamic> serverMsg = (sentMessages.isNotEmpty && sentMessages.first is Map) 
            ? Map<String, dynamic>.from(sentMessages.first) 
            : Map<String, dynamic>.from(result);

        // 🛡️ Ensure ID is unified to prevent duplicates on next sync
        final serverId = serverMsg['whatsapp_message_id'] ?? serverMsg['wamid'] ?? serverMsg['_uid'] ?? serverMsg['uid'];

        // 🛡️ Deep merge __data to preserve optimistic local links if server link is not yet ready
        Map<String, dynamic> mergedData = Map.from(_messages[index]['__data'] ?? {});
        if (serverMsg['__data'] is Map) {
          final serverMediaValues = serverMsg['__data']['media_values'];
          if (serverMediaValues is Map) {
            final Map<String, dynamic> localMediaValues = Map.from(mergedData['media_values'] ?? {});
            
            // Only overwrite link if server provides a valid URL
            final String? serverLink = serverMediaValues['link']?.toString();
            if (serverLink == null || serverLink.isEmpty || !serverLink.startsWith('http')) {
              serverMediaValues['link'] = localMediaValues['link']; // Keep local path
            }
            
            localMediaValues.addAll(Map<String, dynamic>.from(serverMediaValues));
            mergedData['media_values'] = localMediaValues;
          }
          
          // Add other __data fields
          final otherData = Map<String, dynamic>.from(serverMsg['__data']);
          otherData.remove('media_values');
          mergedData.addAll(otherData);
        }

        final Map<String, dynamic> updatedMsg = {
          ..._messages[index],
          ...serverMsg,
          if (serverId != null) 'whatsapp_message_id': serverId.toString(),
          '__data': mergedData,
          'status': 'sent',
          'created_at': result['created_at'] ?? _messages[index]['created_at'] ?? DateTime.now().toIso8601String(),
        };
        _messages[index] = updatedMsg;
        _updateContactLatestMessage(contactUid, updatedMsg);
        
        _messages = List.from(_messages);
        notifyListeners();
      } else {
        debugPrint('⚠️ [SEND MEDIA] Could not find optimistic message to update (Index: $index)');
      }
      
      // Background sync
      debugPrint('🔄 [SEND MEDIA] Triggering background sync');
      await Future.delayed(const Duration(seconds: 1));
      getContactChatBoxData(contactUid, showLoading: false, force: true, refresh: true);
      return true;
    } catch (e) {
      debugPrint('❌ [SEND MEDIA] Error: $e');
      
      String displayError = e.toString().replaceAll('Exception: ', '');
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.sendTimeout || e.type == DioExceptionType.receiveTimeout) {
          displayError = "Upload timed out. Your video might be too large for your internet connection.";
        } else if (e.response != null) {
          final status = e.response?.statusCode;
          debugPrint('📥 [SEND MEDIA] Server Error Response ($status): ${e.response?.data}');
          
          if (status == 413) {
            displayError = "Video file size exceeds server limit. Try a shorter video.";
          } else if (status == 406) {
            displayError = "Server Error: Format not acceptable.";
          } else {
            final serverData = e.response?.data;
            if (serverData is Map) {
              displayError = (serverData['message'] ?? serverData['error'] ?? "Server Error ($status)").toString();
            } else {
              displayError = "Server Error ($status)";
            }
          }
        }
      }
      
      // Override misleading server-side duration messages if possible
      if ((displayError.contains('2 minute') || displayError.contains('2-minute')) && mediaType == 'video') {
         displayError = "Server Error: Video exceeds backend limit (2 mins). Please upload a shorter video.";
      }

      if (displayError.toLowerCase().contains('24 hour') || displayError.toLowerCase().contains('24hour')) {
        displayError = "24_hour_policy_error";
      }

      final index = _messages.indexWhere((m) => m['whatsapp_message_id'] == tempId || m['local_id'] == tempId);
      if (index != -1) {
        _messages[index] = {
          ..._messages[index],
          'status': 'failed',
          'error': displayError,
        };
        _messages = List.from(_messages);
      }
      
      _errorMessage = displayError;
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
