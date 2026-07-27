import 'package:flutter/material.dart';
import '../../data/repositories/contact_repository.dart';

class ContactGroupProvider extends ChangeNotifier {
  final ContactRepository _repository;

  ContactGroupProvider(this._repository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<dynamic> _groups = [];
  List<dynamic> get groups => _groups;

  Future<void> fetchGroups({bool refresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      dynamic result;
      try {
        result = await _repository.getContactGroups(refresh: refresh);
      } catch (e) {
        debugPrint('⚠️ Initial group fetch failed, trying fallback...');
        // Try fallback endpoint manually via repository if needed, 
        // but for now let's just log and see if repository handles it.
        result = await _repository.getContactGroups(refresh: refresh);
      }

      if (result is Map && result['data'] != null) {
        _groups = result['data'];
      } else if (result is List) {
        _groups = result;
      } else if (result is Map) {
         _groups = result['groups'] ?? result['contactGroups'] ?? result['data'] ?? [];
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createGroup(String title, {String? description}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.createContactGroup(title: title, description: description);
      await fetchGroups(refresh: true);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateGroup(String groupUid, String title, {String? description}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.updateContactGroup(groupUid, title: title, description: description);
      await fetchGroups(refresh: true);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteGroup(String groupUid) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteContactGroup(groupUid);
      _groups.removeWhere((g) => g['uid'] == groupUid);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> assignContactsToGroup(List<String> contactUids, List<String> groupUids) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.assignContactsToGroup(contactUids: contactUids, groupUids: groupUids);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> removeContactFromGroup(String contactUid, String groupUid) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.removeContactFromGroup(contactUid: contactUid, groupUid: groupUid);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _groups = [];
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
