import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/auth/data/models/user_model.dart';
import '../features/auth/data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  VoidCallback? onLogout;
  Function(UserModel, String)? onLogin;

  AuthProvider(this._authRepository, {this.onLogout, this.onLogin});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  bool _rememberMe = false;
  bool get rememberMe => _rememberMe;

  String? _savedEmail;
  String? get savedEmail => _savedEmail;

  String? _savedPassword;
  String? get savedPassword => _savedPassword;

  List<Map<String, dynamic>> _savedAccounts = [];
  List<Map<String, dynamic>> get savedAccounts => _savedAccounts;

  UserModel? _user;
  UserModel? get user => _user;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    // Load Remember Me state
    final prefs = await SharedPreferences.getInstance();
    _rememberMe = prefs.getBool('remember_me') ?? false;

    if (_rememberMe) {
      final creds = await _authRepository.getRememberMe();
      if (creds != null) {
        _savedEmail = creds['email'];
        _savedPassword = creds['password'];
      }
    }

    await loadSavedAccounts();

    _user = await _authRepository.getSavedUser();
    _isLoggedIn = _user != null;

    if (_isLoggedIn && _user != null) {
      final token = await _authRepository.getToken();
      if (token != null) {
        onLogin?.call(_user!, token);
      }
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadSavedAccounts() async {
    _savedAccounts = await _authRepository.getSavedAccounts();
    notifyListeners();
  }

  Future<void> saveCurrentAccount({String? password}) async {
    if (_user != null) {
      await _authRepository.saveAccount(_user!.toJson(), password: password);
      await loadSavedAccounts();
    }
  }

  Future<void> removeSavedAccount(String id) async {
    await _authRepository.removeAccount(id);
    await loadSavedAccounts();
  }

  Future<String?> getSavedPassword(String email) async {
    return await _authRepository.getAccountPassword(email);
  }

  void setRememberMe(bool value) async {
    _rememberMe = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', value);
    if (!value) {
      await _authRepository.clearRememberMe();
      _savedEmail = null;
      _savedPassword = null;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password, {bool saveAccount = false}) async {
    debugPrint('=== PROVIDER LOGIN START ===');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('Calling repository login for $email...');
      _user = await _authRepository.login(email, password);
      _isLoggedIn = _user != null;
      debugPrint('Provider Login Success: $_isLoggedIn');
      if (_user != null) {
        if (saveAccount) {
          await saveCurrentAccount(password: password);
        }

        if (_rememberMe) {
          _savedEmail = email;
          _savedPassword = password;
          await _authRepository.saveRememberMe(email, password);
        }

        debugPrint('User Email: ${_user!.email}');
        debugPrint('User ID: ${_user!.id}');
        final token = await _authRepository.getToken();
        if (token != null) {
          onLogin?.call(_user!, token);
        }
      }
      
      _isLoading = false;
      notifyListeners();
      return _isLoggedIn;
    } catch (e, stack) {
      debugPrint('Provider Login Error: $e');
      debugPrint('Stacktrace: $stack');
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoggedIn = false;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> register({
    required String firstName,
    required String lastName,
    required String email,
    required String username,
    required String mobileNumber,
    required String vendorTitle,
    required String password,
    required String passwordConfirmation,
    required bool termsAndConditions,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authRepository.registerVendor(
        firstName: firstName,
        lastName: lastName,
        email: email,
        username: username,
        mobileNumber: mobileNumber,
        vendorTitle: vendorTitle,
        password: password,
        passwordConfirmation: passwordConfirmation,
        termsAndConditions: termsAndConditions,
      );
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _isLoggedIn = false;
    _user = null;
    onLogout?.call();
    notifyListeners();
  }

  Future<bool> updatePassword({
    required String oldPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.updatePassword(
        oldPassword: oldPassword,
        password: password,
        passwordConfirmation: passwordConfirmation,
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

  Future<bool> verifyTwoFactor({required String code}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authRepository.verifyTwoFactor(code: code);
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
