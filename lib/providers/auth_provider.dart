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

  UserModel? _user;
  UserModel? get user => _user;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    // Load Remember Me state and saved credentials
    final prefs = await SharedPreferences.getInstance();
    _rememberMe = prefs.getBool('remember_me') ?? false;

    if (_rememberMe) {
      final creds = await _authRepository.getSavedCredentials();
      _savedEmail = creds['email'];
      _savedPassword = creds['password'];
    }

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

  void setRememberMe(bool value) async {
    _rememberMe = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', value);
    if (!value) {
      await _authRepository.clearSavedCredentials();
      _savedEmail = null;
      _savedPassword = null;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
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
        // Save credentials if Remember Me is enabled
        if (_rememberMe) {
          await _authRepository.saveCredentials(email, password);
          _savedEmail = email;
          _savedPassword = password;
        } else {
          await _authRepository.clearSavedCredentials();
          _savedEmail = null;
          _savedPassword = null;
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
      debugPrint('Registering with params: $firstName, $lastName, $email, $username, $mobileNumber, $vendorTitle, $passwordConfirmation, $termsAndConditions');

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
      debugPrint('Registration Response: $response');
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

